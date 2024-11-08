#!\bin\bash
#Update Packages AUR

option="$1"
packages="${@:2}"
version="1.0.0-alpha52"
name="aurup"
author="wellintonvieira"
directory="$HOME/.$name"
directoryTemp="$directory/tmp"
allPackages="$directory/allPackages.txt"
outdatedPackages="$directory/outdatedPackages.txt"

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

function printManual {
	echo "use:  $name <operation> [...]"
	echo "operations:"
	echo "$name {-S  --sync      } [package name]"
	echo "$name {-R  --remove    } [package name]"
	echo "$name {-Ss --search    } [package name]"
	echo "$name {-L  --list      } [package name]"
	echo "$name {-L  --list      }"
	echo "$name {-Sy --update    }"
	echo "$name {-c  --clear     }"
	echo "$name {-h  --help      }"
	echo "$name {-U  --uninstall }"
	echo "$name {-V  --version   }"
}

function printVersion {
	echo "$name $version"
	echo "2019-2024 Vieirateam Developers"
	echo "this is free software: you are free to change and redistribute it."
	echo "learn more at https://github.com/$author/$name "
}

function printError {
	echo "invalid option, consult manual with command $name --help"
}

function printErrorConnection {
	echo "unable to establish an internet connection."
}

function checkConnection {
	ping aur.archlinux.org -c 1 > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		return 0
	fi
	return 1
}

function checkPackage {
	if checkConnection; then
		for package in $packages; do
			url="https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz"
			local requestCode="$( curl -Is "$url" | head -1 )"
			if [[ $requestCode == *"200"* ]]; then
				local aurPackageVersion="$( w3m -dump "https://aur.archlinux.org/packages?O=0&SeB=N&K=$package&outdated=&SB=n&SO=a&PP=100&submit=Go" | sed -n "/^$package/p" | cut -d' ' -f2 )"
				local localPackageVersion=$( pacman -Qm | grep $package | cut -d' ' -f2 )
				if [[ "$aurPackageVersion" == "$localPackageVersion" ]]; then
					echo "${green}$package ${reset}is in the latest version"
				else
					installPackage
				fi
			else
				echo "${red}$package ${reset}does not exist in aur repository"
			fi
		done
	else
		printErrorConnection
	fi
}

function verifyPackageVersion {
	local aurPackageVersion="$( w3m -dump "https://aur.archlinux.org/packages?O=0&SeB=N&K=$package&outdated=&SB=n&SO=a&PP=100&submit=Go" | sed -n "/^$package/p" | cut -d' ' -f2 )"
	local localPackageVersion=$( pacman -Qm | grep $package | cut -d' ' -f2 )
	if [[ "$aurPackageVersion" == "$localPackageVersion" ]]; then
		return 0
	fi
	return 1
}

function installPackage {
	echo "preparing to install the package ${green}$package${reset}"
	cd $directoryTemp
	if [ -d "$package" ]; then
		rm -rf "$package"
		rm -rf "$package.tar.gz"
	fi
	curl -s -O $url
	tar -xzf "$package.tar.gz"
	cd "$package"
	makepkg -m -c -si --needed --noconfirm

	local condition=$( pacman -Q | grep "$package-debug" )
	if [ -z "$condition" ]; then
		echo "nothing to do..."
	else
		sudo pacman -R "$package-debug" --noconfirm
		sudo pacman -Rns $(pacman -Qtdq) --noconfirm
	fi
}

function verifyVersion {
	local serverVersion="$( w3m -dump "https://raw.githubusercontent.com/$author/$name/main/src/$name.sh" | grep "version" | head -n 1 | sed 's/version=//' | sed 's/ //g' | sed 's/"//g' )"
	if [[ "$version" == "$serverVersion" ]]; then
		return 0
	fi
	return 1
}

function updatePackages {
	if checkConnection; then
		echo "updating the database, please wait..."
		echo -n > $allPackages
		echo -n > $outdatedPackages
		pacman -Qm > $allPackages

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
		else
			echo "nothing to do, database updated..."
		fi
		updateApp
		clearCache
	else
		printErrorConnection
	fi
}

function updateApp {
	if checkConnection; then
		if verifyVersion; then
			echo "${green}$name ${reset}is on the latest version"
		else
			cd /tmp/
			if [ -d "$name" ]; then
				rm -rf "$name"
			fi
			echo "${red}$name ${reset}needs to be updated"
			git clone "https://github.com/$author/$name.git"
			echo "preparing to install the package ${green}$name${reset}"
			cd $name
			sh install.sh
			cd $HOME
		fi
	else
		printErrorConnection
	fi
}

function searchPackage {
	if checkConnection; then
		echo "listing similar packages..."
		for package in $packages; do
			url="https://aur.archlinux.org/packages/?O=0&SeB=nd&K=$package&outdated=&SB=n&SO=a&PP=100&do_Search=Go"
			w3m -dump $url | sed -n "/^$package/p"
			echo ""
		done
	else
		printErrorConnection
	fi
}

function removePackage {
	for package in $packages; do
		local condition=$( pacman -Q | grep $package )
		if [ -z "$condition" ]; then
			echo "package $package not exist"
		else
			sudo pacman -R "$package" --noconfirm
			sudo pacman -Rns $(pacman -Qtdq) --noconfirm
		fi
	done
	clearCache
}

function listLocalPackages {
	for package in $packages; do
		pacman -Qm | grep $package
	done
}

function clearCache {
	rm -rf "$directoryTemp"
	mkdir "$directoryTemp"
	echo -n > $outdatedPackages
}

function uninstallApp {
	if [ -d $directory ]; then
		rm -rf "$directory"
		sudo rm -rf "/usr/share/bash-completion/completions/$name-complete.sh"
		sed -i "/$name/d" "/$HOME/.bashrc"
		echo "$name was uninstalled successfully"
		exec bash --login
	else
		echo "$name is not installed"
	fi
}

case $option in
	"--sync"|"-S"		) [[ -z "$packages" ]] && printError || checkPackage;;
	"--remove"|"-R"		) [[ -z "$packages" ]] && printError || removePackage;;
	"--search"|"-Ss"	) [[ -z "$packages" ]] && printError || searchPackage;;
	"--update"|"-Sy"	) [[ -z "$packages" ]] && updatePackages || printError;;
	"--list"|"-L"		) [[ -z "$packages" ]] && pacman -Qm || listLocalPackages;;
	"--clear"|"-c"		) clearCache;;
	"--help"|"-h"		) printManual;;
	"--uninstall"|"-U"	) uninstallApp;;
	"--version"|"-V"	) printVersion ;;
	*) printError;;
esac