#!\bin\bash
#Update Package AUR

cd /tmp/
option="$1"
package="$2"
version="1.0.0-alpha09"

function printError {
	echo "invalid option, consult manual with command aurup --help"
}

function printManual {
	echo "use:  aurup <operation> [...]"
	echo "operations:"
	echo "aurup {-S  --sync   } [package name]"
	echo "aurup {-R  --remove } [package name]"
	echo "aurup {-Ss --search } [package name]"
	echo "aurup {-Sy --update }"
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

function verifyPackageVersion {
	condition1="$( w3m -dump "https://aur.archlinux.org/packages?O=0&SeB=N&K=$package&outdated=&SB=n&SO=a&PP=100&submit=Go" | sed -n "/^$package/p" | cut -d' ' -f2 )"
	condition2=$( sudo pacman -Qm | grep $package | cut -d' ' -f2 )
	if [[ "$condition1" == "$condition2" ]]; then
		echo "package is in the latest version"
	else	
		sudo mount -o remount,size=10G /tmp
		wget -q $url
		tar -xzf "$package.tar.gz"
		cd "$package"
		makepkg -m -c -si --needed --noconfirm
		sudo rm -rf "/tmp/$package"
		sudo rm -rf "/tmp/$package.tar.gz"
		sudo pacman -Rns $(pacman -Qtdq) --noconfirm
	fi
}

function updatePackages {
	file1="/tmp/aurup.txt"
	file2="/tmp/packages.txt"
	sudo pacman -Qm > $file1
	echo -ne "updating the database, please wait"
	while read -r line; do
	echo -ne "."
	package="$( echo "$line" | cut -d' ' -f1 )"
	condition1="$( w3m -dump "https://aur.archlinux.org/packages?O=0&SeB=N&K=$package&outdated=&SB=n&SO=a&PP=100&submit=Go" | sed -n "/^$package/p" | cut -d' ' -f2 )"
	condition2=$( sudo pacman -Qm | grep $package | cut -d' ' -f2 )
		if [[ "$condition1" != "$condition2" ]]; then
			echo "$package" >> $file2
		fi
	done < $file1

	if [ -s "$file2" ]; then
		sudo mount -o remount,size=10G /tmp
		while read -r line; do
			url="https://aur.archlinux.org/cgit/aur.git/snapshot/$line.tar.gz"
			wget -q $url
			tar -xzf "$line.tar.gz"
			cd "$line"
			makepkg -m -c -si --needed --noconfirm
			sudo rm -rf "/tmp/$line"
			sudo rm -rf "/tmp/$line.tar.gz"
		done < $file2
	else
		echo ""
		echo "there are no packages to update"
	fi
	sudo rm -rf "$file1"
	sudo rm -rf "$file2"
	sudo pacman -Rns $(pacman -Qtdq) --noconfirm
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
		verifyPackageVersion
	else
		echo "package does not exist in aur repository"
	fi	

elif [[ "$option" == "--update" || "$option" == "-Sy" ]]; 
then
	updatePackages
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