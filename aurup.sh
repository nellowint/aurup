#!/bin/bash
# Maintainer: Wellinton Vieira <wellintonvieira.office@gmail.com>
# The simplify finding and installing packages AUR helper

option="$1"
packages="${@:2}"
pkgname="aurup"
pkgver="1.77"
author="nellowint"
name_args=""
directory="$HOME/.$pkgname"
local_packages="$directory/local_packages.txt"
remote_packages="$directory/remote_packages.txt"
updated_packages="$directory/updated_packages.txt"
temp_directory="$directory/tmp/"
base_url="https://aur.archlinux.org"
type_application="accept: application/json"

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 11)
PINK=$(tput setaf 5)
BLUE=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

mkdir -p "$directory"
mkdir -p "$temp_directory"

function print_manual {
	echo "use:  $pkgname <operation> [...]"
	echo "operations:"
	echo "$pkgname {-S  --sync      } [package name]"
	echo "$pkgname {-R  --remove    } [package name]"
	echo "$pkgname {-Ss --search    } [package name]"
	echo "$pkgname {-L  --list      } [package name]"
	echo "$pkgname {-L  --list      }"
	echo "$pkgname {-Sy --update    }"
	echo "$pkgname {-c  --clear     }"
	echo "$pkgname {-h  --help      }"
	echo "$pkgname {-V  --version   }"
}

function print_version {
	echo "$BOLD$PINK$pkgname $RESET$BOLD$GREEN$pkgver$RESET"
	echo "2019-$( date +"%Y" ) VWTech Dev - https://github.com/vwtechdev"
	echo "this is free software: you are free to change and redistribute it."
	echo "learn more at https://github.com/$author/$pkgname"
}

function print_error {
	echo "invalid option, consult manual with command $pkgname --help"
}

function print_error_connection {
	echo "no internet connection!"
}

function as_root() {
	if [[ $EUID -eq 0 ]]; then
		"$@"
	elif command -v sudo >/dev/null 2>&1; then
		sudo "$@"
	elif command -v doas >/dev/null 2>&1; then
		doas "$@"
	else
		echo "error: need root privileges"
		exit 1
	fi
}

function check_connection {
	local response="$( curl -s -I $base_url/rpc/swagger )"
	local status_code=$( echo $response | grep "HTTP" | cut -d " " -f 2 )
	if [[ $status_code -eq "200" ]]; then
		return 0
	fi
	return 1
}

function check_packages {
	if check_connection; then
		echo -n > $remote_packages
		for package in $packages; do
			name_args+="arg%5B%5D=$package&"
		done
		name_args=$( echo "$name_args" | tr -d ' ' )
		verify_packages

		if [ -s "$remote_packages" ]; then
			while read -r line; do
				package="$( echo "$line" | cut -d ' ' -f1 )"
				local remote_version="$( echo "$line" | cut -d ' ' -f2 )"
				local local_version=$( pacman -Qm | grep $package | cut -d ' ' -f2 )

				if [[ "$local_version" == "$remote_version" ]]; then
					echo "$BOLD${GREEN}$package${RESET} is on the latest version"
				else
					url="$base_url/cgit/aur.git/snapshot/$package.tar.gz"
					install_packages
				fi
			done < $remote_packages
		fi
	else
		print_error_connection
	fi
}

function verify_packages {
	local result_count=$( curl -s -X 'GET' "$base_url/rpc/v5/info?${name_args}" -H "$type_application" | jq '.resultcount' )
	if [[ $result_count -eq 0 ]] ; then
		echo "no results, check the reported packages"
	else
		local response=$( curl -s -X 'GET' "$base_url/rpc/v5/info?${name_args}" -H "$type_application" | jq '.results[]' )
		local results=$( echo "$response" | jq '{Name, Version}')

		for row in $( echo "$results" | jq -r '@base64' ); do
			_jq() {
				echo ${row} | base64 --decode | jq -r ${1}
			}
			local remote_name=$( echo $(_jq '.Name') )
			local remote_version=$( echo $(_jq '.Version') )
			echo $remote_name $remote_version >> $remote_packages
		done
	fi
}

