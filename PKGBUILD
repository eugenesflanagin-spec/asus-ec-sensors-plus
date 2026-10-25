# Maintainer: Eugene Flanagin <eflanagin@pm.me>
#
# Read-only DKMS build of the Linux asus-ec-sensors hwmon driver with support
# for the ASUS TUF GAMING X870-PRO WIFI7 W NEO.
#
# Building before a GitHub release exists (or from your own changes):
#   tools/build-local-pkg.sh      (packs the git checkout, then runs makepkg)

pkgname=asus-ec-sensors-x870tuf-dkms
_repo=asus-ec-sensors-x870tuf
_dkmsname=asus-ec-sensors-x870tuf
pkgver=0.1.0
pkgrel=1
pkgdesc="ASUS EC sensors (CPU, CPU package, motherboard, VRM, CPU_OPT fan) for TUF GAMING X870-PRO WIFI7 W NEO; read-only DKMS build of asus-ec-sensors"
arch=('any')
url="https://github.com/eugenesflanagin-spec/${_repo}"
license=('GPL-2.0-only')
depends=('dkms')
optdepends=('lm_sensors: the "sensors" command to read the values'
            'linux-headers: build the module for the stock Arch kernel')
conflicts=('asus-ec-sensors-dkms-git')
source=("${_repo}-${pkgver}.tar.gz::${url}/archive/refs/tags/v${pkgver}.tar.gz")
# Fill in after the v0.1.0 GitHub release exists (updpkgsums).
sha256sums=('SKIP')

prepare() {
  cd "${_repo}-${pkgver}/module"
  # the three version numbers must agree, or DKMS keeps an old build
  # (the "same-version rebuild trap")
  [ "$(cat VERSION)" = "${pkgver}" ] || { echo "module/VERSION is not ${pkgver}"; return 1; }
  grep -qx "PACKAGE_VERSION=\"${pkgver}\"" dkms.conf || { echo "dkms.conf version is not ${pkgver}"; return 1; }
}

package() {
  cd "${_repo}-${pkgver}"
  local dest="${pkgdir}/usr/src/${_dkmsname}-${pkgver}"
  install -Dm644 -t "${dest}" module/asus-ec-sensors.c module/Kbuild module/Makefile module/VERSION module/dkms.conf
  install -Dm644 -t "${pkgdir}/usr/share/doc/${pkgname}" README.md CHANGELOG.md CREDITS.md
  install -Dm755 tools/ec-sample.sh "${pkgdir}/usr/share/doc/${pkgname}/ec-sample.sh"
  install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
