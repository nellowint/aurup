#!\bin\bash
#Update Package AUR

option="$1"
packages="${@:2}"
version="1.0.0-alpha21"
directory="/$HOME/.aurup"

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

function printError {
	echo "invalid option, consult manual with command aurup --help"
}

function printManual {
	echo "use:  aurup <operation> [...]"
	echo "operations:"
	echo "aurup {-S  --sync      } [package name]"
	echo "aurup {-R  --remove    } [package name]"
	echo "aurup {-Ss --search    } [package name]"
	echo "aurup {-L  --list      } [package name]"
	echo "aurup {-L  --list      }"
	echo "aurup {-Sy --update    }"
	echo "aurup {-h  --help      }"
	echo "aurup {-U  --uninstall }"
	echo "aurup {-V  --version   }"
}

function printVersion {
	echo "aurup $version"
	echo "2019-2022 Vieirateam Developers"
	echo "this is free software: you are free to change and redistribute it."
	echo "learn more at https://github.com/wellintonvieira/aurup "
}

function checkPackage {
	local hasDependency=false
	for package in $packages; do
		url="https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz"
		requestCode="$( curl -Is "$url" | head -1 )"
		if [[ $requestCode == *"200"* ]]; then
			if verifyPackageVersion; then
				echo "${green}$package ${reset}is in the latest version"
			else
				installPackage
				hasDependency=true
			fi
		else
			echo "${red}$package ${reset}does not exist in aur repository"
		fi
	done

	if [ $hasDependency ]; then
		removeDependecy
	fi
}

function installPackage {
	echo "preparing to install the package ${green}$package${reset}"
	cd $directory
	wget -q $url
	tar -xzf "$package.tar.gz"
	cd "$package"
	makepkg -m -c -si --needed --noconfirm
	rm -rf "$directory/$package"
	rm -rf "$directory/$package.tar.gz"
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

function searchPackage {
	echo "listing similar packages..."
	for package in $packages; do
		url="https://aur.archlinux.org/packages/?O=0&SeB=nd&K=$package&outdated=&SB=n&SO=a&PP=100&do_Search=Go"
		w3m -dump $url | sed -n "/^$package/p"
		echo ""
	done
}

function removePackage {
	for package in $packages; do
		condition=$( pacman -Q | grep $package )
		if [ -z "$condition" ]; then
			echo "Package $package not exist"
		else
			sudo pacman -R "$package" --noconfirm
		fi
	done
	removeDependecy
}

function removeDependecy {
	sudo pacman -Rns $(pacman -Qtdq) --noconfirm
}

function uninstallAurup {
	if [ -d $directory ]; then
		rm -rf "$directory"
		sudo rm -rf "/usr/share/bash-completion/completions/aurup-complete.sh"
		sed -i "/aurup/d" "/$HOME/.bashrc"
		echo "aurup was uninstalled successfully"
		exec bash --login
	else
		echo "aurup is not installed"
	fi
}

case $option in
	"--sync"|"-S" )
		if [ -z "$packages" ]; then
			printError
		else
			checkPackage
		fi	
	;;
	"--remove"|"-R" )
		if [ -z "$packages" ]; then
			printError
		else
			removePackage
		fi
	;;
	"--search"|"-Ss" )
		if [ -z "$packages" ]; then
			printError
		else
			searchPackage
		fi
	;;
	"--update"|"-Sy" )
		if [ -z "$package" ]; then
			updatePackages
		else
			printError
		fi
	;;
	"--list"|"-L")
		if [ -z "$packages" ]; then
			pacman -Qm
		else
			for package in $packages; do
				pacman -Qm | grep $package
			done
		fi
	;;
	"--help"|"-h" )
		printManual
	;;
	"--uninstall"|"-U" )
		uninstallAurup
	;;
	"--version"|"-V" )
		printVersion
	;;
	*)
		printError
	;;
esac