# aurup
## AUR Packages Installer (Unreleased)

Aurup is a program to facilitate the installation of Arch User Repository (AUR) software. Developed in the Shell Script language.

To install aurup on your computer, just run the command **chmod +x install.sh** and after running the command **sh install.sh**, if necessary run the command with sudo privileges. 

## Configure Cron exec crontab -e
### The task will run every five minutes every day
```
*/5 * * * * sh $HOME/.aurup/aurup-background.sh && date >> $HOME/.aurup/aurup.log
```
##

### Main features

aurup {-S --sync package1 package2 package3 ... }
Install software from AUR

aurup {-R --remove package1 package2 package3 ... }
Remove a software

aurup {-Ss --search package1 package2 package3 ... }
Search for software in the AUR

aurup {-Sy --update }
Installed software update list

aurup {-L --list}
Check the list of installed software

aurup {-L --list package1 package2 package3 ...}
Check that the packages are installed

aurup {-c --clear }
Clear cache and unused dependencies

aurup {-h --help }
See Aurup's help

aurup {-U --uninstall }
Uninstall Aurup to computer

aurup {-V --version}
Check the Aurup version

##

### Dependencies to be installed

* [adwaita-icon-theme](https://archlinux.org/packages/extra/any/adwaita-icon-theme/)
* [bash-completion](https://archlinux.org/packages/extra/any/bash-completion/)
* [curl](https://archlinux.org/packages/?name=curl)
* [cronie](https://archlinux.org/packages/extra/x86_64/cronie/)
* [libnotify](https://archlinux.org/packages/extra/x86_64/libnotify/)
* [tar](https://archlinux.org/packages/?name=tar)
* [w3m](https://archlinux.org/packages/extra/x86_64/w3m/)