function install_packages {
	cd "$temp_directory"
	echo "downloading the $BOLD${GREEN}$package${RESET} package..."
	curl -O "$url"
	echo "unpacking the $BOLD${GREEN}$package${RESET} package..."
	tar -xzvf "$package.tar.gz"
	echo "preparing to install the package $BOLD${GREEN}$package${RESET}"
	if [ -d "$package" ]; then
		cd "$package"
		makepkg -m -c -s --needed --noconfirm

		pkgfile=$(ls *.pkg.tar.* | head -n1)
		as_root pacman -U "$pkgfile" --noconfirm

		if pacman -Q "$package-debug" >/dev/null 2>&1; then
			as_root pacman -R "$package-debug" --noconfirm
		fi

		orphans=$(pacman -Qtdq || true)
		[[ -n "$orphans" ]] && as_root pacman -Rns $orphans --noconfirm
	else
		echo "error to install the package $BOLD${GREEN}$package${RESET}"
	fi

	cd "$directory"
	rm -rf "$temp_directory"/*
}

function update_packages {
	if check_connection; then
		echo -n > $local_packages
		echo -n > $remote_packages
		echo -n > $updated_packages
		pacman -Qm > $local_packages
		echo "$BOLD$BLUE::$RESET$BOLD synchronizing the package database..."$RESET
		packages=("")

		if [ -s "$local_packages" ]; then
			while read -r line; do
				package="$( echo "$line" | cut -d ' ' -f1 )"
				name_args+="arg%5B%5D=$package&"
				packages+="$package "
			done < $local_packages
			name_args=$( echo "$name_args" | tr -d ' ' )
			verify_packages &
			pacman_loading &
			wait
		else
			echo "no aur packages installed"
			return
		fi

		diff $local_packages $remote_packages | grep "> " | cut -d ">" -f 2 | cut -d " " -f 2 > $updated_packages
		
		echo "$BOLD$BLUE::$RESET$BOLD starting full system update...$RESET"
		if [ -s "$updated_packages" ]; then
			while read -r line; do
				package=$line
				url="$base_url/cgit/aur.git/snapshot/$package.tar.gz"
				install_packages
			done < $updated_packages
		else
			echo "nothing to do"
		fi
	else
		print_error_connection
	fi
}

function pacman_loading {
    for package in $packages; do
    	local delay=0.003
		local current_pos=0
		local total_dots=50
		local pacman_frames=('C' 'c')
	    local dots_line=$(printf "%0.s∙" $(seq 1 $total_dots))

    	while [ $current_pos -le $total_dots ]; do
	        local anim_index=$((current_pos % 4))
	        local percentage=$((current_pos * 100 / total_dots))
	        local display_line="${dots_line:0:current_pos}${YELLOW}${pacman_frames[$anim_index]}${RESET}${dots_line:current_pos+1}"

	       	printf "\r %3d%% [ %s ] [ %s ]" "${percentage}" "${display_line}" "${package}"
	        current_pos=$((current_pos + 1))
	        sleep $delay
	    done
    	echo "$RESET"
    done  
}

function search_packages {
	if check_connection; then
		echo "searching..."
		for package in $packages; do
			local result_count=$( curl -s -X 'GET' "$base_url/rpc/v5/search/$package?by=name" -H "$type_application" | jq '.resultcount' )
			if [[ $result_count -eq 0 ]] ; then
				echo "no results found"
			else
				local response=$( curl -s -X 'GET' "$base_url/rpc/v5/search/$package?by=name" -H "$type_application" | jq '.results[]' )
				local results=$( echo "$response" | jq '{Maintainer, Name, Description, Version}')
				local local_version=$( pacman -Qm | grep $package | cut -d' ' -f2 )
					
				for row in $( echo "$results" | jq -r '@base64' ); do
					_jq() {
						echo ${row} | base64 --decode | jq -r ${1}
					}
					local maintainer=$( echo $(_jq '.Maintainer') )
					local name=$( echo $(_jq '.Name') )
					local remote_version=$( echo $(_jq '.Version') )
					local description=$( echo $(_jq '.Description') )

					if [[ "$remote_version" == "$local_version" ]]; then
						printf "%s %s" "$BOLD$PINK$maintainer/$RESET$BOLD$name" "${GREEN}$remote_version ${BLUE}[installed]"
					else
						printf "%s %s" "$BOLD$PINK$maintainer/$RESET$BOLD$name" "${GREEN}$remote_version"
					fi
					printf "\n\t %s\n" "$RESET$description"
				done
			fi
		done
	else
		print_error_connection
	fi
}

function remove_packages {
	for package in $packages; do
		local condition=$( pacman -Q | grep $package )
		if [ -z "$condition" ]; then
			echo "package $package not exist"
		else
			as_root pacman -R "$package" --noconfirm
			as_root pacman -Rns "$(pacman -Qtdq)" --noconfirm
		fi
	done
}

function list_local_packages {
	for package in $packages; do
		pacman -Qm | grep $package
	done
}

case $option in
	"--sync"|"-S"		) [[ -z "$packages" ]] && print_error || check_packages;;
	"--remove"|"-R"		) [[ -z "$packages" ]] && print_error || remove_packages;;
	"--search"|"-Ss"	) [[ -z "$packages" ]] && print_error || search_packages;;
	"--update"|"-Sy"	) [[ -z "$packages" ]] && update_packages || print_error;;
	"--list"|"-L"		) [[ -z "$packages" ]] && pacman -Qm || list_local_packages;;
	"--help"|"-h"		) print_manual;;
	"--version"|"-V"	) print_version ;;
	*) print_error;;
esac