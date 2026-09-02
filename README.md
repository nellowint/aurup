# aurup

[![AUR](https://img.shields.io/aur/version/aurup)](https://aur.archlinux.org/packages/aurup)
[![AUR votes](https://img.shields.io/aur/votes/aurup)](https://aur.archlinux.org/packages/aurup)
[![License: GPL v3](https://img.shields.io/badge/license-GPL%20v3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Arch%20Linux%20%26%20derivatives-lightgrey.svg)]()

## Search and Install packages from AUR

Aurup is a command-line tool (CLI) designed to simplify searching and installing packages from the AUR (Arch User Repository) on Arch Linux-based systems.

## Installation

### From AUR
```bash
yay -S aurup
```
### From Git
```
git clone https://github.com/nellowint/aurup.git
cd aurup
makepkg -si
```

## Features

aurup {-S --sync package1 package2 package3 ... }
Install software from AUR

aurup {-S --sync package.tar.gz }
Install a package from a local AUR snapshot (tar.gz with PKGBUILD) found in the current directory; falls back to the AUR API if the file is not present

aurup {-R --remove package1 package2 package3 ... }
Remove a software

aurup {-Ss --search package1 package2 package3 ... }
Search for software in the AUR

aurup {-Sy --update }
Installed software update list

aurup {-L --list}
Check the list of installed software

aurup {-c --clear}
Clear cache

aurup {-L --list package1 package2 package3 ...}
Check that the packages are installed

aurup {-h --help }
See Aurup's help

aurup {-V --version}
Check the Aurup version

## Contributing
✨ Contributions are welcome! Please:

1) Fork the repository
2) Create a feature branch (git checkout -b feature/your-feature)
3) Commit your changes (git commit -am 'Add some feature')
4) Push to the branch (git push origin feature/your-feature)
5) Open a Pull Request

## Dependencies

* [bash-completion](https://archlinux.org/packages/?name=bash-completion)
* [curl](https://archlinux.org/packages/?name=curl)
* [diffutils](https://archlinux.org/packages/?name=diffutils)
* [git](https://archlinux.org/packages/?name=git)
* [jq](https://archlinux.org/packages/?name=jq)
* [tar](https://archlinux.org/packages/?name=tar)

## License
This project is licensed under the GNU GENERAL PUBLIC LICENSE - see the LICENSE file for details.
