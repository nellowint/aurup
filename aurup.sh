#!\bin\bash
#Update Package AUR 1.0
clear
cd /tmp/
option="$1"
package="$2"

echo "##################################################################################################"
echo "#                                                                                                #"
echo "#                               Atualizador de Pacotes da AUR                                    #"
echo "#                                        Versão 1.0                                              #"
echo "#                                                                                                #"
echo "##################################################################################################"

if [[ "$option" == "--list" || "$option" == "-l" ]];
then
	echo ""
	sudo pacman -Qm
	echo ""
elif [[ "$option" == "--install" || "$option" == "-i" ]];
then	
	echo ""
	echo ":: Iniciando script de atualização..."
	sleep 1s
	echo ""
	echo ":: Baixando pacote do repositório AUR..."
	sleep 1s
	echo ""
	wget "https://aur.archlinux.org/cgit/aur.git/snapshot/$package.tar.gz"
	echo ":: Descompactando arquivo baixado..."
	sleep 1s
	tar -xzf "$package.tar.gz"
	cd "$package"
	echo ""
	echo ":: Iniciando instalação do pacote..."
	sleep 1s
	echo ""
	makepkg -si
	echo ""
	echo ":: Pacote AUR atualizado com sucesso!"
	sleep 1s
	echo ""
	echo ":: Finalizando script de atualização..."
	sleep 1s
	sudo rm -rf "/tmp/$package"
	sudo rm -rf "/tmp/$package.tar.gz"
	echo ""
elif [[ "$option" == "--remove" || "$option" == "-r" ]]; 
then
	echo ""
	echo ":: Removendo pacote do computador..."
	sleep 1s
	echo ""
	sudo pacman -R "$package"
	echo ""
elif [[ "$option" == "--help" || "$option" == "-h" ]]; 
then
	echo "#                                                                                                #"
	echo "#    Comando          Atalho          Função                                                     #"
	echo "#                                                                                                #"
	echo "#    --install        -i              instalar um pacote da AUR                                  #"
	echo "#    --remove         -r              remover um pacote da AUR                                   #"
	echo "#    --list           -l              listar os pacotes instalados da AUR                        #"
	echo "#    --help           -h              visualizar o manual do aurup                               #"
	echo "#                                                                                                #"
else
	echo ""
	echo ":: Opção inválida, consulte o manual com aurup help"
	echo ""
fi
echo "##################################################################################################"
echo ""
read -rsp $':: Pressione qualquer tecla para concluir...' -n1 key
echo ""
clear