#!\bin\bash
#file install aurup in /$HOME/.aurup

name="aurup"
directory="$HOME/.$name"

function checking_dependencies {
	if check_connection; then
		dependencies="bash-completion curl jq tar"
		echo "checking dependencies to be installed..."
		for dependency in $dependencies; do
			local condition=$( pacman -Q | grep $dependency )
			if [ -z "$condition" ]; then
				echo "preparing to install the dependency $dependency"
				sudo pacman -S $dependency --noconfirm
			fi
			sleep 1
		done
	else
		echo "no internet connection!"
	fi
}

function check_connection {
	local response="$( curl -s -I https://aur.archlinux.org/rpc/swagger )"
	local status_code=$( echo $response | grep "HTTP" | cut -d " " -f 2 )
	if [[ $status_code -eq "200" ]]; then
		return 0
	fi
	return 1
}

function install_app {
	mkdir $directory
	mkdir "$directory/tmp"
	cp "$PWD/src/$name.sh" $directory
	chmod +x "$directory/$name.sh"
	sudo cp "$PWD/src/$name-complete.sh" "/usr/share/bash-completion/completions/"
	echo -e "\nalias $name='sh $directory/$name.sh'\n" >> "/$HOME/.bashrc"
	echo -e "source /usr/share/bash-completion/completions/$name-complete.sh" >> "/$HOME/.bashrc"
	echo "installation completed successfully."
	exec bash --login
}

if [ -d $directory ]; then
	rm -rf "$directory"
	sudo rm -rf "/usr/share/bash-completion/completions/$name-complete.sh"
	sed -i "/$name/d" "/$HOME/.bashrc"
fi

checking_dependencies
install_app