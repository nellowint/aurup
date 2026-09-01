# Maintainer: Wellinton Vieira <wellintonvieira.office@gmail.com>

pkgname="aurup"
pkgver="1.79"
pkgrel=2
pkgdesc="The simplify finding and installing packages AUR helper"
arch=("any")
url="https://github.com/nellowint/$pkgname"
license=("GPL-3.0-or-later")
depends=("bash-completion" "curl" "diff" "jq" "tar")
makedepends=("git")
source=("git+https://github.com/nellowint/$pkgname.git#tag=v$pkgver")
md5sums=("SKIP")

package() {
	cd "$pkgname"
	install -Dm755 "$pkgname.sh" "$pkgdir/usr/bin/$pkgname"
	install -Dm644 "$pkgname-complete.sh" "$pkgdir/usr/share/bash-completion/completions/$pkgname"
	install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}