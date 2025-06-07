# Maintainer: Wellinton Vieira <wellintonvieira.office@gmail.com>

pkgname=aurup
pkgver=1.0.0
pkgrel=1
pkgdesc="The simplify finding and installing packages AUR helper"
arch=('x86_64')
url="https://github.com/nellowint/$pkgname"
licence=('GNU')
conflicts=($pkgname)
depends=('bash-completion' 'curl' 'jq' 'tar')
makedepends=('git')
source=("git+${url}.git")
md5sums=('SKIP')	

package() {
	install -Dm755 "${pkgname}" "${pkgdir}/usr/bin/${pkgname}"
	install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}