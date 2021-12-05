#!\bin\bash
#Update Package AUR

cd /tmp/
option="$1"
package="$2"
version="1.0.0-alpha04"

function printError {
	echo "opção inválida, consulte o manual com o comando aurup --help"
	echo ""
}

function printManual {
	echo "uso:  aurup <operação> [...]"
	echo "operações:"
	echo "aurup {-S  --sync   } [package name]"
	echo "aurup {-R  --remove } [package name]"
	echo "aurup {-Ss --search } [package name]"
	echo "aurup {-L  --list   }"
	echo "aurup {-h  --help   }"
	echo "aurup {-V  --version}"
	echo ""
}

function printVersion {
	echo "aurup $version"
	echo "copyright (C) 2020-2021 Vieirateam Developers"
	echo "este é um software livre: você é livre para alterá-lo e redistribuí-lo."
	echo "saiba mais em https://github.com/wellintonvieira/aurup "
	echo ""
}

function searchPackage {
	url="https://aur.archlinux.org/packages/?O=0&SeB=nd&K=$package&outdated=&SB=n&SO=a&PP=100&do_Search=Go"
	echo "listando pacotes semelhantes a pesquisa: $package"
	w3m -dump $url | grep $package | sed "1 d"
}

if [[ "$option" == "--list" || "$option" == "-L" ]];
then
	sudo pacman -Qm
elif [[ "$option" == "--sync" || "$option" == "-S" ]];
then
	url="$(curl -Is "https://aur.archlinux.org/packages/$package/" | head -1)"
	condition=( $url )
	if [[ "$package" == "" ]]; then
		printError
	elif [ ${condition[-2]} == "200" ]; then
		sudo mount -o remount,size=10G /tmp
		wget -q "https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz"
		tar -xzf "$package.tar.gz"
		cd "$package"
		makepkg -m -c -si --needed --noconfirm
		sudo rm -rf "/tmp/$package"
		sudo rm -rf "/tmp/$package.tar.gz"
		sudo pacman -Rns $(pacman -Qtdq) --noconfirm
	else
		echo "pacote não existe no repositório AUR"
	fi	
elif [[ "$option" == "--remove" || "$option" == "-R" ]]; 
then
	if [[ "$package" == "" ]]; then
		printError
	else
		sudo pacman -R "$package"
	fi
elif [[ "$option" == "--help" || "$option" == "-h" ]]; 
then
	printManual
elif [[ "$option" == "--search" || "$option" == "-Ss" ]];
then
	if [[ "$package" == "" ]]; then
		printError
	else
		sudo pacman -Qs w3m > /tmp/aurup.txt
		if [ -s /tmp/aurup.txt ]; then
			searchPackage
		else
			sudo pacman -S w3m --noconfirm
			searchPackage
		fi
		sudo rm /tmp/aurup.txt
	fi
elif [[ "$option" == "--version" || "$option" == "-V" ]]; 
then
	printVersion
else
	printError
fi