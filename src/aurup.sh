#!\bin\bash
#Update Package AUR

option="$1"
parameters="${@:2}"
version="1.0.0-alpha18"
directory="/opt/aurup/tmp"

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
	echo "2019-2022 Vieirateam Developers"
	echo "this is free software: you are free to change and redistribute it."
	echo "learn more at https://github.com/wellintonvieira/aurup "
}

function searchPackage {
	echo "listing similar packages..."
	for package in $parameters; do
		url="https://aur.archlinux.org/packages/?O=0&SeB=nd&K=$package&outdated=&SB=n&SO=a&PP=100&do_Search=Go"
		w3m -dump $url | sed -n "/^$package/p"
		echo ""
	done
}

function checkPackage {
	for package in $parameters; do
		url="https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz"
		requestCode="$( curl -Is "$url" | head -1 )"
		if [[ $requestCode == *"200"* ]]; then
			verifyDependency
			if verifyPackageVersion; then
				echo "${green}$package ${reset}is in the latest version"
			else
				sudo mount -o remount,size=10G /tmp
				makeDirectory
				installPackage
				removeDependecy
			fi
		else
			echo "${red}$package ${reset}does not exist in aur repository"
		fi
	done
}

function installPackage {
	echo ""
	wget -q $url
	tar -xzf "$package.tar.gz"
	cd "$package"
	makepkg -m -c -si --needed --noconfirm
	sudo rm -rf "$package"
	sudo rm -rf "$package.tar.gz" 
}

function removePackage {
	for package in $parameters; do
		condition=$( pacman -Q | grep $package )
		if [ -z "$condition" ]; then
			echo "Package $package not exist"
		else
			sudo pacman -R "$package"
		fi
	done
	sudo pacman -Rns $(pacman -Qtdq) --noconfirm
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
	allPackages="$directory/allPackages.txt"
	outdatedPackages="$directory/outdatedPackages.txt"
	echo -n > $allPackages
	echo -n > $outdatedPackages
	
	sudo pacman -Qm > $allPackages
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

	sudo rm -rf "$allPackages"
	sudo rm -rf "$outdatedPackages"
}

function verifyDependency {
	dependency=$( pacman -Qs w3m )
	if [ "$dependency" == "" ]; then
		sudo pacman -S w3m --noconfirm
	fi
}

function makeDirectory {
	if [ -d $directory ]; then
		echo "directory $directory is exist"
	else
		sudo mkdir $directory
		echo "make directory $directory"
	fi
	cd $directory
}

function removeDependecy {
	sudo pacman -Rns $(pacman -Qtdq) --noconfirm
}

if [[ "$option" == "--list" || "$option" == "-L" ]]; then
	if [ -z "$parameters" ]; then
		sudo pacman -Qm
	else
		for package in $parameters; do
			sudo pacman -Qm | grep $package
		done
	fi
elif [[ "$option" == "--sync" || "$option" == "-S" ]]; then
	if [ -z "$parameters" ]; then
		printError
	else
		checkPackage
	fi
elif [[ "$option" == "--update" || "$option" == "-Sy" ]]; then
	if [ -z "$package" ]; then
		verifyDependency
		makeDirectory
		updatePackages
	else
		printError
	fi
elif [[ "$option" == "--remove" || "$option" == "-R" ]]; then
	if [ -z "$parameters" ]; then
		printError
	else
		removePackage
	fi
elif [[ "$option" == "--help" || "$option" == "-h" ]]; then
	printManual
elif [[ "$option" == "--search" || "$option" == "-Ss" ]]; then
	if [ -z "$parameters" ]; then
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