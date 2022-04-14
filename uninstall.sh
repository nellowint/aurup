#!\bin\bash
#file uninstall aurup in /opt/aurup

if [ -d "/opt/aurup" ]; then
	sudo rm -rf "/opt/aurup"
	sudo rm -rf "/usr/share/bash-completion/completions/aurup-complete.sh"
	sed -i "/alias aurup/d" "/$HOME/.bashrc"
	sed -i "/source/d" "/$HOME/.bashrc"
	echo "aurup was uninstalled successfully"
	exec bash
else
	echo "aurup is not installed"
fi