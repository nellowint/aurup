#!\bin\bash
# Maintainer: Wellinton Vieira <wellintonvieira.office@gmail.com>
# The simplify finding and installing packages AUR helper

option="$1"
packages="${@:2}"
pkgname="aurup"
pkgver="1.70"
author="nellowint"
has_update=0
local_packages="/tmp/local_packages.txt"
remote_packages="/tmp/remote_packages.txt"
base_url="https://aur.archlinux.org/rpc/v5"
type_application="accept: application/json"

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 11)
PINK=$(tput setaf 5)
BLUE=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

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
	echo "2019-2025 Vieirateam Developers"
	echo "this is free software: you are free to change and redistribute it."
	echo "learn more at https://github.com/$author/$pkgname "
}

function print_error {
	echo "invalid option, consult manual with command $pkgname --help"
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
		local remote_url=$( echo "${results}" | jq -r .URLPath)

		if [[ "$remote_version" == "$local_version" ]]; then
			if [[ $has_update -eq 1 ]]; then
				echo "$BOLD${GREEN}$package${RESET} is on the latest version"
			fi
		else
			if [[ $has_update -eq 0 ]]; then
				echo "$package" >> $remote_packages
			else
				url=https://aur.archlinux.org/$remote_url
				install_package
			fi
		fi
	fi
}

function install_package {
	echo "preparing to install the package $BOLD${GREEN}$package${RESET}"
	cd "/tmp/"
	if [ -d "$package" ]; then
		rm -rf "$package"
		rm -rf "$package.tar.gz"
	fi
	curl -s -O "$url"
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
		echo -n > $local_packages
		pacman -Qm > $local_packages
		echo "$BOLD$BLUE::$RESET$BOLD synchronizing the package database..."$RESET

		if [ -s "$local_packages" ]; then
			while read -r line; do
				package="$( echo "$line" | cut -d' ' -f1 )"
				pacman_loading &
				verify_package_version &
				wait
			done < $local_packages
		else
			echo "no aur packages installed"
			return
		fi
		
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
	else
		print_error_connection
	fi
}

function pacman_loading {
	local delay=0.01
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
}

function list_local_packages {
	for package in $packages; do
		pacman -Qm | grep $package
	done
}

case $option in
	"--sync"|"-S"		) [[ -z "$packages" ]] && print_error || check_package;;
	"--remove"|"-R"		) [[ -z "$packages" ]] && print_error || remove_package;;
	"--search"|"-Ss"	) [[ -z "$packages" ]] && print_error || search_package;;
	"--update"|"-Sy"	) [[ -z "$packages" ]] && update_packages || print_error;;
	"--list"|"-L"		) [[ -z "$packages" ]] && pacman -Qm || list_local_packages;;
	"--help"|"-h"		) print_manual;;
	"--version"|"-V"	) print_version ;;
	*) print_error;;
esac