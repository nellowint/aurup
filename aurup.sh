#!\bin\bash
#Update Package AUR 1.0.0-alpha02

clear
cd /tmp/
option="$1"
package="$2"
version="1.0.0-alpha02"

echo "##################################################################################################"
echo "#                                                                                                #"
echo "#                               Atualizador de Pacotes da AUR                                    #"
echo "#                                    Versão $version                                        #"
echo "#                                                                                                #"
echo "##################################################################################################"

if [[ "$option" == "--list" || "$option" == "-L" ]];
then
	echo ""
	sudo pacman -Qqm
	echo ""
elif [[ "$option" == "--sync" || "$option" == "-S" ]];
then
	url="$(curl -Is "https://aur.archlinux.org/packages/$package/" | head -1)"
	condition=( $url )
	if [[ "$package" == "" ]]; then
		echo ""
		echo ":: Opção inválida, consulte o manual com aurup --help..."
		echo ""
	elif [ ${condition[-2]} == "200" ]; then
		echo ""
		sudo mount -o remount,size=10G /tmp
		echo ""
		echo ":: Pesquisando o pacote no repositório AUR..."
		sleep 1s
		echo ""
		wget -q "https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz"
		tar -xzf "$package.tar.gz"
		cd "$package"
		makepkg -m -c -si --needed --noconfirm
		sudo rm -rf "/tmp/$package"
		sudo rm -rf "/tmp/$package.tar.gz"
		echo ""
	else
		echo ""
		echo ":: Pacote não existe no repositório AUR..."
		sleep 1s
		echo ""
	fi	
elif [[ "$option" == "--remove" || "$option" == "-R" ]]; 
then
	if [[ "$package" == "" ]]; then
		echo ""
		echo ":: Opção inválida, consulte o manual com aurup --help..."
		echo ""
	else
		echo ""
		echo ":: Removendo pacote do computador..."
		sleep 1s
		echo ""
		sudo pacman -R "$package"
		echo ""
	fi
elif [[ "$option" == "--help" || "$option" == "-h" ]]; 
then
	echo "#                                                                                                #"
	echo "#    Comando          Atalho          Função                                                     #"
	echo "#                                                                                                #"
	echo "#    --sync           -S              instalar um pacote da AUR                                  #"
	echo "#    --remove         -R              remover um pacote instalado da AUR                         #"
	echo "#    --search         -Ss             pesquisa um pacote da AUR                                  #"
	echo "#    --list           -L              listar os pacotes instalados da AUR                        #"
	echo "#    --help           -h              visualizar o manual do aurup                               #"
	echo "#    --version        -V              consultar a versão do aurup                                #"
	echo "#                                                                                                #"
elif [[ "$option" == "--search" || "$option" == "-Ss" ]];
then
	if [[ "$package" == "" ]]; then
		echo ""
		echo ":: Opção inválida, consulte o manual com aurup --help..."
		echo ""
	else
		echo ""
		url="https://aur.archlinux.org/packages/?O=0&SeB=nd&K=$package&outdated=&SB=n&SO=a&PP=100&do_Search=Go"
		w3m -dump $url | grep $package | sed "1 d"
		echo ""
	fi
elif [[ "$option" == "--version" || "$option" == "-V" ]]; 
then
	echo ""
	echo ":: aurup $version"
	echo ":: Copyright (C) 2020 Free Software Foundation, Inc."
	echo ":: Licença GPLv3+: GNU GPL versão 3 ou posterior <https://gnu.org/licenses/gpl.html>"
	echo ":: Este é um software livre: você é livre para alterá-lo e redistribuí-lo."
	echo ":: NÃO HÁ QUALQUER GARANTIA, na máxima extensão permitida em lei."
	echo ":: Escrito por Wellinton Vieira dos Santos."
	echo ":: Saiba mais em https://github.com/wellintonvieira/aurup "
	echo ""
else
	echo ""
	echo ":: Opção inválida, consulte o manual com aurup --help..."
	echo ""
fi
echo "##################################################################################################"
echo ""
read -rsp $':: Pressione qualquer tecla para concluir...' -n1 key
echo ""
echo ""