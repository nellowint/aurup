#!\bin\bash
#Update Package AUR

cd /tmp/
option="$1"
package="$2"
version="1.0.0-alpha15"

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

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
	echo "listing similar packages..." 
	wait
}

function installPackage {
	echo ""
	wget -q $url
	tar -xzf "$package.tar.gz"
	cd "$package"
	makepkg -m -c -si --needed --noconfirm
	sudo rm -rf "/tmp/$package"
	sudo rm -rf "/tmp/$package.tar.gz" 
}

function verifyPackageVersion {
	aurPackageVersion="$( w3m -dump "https://aur.archlinux.org/packages?O=0&SeB=N&K=$package&outdated=&SB=n&SO=a&PP=100&submit=Go" | sed -n "/^$package/p" | cut -d' ' -f2 )"
	localPackageVersion=$( pacman -Qm | grep $package | cut -d' ' -f2 )
	if [[ "$aurPackageVersion" == "$localPackageVersion" ]]; then
		return 0
	fi
	return 1
}

function updatePackages {
	allPackages="/tmp/allPackages.txt"
	outdatedPackages="/tmp/outdatedPackages.txt"
	echo -n > $allPackages
	echo -n > $outdatedPackages
	
	pacman -Qm > $allPackages
	echo "updating the database, please wait..."

	while read -r line; do
		package="$( echo "$line" | cut -d' ' -f1 )"
		if verifyPackageVersion; then
			echo "${green}$package ${reset}is on the latest version"
		else
			echo "${red}$package ${reset}needs to be updated"
			echo "$package" >> $outdatedPackages
		fi
	done < $allPackages

	if [ -s "$outdatedPackages" ]; then
		sudo mount -o remount,size=10G /tmp
		while read -r line; do
			package=$line
			url="https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz"
			installPackage
		done < $outdatedPackages
		removeDependecy
	else
		echo ""
		echo "there are no packages to update"
	fi

	rm -rf "$allPackages"
	rm -rf "$outdatedPackages"
}

function verifyDependency {
	dependency=$( pacman -Qs w3m )
	if [ "$dependency" == "" ]; then
		pacman -S w3m --noconfirm
	fi
}

function removeDependecy {
	sudo pacman -Rns $(pacman -Qtdq) --noconfirm
}

if [[ "$option" == "--list" || "$option" == "-L" ]]; then
	if [ -z "$package" ]; then
		pacman -Qm
	else
		pacman -Qm | grep $package
	fi
elif [[ "$option" == "--sync" || "$option" == "-S" ]]; then
	url="https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz"
	requestCode="$( curl -Is "$url" | head -1 )"
	if [ -z "$package" ]; then
		printError
	elif [[ $requestCode == *"200"* ]]; then
		verifyDependency
		if verifyPackageVersion; then
			echo "${green}$package ${reset}is in the latest version"
		else
			sudo mount -o remount,size=10G /tmp
			installPackage
			removeDependecy
		fi
	else
		echo "package does not exist in aur repository"
	fi
elif [[ "$option" == "--update" || "$option" == "-Sy" ]]; then
	if [ -z "$package" ]; then
		verifyDependency
		updatePackages
	fi
elif [[ "$option" == "--remove" || "$option" == "-R" ]]; then
	if [ -z "$package" ]; then
		printError
	else
		condition=$( pacman -Q | grep $package )
		if [ -z "$condition" ]; then
			echo "Package $package not exist"
		else
			sudo pacman -R "$package"
			sudo pacman -Rns $(pacman -Qtdq) --noconfirm
		fi
	fi
elif [[ "$option" == "--help" || "$option" == "-h" ]]; then
	printManual
elif [[ "$option" == "--search" || "$option" == "-Ss" ]]; then
	if [ -z "$package" ]; then
		printError
	else
		verifyDependency
		searchPackage
	fi
elif [[ "$option" == "--version" || "$option" == "-V" ]]; then
	printVersion
else
	printError
fi