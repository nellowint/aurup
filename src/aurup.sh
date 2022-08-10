#!\bin\bash
#Update Packages AUR

option="$1"
packages="${@:2}"
version="1.0.0-alpha23"
name="aurup"
directory="$HOME/.$name"
directoryTemp="$directory/tmp"

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

function printError {
	echo "invalid option, consult manual with command $name --help"
}

function printManual {
	echo "use:  $name <operation> [...]"
	echo "operations:"
	echo "$name {-S  --sync      } [package name]"
	echo "$name {-R  --remove    } [package name]"
	echo "$name {-Ss --search    } [package name]"
	echo "$name {-L  --list      } [package name]"
	echo "$name {-L  --list      }"
	echo "$name {-Sy --update    }"
	echo "$name {-h  --help      }"
	echo "$name {-U  --uninstall }"
	echo "$name {-V  --version   }"
}

function printVersion {
	echo "$name $version"
	echo "2019-2022 Vieirateam Developers"
	echo "this is free software: you are free to change and redistribute it."
	echo "learn more at https://github.com/wellintonvieira/$name "
}

function printErrorConection {
	echo "Sorry, Aur.archlinux.org is DOWN for everyone. Try again in a few minutes."
}

function verifyConection {
	local url="https://aur.archlinux.org"
	local requestCode="$( curl -Is "$url" | head -1 )"
	if [[ $requestCode == *"500" ]]; then
		return 0
	fi
	return 1
}

function checkPackage {
	if verifyConection; then
		printErrorConection
	else
		local hasDependency=0
		for package in $packages; do
			url="https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz"
			local requestCode="$( curl -Is "$url" | head -1 )"
			if [[ $requestCode == *"200"* ]]; then
				if verifyPackageVersion; then
					echo "${green}$package ${reset}is in the latest version"
					hasDependency=0
				else
					installPackage
					hasDependency=1
				fi
			else
				echo "${red}$package ${reset}does not exist in aur repository"
			fi
		done

		if [ $hasDependency -eq "1" ]; then
			removeDependecy
		fi
	fi
}

function installPackage {
	echo "preparing to install the package ${green}$package${reset}"
	cd $directoryTemp
	curl -s -O $url
	tar -xzf "$package.tar.gz"
	cd "$package"
	makepkg -m -c -si --needed --noconfirm
}

function verifyPackageVersion {
	local aurPackageVersion="$( w3m -dump "https://aur.archlinux.org/packages?O=0&SeB=N&K=$package&outdated=&SB=n&SO=a&PP=100&submit=Go" | sed -n "/^$package/p" | cut -d' ' -f2 )"
	local localPackageVersion=$( pacman -Qm | grep $package | cut -d' ' -f2 )
	if [[ "$aurPackageVersion" == "$localPackageVersion" ]]; then
		return 0
	fi
	return 1
}

function updatePackages {
	if verifyConection; then
		printErrorConection
	else
		local allPackages="$directoryTemp/allPackages.txt"
		local outdatedPackages="$directoryTemp/outdatedPackages.txt"
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
	fi
}

function searchPackage {
	if verifyConection; then
		printErrorConection
	else
		echo "listing similar packages..."
		for package in $packages; do
			url="https://aur.archlinux.org/packages/?O=0&SeB=nd&K=$package&outdated=&SB=n&SO=a&PP=100&do_Search=Go"
			w3m -dump $url | sed -n "/^$package/p"
			echo ""
		done
	fi
}

function removePackage {
	for package in $packages; do
		local condition=$( pacman -Q | grep $package )
		if [ -z "$condition" ]; then
			echo "Package $package not exist"
		else
			sudo pacman -R "$package" --noconfirm
		fi
	done
	removeDependecy
}

function listLocalPackages {
	for package in $packages; do
		pacman -Qm | grep $package
	done
}

function removeDependecy {
	sudo pacman -Rns $(pacman -Qtdq) --noconfirm
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
	"--help"|"-h"		) printManual;;
	"--uninstall"|"-U"	) uninstallApp;;
	"--version"|"-V"	) printVersion ;;
	*) printError;;
esac