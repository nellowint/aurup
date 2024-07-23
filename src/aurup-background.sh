#!\bin\bash
#this script running in background with cronie

name="aurup"
directory="$HOME/.$name"
allPackages="$directory/allPackages.txt"
outdatedPackages="$directory/outdatedPackages.txt"

echo -n > $allPackages
echo -n > $outdatedPackages
pacman -Qm > $allPackages

function verifyPackageVersion {
	local aurPackageVersion="$( w3m -dump "https://aur.archlinux.org/packages?O=0&SeB=N&K=$package&outdated=&SB=n&SO=a&PP=100&submit=Go" | sed -n "/^$package/p" | cut -d' ' -f2 )"
	local localPackageVersion=$( pacman -Qm | grep $package | cut -d' ' -f2 )
	if [[ "$aurPackageVersion" != "$localPackageVersion" ]]; then
		echo "$package" >> $outdatedPackages
	fi
}

while read -r line; do
	package="$( echo "$line" | cut -d' ' -f1 )"
	verifyPackageVersion
done < $allPackages

if [ -s "$outdatedPackages" ]; then
	notify-send -t 3000 -i "/usr/share/icons/Adwaita/symbolic/status/software-update-available-symbolic.svg" "Aurup" "There are packages to be updated!"
fi