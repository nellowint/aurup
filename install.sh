#!\bin\bash
#file install aurup in /opt/aurup

if [ -d "/opt/aurup" ]; then
	echo "aurup is installed in /opt/aurup"
else
	sudo mkdir "/opt/aurup"
	sudo cp "$PWD/src/aurup.sh" "/opt/aurup"
	sudo chmod +x "/opt/aurup/aurup.sh"
	sudo chmod +x "/$PWD/uninstall.sh"
	echo -e "\nalias aurup='sh /opt/aurup/aurup.sh'\n" >> "/$HOME/.bashrc"
	echo "aurup was installed successfully"
	exec bash
fi