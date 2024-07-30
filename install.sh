#!\bin\bash
#file install aurup in /$HOME/.aurup

name="aurup"
directory="$HOME/.$name"

function checkingDependencies {
	dependencies="adwaita-icon-theme bash-completion curl cronie libnotify tar w3m"
	echo "checking dependencies to be installed..."
	for dependency in $dependencies; do
		local condition=$( pacman -Q | grep $dependency )
		if [ -z "$condition" ]; then
			echo "preparing to install the dependency $dependency"
			sudo pacman -S $dependency --noconfirm
		fi
		sleep 1
	done
}

function installApp {
	mkdir $directory
	mkdir "$directory/tmp"
	cp "$PWD/src/$name.sh" $directory
	cp "$PWD/src/$name-background.sh" $directory
	chmod +x "$directory/$name.sh"
	chmod +x "$directory/$name-background.sh"
	sudo cp "$PWD/src/$name-complete.sh" "/usr/share/bash-completion/completions/"
	echo -e "\nalias $name='sh $directory/$name.sh'\n" >> "/$HOME/.bashrc"
	echo -e "source /usr/share/bash-completion/completions/$name-complete.sh" >> "/$HOME/.bashrc"
	exec bash --login
}

if [ -d $directory ]; then
	rm -rf "$directory"
	sudo rm -rf "/usr/share/bash-completion/completions/$name-complete.sh"
	sed -i "/$name/d" "/$HOME/.bashrc"
fi

checkingDependencies
installApp