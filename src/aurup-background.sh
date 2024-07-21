#!\bin\bash
#this script running in background with cronie

name="aurup"
directory="$HOME/.$name"
directoryTemp="$directory/tmp"
allPackages="$directoryTemp/allPackages.txt"
outdatedPackages="$directoryTemp/outdatedPackages.txt"

echo -n > $allPackages
echo -n > $outdatedPackages
pacman -Qm > $allPackages

function verifyPackageVersion {
	local aurPackageVersion="$( w3m -dump "https://aur.archlinux.org/packages?O=0&SeB=N&K=$package&outdated=&SB=n&SO=a&PP=100&submit=Go" | sed -n "/^$package/p" | cut -d' ' -f2 )"
	local localPackageVersion=$( pacman -Qm | grep $package | cut -d' ' -f2 )
	if [[ "$aurPackageVersion" != "$localPackageVersion" ]]; then
		echo "$package" >> $outdatedPackages
		notify-send -i software-update-available-symbolic "Aurup" "$package needs update" 
	fi
}

while read -r line; do
	package="$( echo "$line" | cut -d' ' -f1 )"
	verifyPackageVersion
done < $allPackages