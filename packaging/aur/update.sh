#!/usr/bin/env bash
# update.sh X.Y.Z [DIR] — update the PKGBUILD and .SRCINFO in DIR (default:
# this folder) for the released tag vX.Y.Z: pkgver, pkgrel=1, the KaTeX and
# mermaid versions that tag pins, and every checksum. Downloads the sources;
# the tag must already be on GitHub. Needs makepkg, curl, bsdtar or tar.
# Run by .github/workflows/aur.yml; also works by hand (packaging/aur/README.md).

set -euo pipefail

die() { printf 'update.sh: %s\n' "$*" >&2; exit 1; }

V=${1:-}
[[ $V =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "usage: update.sh X.Y.Z [DIR]"
cd "${2:-$(dirname "$0")}"
[[ -f PKGBUILD ]] || die "no PKGBUILD in $(pwd)"

url=$(sed -n "s/^url='\(.*\)'$/\1/p" PKGBUILD)
[[ -n $url ]] || die "no url= in the PKGBUILD"

# Downloads go here, so the checksums are of exactly what was fetched.
export SRCDEST
SRCDEST=$(mktemp -d)
trap 'rm -rf "$SRCDEST"' EXIT

tarball=$SRCDEST/md-preview-$V.tar.gz
curl -fsSL -o "$tarball" "$url/archive/refs/tags/v$V.tar.gz" || die "can't download the v$V tarball; is the tag on GitHub?"

# The versions the tagged md-preview fetches, so the package ships the same.
script=$(tar -xzOf "$tarball" "md-preview-$V/bin/md-preview")
pin() { sed -n "s/^$1=\${MD_PREVIEW_$1:-\(.*\)}\$/\1/p" <<<"$script"; }
katex=$(pin KATEX_VERSION); mermaid=$(pin MERMAID_VERSION)
[[ -n $katex && -n $mermaid ]] || die "can't find the KaTeX/mermaid versions in v$V's bin/md-preview"

sed -i -e "s/^pkgver=.*/pkgver=$V/" -e "s/^pkgrel=.*/pkgrel=1/" \
       -e "s/^_katex=.*/_katex=$katex/" -e "s/^_mermaid=.*/_mermaid=$mermaid/" PKGBUILD

# What updpkgsums does: replace the sha256sums=(...) array with makepkg -g's.
sums=$(makepkg -g 2>/dev/null) || die "makepkg -g failed"
[[ $sums == sha256sums=* ]] || die "unexpected output from makepkg -g: $sums"
awk -v sums="$sums" '
  /^sha256sums=\(/ { skip = 1; print sums }
  skip { if (/\)[[:space:]]*$/) skip = 0; next }
  { print }
' PKGBUILD > PKGBUILD.new
mv PKGBUILD.new PKGBUILD

makepkg --printsrcinfo > .SRCINFO
echo "PKGBUILD updated for $V (KaTeX $katex, mermaid $mermaid)"
