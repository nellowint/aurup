#!\bin\bash
#file install aurup in /$HOME/.aurup

name="aurup"
directory="$HOME/.$name"

function checkingDependencies {
	dependencies="bash-completion curl cronie tar w3m"
	for dependency in $dependencies; do
		echo "checking dependencies to be installed..."
		local condition=$( pacman -Qs $dependency )
		if [ -z "$condition" ]; then
			echo -e "$dependency dependency already installed."
			sleep 1
		else
			echo "preparing to install the dependency $dependency"
			sudo pacman -S $dependency --noconfirm
		fi
	done
}

function installApp {
	mkdir $directory
	mkdir "$directory/tmp"
	cp "$PWD/src/$name.sh" $directory
	chmod +x "$directory/$name.sh"
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