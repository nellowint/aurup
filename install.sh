#!\bin\bash
#file install aurup in /opt/aurup

if [ -d "/opt/aurup" ]; then
	echo "aurup is installed in /opt/aurup"
else
	dependency=$( pacman -Qs bash-completion )
	if [ "$dependency" == "" ]; then
		sudo pacman -S bash-completion --noconfirm
	fi
	sudo mkdir "/opt/aurup"
	sudo cp "$PWD/src/aurup.sh" "/opt/aurup"
	sudo cp "$PWD/src/aurup-complete.sh" "/usr/share/bash-completion/completions/"
	sudo chmod +x "/opt/aurup/aurup.sh"
	sudo chmod +x "/$PWD/uninstall.sh"
	echo -e "\nalias aurup='sh /opt/aurup/aurup.sh'\n" >> "/$HOME/.bashrc"
	echo -e "source /usr/share/bash-completion/completions/aurup-complete.sh" >> "/$HOME/.bashrc"
	exec bash --login
fi