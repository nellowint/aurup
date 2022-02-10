#!\bin\bash
#Update Package AUR

cd /tmp/
option="$1"
package="$2"
version="1.0.0-alpha08"

function printError {
	echo "invalid option, consult manual with command aurup --help"
}

function printManual {
	echo "use:  aurup <operation> [...]"
	echo "operations:"
	echo "aurup {-S  --sync   } [package name]"
	echo "aurup {-R  --remove } [package name]"
	echo "aurup {-Ss --search } [package name]"
	echo "aurup {-L  --list   }"
	echo "aurup {-h  --help   }"
	echo "aurup {-V  --version}"
}

function printVersion {
	echo "aurup $version"
	echo "copyright (C) 2019-2022 Vieirateam Developers"
	echo "this is free software: you are free to change and redistribute it."
	echo "learn more at https://github.com/wellintonvieira/aurup "
}

function searchPackage {
	url="https://aur.archlinux.org/packages/?O=0&SeB=nd&K=$package&outdated=&SB=n&SO=a&PP=100&do_Search=Go"
	w3m -dump $url | sed -n "/^$package/p" & 
	echo "listing similar packages to search: $package" 
	wait
}

if [[ "$option" == "--list" || "$option" == "-L" ]];
then
	sudo pacman -Qm
elif [[ "$option" == "--sync" || "$option" == "-S" ]];
then
	url="https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz"
	condition="$( curl -Is "$url" | head -1 )"
	if [[ "$package" == "" || "$package" == " " ]]; then
		printError
	elif [[ $condition == *"200"* ]]; then
		sudo mount -o remount,size=10G /tmp
		wget -q $url
		tar -xzf "$package.tar.gz"
		cd "$package"
		makepkg -m -c -si --needed --noconfirm
		sudo rm -rf "/tmp/$package"
		sudo rm -rf "/tmp/$package.tar.gz"
		sudo pacman -Rns $(pacman -Qtdq) --noconfirm
	else
		echo "package does not exist in aur repository"
	fi	
elif [[ "$option" == "--remove" || "$option" == "-R" ]]; 
then
	if [[ "$package" == "" || "$package" == " " ]]; then
		printError
	else
		sudo pacman -R "$package"
	fi
elif [[ "$option" == "--help" || "$option" == "-h" ]]; 
then
	printManual
elif [[ "$option" == "--search" || "$option" == "-Ss" ]];
then
	if [[ "$package" == "" || "$package" == " " ]]; then
		printError
	else
		condition=$( pacman -Qs w3m )
		if [ "$condition" == "" ]; then
			sudo pacman -S w3m --noconfirm
			searchPackage
		else
			searchPackage
		fi
	fi
elif [[ "$option" == "--version" || "$option" == "-V" ]]; 
then
	printVersion
else
	printError
fi