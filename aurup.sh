#!\bin\bash
# Maintainer: Wellinton Vieira <wellintonvieira.office@gmail.com>
# The simplify finding and installing packages AUR helper

option="$1"
packages="${@:2}"
version="1.0.0"
name="aurup"
author="wellintonvieira"
directory="$HOME/.$name"
directory_temp="$directory/tmp"
local_packages="$directory/local_packages.txt"
remote_packages="$directory/remote_packages.txt"
base_url="https://aur.archlinux.org/rpc/v5"
type_application="accept: application/json"

mkdir $directory
mkdir "$directory_temp"

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 11)
PINK=$(tput setaf 5)
BLUE=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

function print_manual {
	echo "use:  $name <operation> [...]"
	echo "operations:"
	echo "$name {-S  --sync      } [package name]"
	echo "$name {-R  --remove    } [package name]"
	echo "$name {-Ss --search    } [package name]"
	echo "$name {-L  --list      } [package name]"
	echo "$name {-L  --list      }"
	echo "$name {-Sy --update    }"
	echo "$name {-c  --clear     }"
	echo "$name {-h  --help      }"
	echo "$name {-V  --version   }"
}

function print_version {
	echo "$BOLD$PINK$name $RESET$BOLD$GREEN$version$RESET"
	echo "2019-2025 Vieirateam Developers"
	echo "this is free software: you are free to change and redistribute it."
	echo "learn more at https://github.com/$author/$name "
}

function print_error {
	echo "invalid option, consult manual with command $name --help"
}

function print_error_connection {
	echo "no internet connection!"
}

function check_connection {
	local response="$( curl -s -I https://aur.archlinux.org/rpc/swagger )"
	local status_code=$( echo $response | grep "HTTP" | cut -d " " -f 2 )
	if [[ $status_code -eq "200" ]]; then
		return 0
	fi
	return 1
}

function check_package {
	if check_connection; then
		for package in $packages; do
			has_update=1
			verify_package_version
		done
	else
		print_error_connection
	fi
}

function verify_package_version {
	local result_count=$( curl -s -X 'GET' "$base_url/info/$package" -H "$type_application" | jq '.resultcount' )
	if [[ $result_count -eq 0 ]] ; then
		echo "$BOLD${RED}$package${RESET} does not exist in aur repository"
	else
		local response=$( curl -s -X 'GET' "$base_url/info/$package" -H "$type_application" | jq '.results[]' )
		local results=$( echo "$response" | jq '{Name, Description, URLPath, Version}')
		local local_version=$( pacman -Qm | grep $package | cut -d' ' -f2 )
		local remote_version=$( echo "${results}" | jq -r .Version)
		url=$( echo "${results}" | jq -r .URLPath)

		if [[ "$remote_version" == "$local_version" ]]; then
			if [[ $has_update -eq 1 ]]; then
				echo "$BOLD${GREEN}$package${RESET} is on the latest version"
			fi
		else
			if [[ $has_update -eq 0 ]]; then
				echo "$package" >> $remote_packages
			else
				install_package
			fi
		fi
	fi
}

function install_package {
	echo "preparing to install the package $BOLD${GREEN}$package${RESET}"
	cd $directory_temp
	if [ -d "$package" ]; then
		rm -rf "$package"
		rm -rf "$package.tar.gz"
	fi
	curl -s -O "https://aur.archlinux.org/$url"
	tar -xzf "$package.tar.gz"
	cd "$package"
	makepkg -m -c -si --needed --noconfirm

	local condition=$( pacman -Q | grep "$package-debug" )
	if [ -z "$condition" ]; then
		echo "nothing to do..."
	else
		sudo pacman -R "$package-debug" --noconfirm
		sudo pacman -Rns $(pacman -Qtdq) --noconfirm
	fi
}

function update_packages {
	if check_connection; then
		echo -n > $remote_packages
		echo "$BOLD$BLUE::$RESET$BOLD synchronizing the package database..."$RESET
		
		package=$name
		delay=0.1
		message='core'
		pacman_loading

		delay=0.3
		has_update=0
		message='aur '
		pacman_loading &
		check_packages &
		wait
		
		echo "$BOLD$BLUE::$RESET$BOLD starting full system update...$RESET"
		if [ -s "$remote_packages" ]; then
			while read -r line; do
				package=$line
				url="https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz"
				install_package
			done < $remote_packages
		else
			echo "nothing to do"
		fi

		if [[ $app_updated -eq 0 ]]; then
			update_app
		fi
		clear_cache
	else
		print_error_connection
	fi
}

function check_packages {
	echo -n > $local_packages
	pacman -Qm > $local_packages
	while read -r line; do
		package="$( echo "$line" | cut -d' ' -f1 )"
		verify_package_version
	done < $local_packages
}

function search_package {
	if check_connection; then
		echo "searching..."
		for package in $packages; do
			local result_count=$( curl -s -X 'GET' "$base_url/search/$package?by=name" -H "$type_application" | jq '.resultcount' )
			if [[ $result_count -eq 0 ]] ; then
				echo "no results found"
			else
				local response=$( curl -s -X 'GET' "$base_url/search/$package?by=name" -H "$type_application" | jq '.results[]' )
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

function remove_package {
	for package in $packages; do
		local condition=$( pacman -Q | grep $package )
		if [ -z "$condition" ]; then
			echo "package $package not exist"
		else
			sudo pacman -R "$package" --noconfirm
			sudo pacman -Rns $(pacman -Qtdq) --noconfirm
		fi
	done
	clear_cache
}

function list_local_packages {
	for package in $packages; do
		pacman -Qm | grep $package
	done
}

function clear_cache {
	rm -rf "$directory_temp"
	mkdir "$directory_temp"
}

function pacman_loading {
	local current_pos=0
	local total_dots=50
	local pacman_frames=('C' 'c')
    local dots_line=$(printf "%0.s∙" $(seq 1 $total_dots))
    
    while [ $current_pos -le $total_dots ]; do
        local anim_index=$((current_pos % 4))
        local percentage=$((current_pos * 100 / total_dots))
        local display_line="${dots_line:0:current_pos}${YELLOW}${pacman_frames[$anim_index]}${RESET}${dots_line:current_pos+1}"

        printf "\r ${message} [ ${display_line} ] [ ${percentage}%% ]"
        current_pos=$((current_pos + 1))
        sleep $delay
    done
    echo "$RESET"
}

case $option in
	"--sync"|"-S"		) [[ -z "$packages" ]] && print_error || check_package;;
	"--remove"|"-R"		) [[ -z "$packages" ]] && print_error || remove_package;;
	"--search"|"-Ss"	) [[ -z "$packages" ]] && print_error || search_package;;
	"--update"|"-Sy"	) [[ -z "$packages" ]] && update_packages || print_error;;
	"--list"|"-L"		) [[ -z "$packages" ]] && pacman -Qm || list_local_packages;;
	"--clear"|"-c"		) clear_cache;;
	"--help"|"-h"		) print_manual;;
	"--version"|"-V"	) print_version ;;
	*) print_error;;
esac