#!/bin/bash
# Build the Arch package from this git checkout (no GitHub download needed).
# It packs the current commit with "git archive" under the same file name the
# PKGBUILD would download, so makepkg uses it as-is.
#
#   tools/build-local-pkg.sh            build only
#   tools/build-local-pkg.sh --install  build, then "sudo pacman -U" it
set -euo pipefail
cd "$(dirname "$0")/.."
. <(grep -E '^(pkgname|_repo|pkgver|pkgrel)=' PKGBUILD)
if [ -n "$(git status --porcelain -- module PKGBUILD README.md CHANGELOG.md CREDITS.md LICENSE tools)" ]; then
  echo "note: uncommitted changes are NOT included (git archive packs HEAD)" >&2
fi
git archive --format=tar.gz --prefix="${_repo}-${pkgver}/" -o "${_repo}-${pkgver}.tar.gz" HEAD
# --nodeps: nothing is compiled here (DKMS builds on install), so dkms
# itself does not need to be installed just to make the package
makepkg -f --noconfirm --nodeps
pkg="${pkgname}-${pkgver}-${pkgrel}-any.pkg.tar.zst"
ls -l "$pkg"
if [ "${1:-}" = "--install" ]; then
  sudo pacman -U --noconfirm "$pkg"
fi
