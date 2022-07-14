#!\bin\bash
#file install aurup in /opt/aurup

directory="/$HOME/.aurup"

function checkingDependencies {
	dependencies=("bash-completion" "curl" "sudo" "tar" "wget" "w3m")
	for dependency in $dependencies; do
		condition=$( pacman -Qs $dependency )
		if [ "$dependency" == "" ]; then
			sudo pacman -S $dependency --noconfirm
		else
			echo -e "checking dependencies to install aurup..."
			sleep 1
		fi
	done
	echo "aurup installed successfully"
}

if [ -d $directory ]; then
	echo "aurup is installed in $directory"
else
	mkdir $directory
	cp "$PWD/src/aurup.sh" $directory
	chmod +x "$directory/aurup.sh"
	sudo cp "$PWD/src/aurup-complete.sh" "/usr/share/bash-completion/completions/"
	echo -e "\nalias aurup='sh $directory/aurup.sh'\n" >> "/$HOME/.bashrc"
	echo -e "source /usr/share/bash-completion/completions/aurup-complete.sh" >> "/$HOME/.bashrc"
	checkingDependencies
	exec bash --login
fi