#!/usr/bin/env bash
# aur: build the AUR package (packaging/aur/PKGBUILD) from a tarball of HEAD,
# check its contents, then run md-preview from the unpacked package with
# nothing fetched: it must use the packaged KaTeX/mermaid and find the
# packaged docs. Also checks .SRCINFO matches the PKGBUILD. Needs makepkg
# (Arch); not run on CI. KaTeX and mermaid are downloaded once.

source "$(dirname "$0")/lib.sh"
need makepkg bsdtar git pandoc python3

W=$WORK/aur
PKGBUILD=$ROOT/packaging/aur/PKGBUILD
pkgver=$(sed -n 's/^pkgver=//p' "$PKGBUILD")
rm -rf "$W"; mkdir -p "$W/build" "$W/root" "$W/emptydata"

echo "== .SRCINFO"
check ".SRCINFO matches the PKGBUILD" \
  diff <(cd "$ROOT/packaging/aur" && makepkg --printsrcinfo) "$ROOT/packaging/aur/.SRCINFO"

echo "== build"
cp "$PKGBUILD" "$W/build/"
# Our tarball of HEAD isn't byte-identical to GitHub's, so skip only its
# checksum; KaTeX's and mermaid's are still verified.
sed -i "s/^sha256sums=('[^']*'/sha256sums=('SKIP'/" "$W/build/PKGBUILD"
# The tag doesn't exist yet at release time; makepkg uses a local file with
# the source's name instead of downloading it.
git -C "$ROOT" archive --prefix="md-preview-$pkgver/" HEAD | gzip -n > "$W/build/md-preview-$pkgver.tar.gz"
if (cd "$W/build" && makepkg -f --noconfirm) >"$W/makepkg.log" 2>&1; then
  ok "makepkg (build, check, package)"
else
  bad "makepkg"; tail -20 "$W/makepkg.log" | sed 's/^/     /'; finish; exit
fi
check "check() ran the round trip"      grep -q 'roundtrip: test-sample.md reproduced exactly' "$W/makepkg.log"
refute "no network fetch during build"  grep -q 'fetching' "$W/makepkg.log"
pkg=$(ls "$W"/build/md-preview-"$pkgver"-*-any.pkg.tar.* | head -1)

echo "== contents"
bsdtar -tf "$pkg" > "$W/contents"
for f in usr/bin/md-preview usr/share/md-preview/template.html usr/share/md-preview/md-preview.js \
         usr/share/md-preview/vendor/katex/katex.min.js usr/share/md-preview/vendor/mermaid/mermaid.min.js \
         usr/share/emacs/site-lisp/md-preview.el usr/share/man/man1/md-preview.1.gz \
         usr/share/bash-completion/completions/md-preview usr/share/zsh/site-functions/_md-preview \
         usr/share/doc/md-preview/html/index.html usr/share/licenses/md-preview/LICENSE; do
  check "has /$f"                       grep -qx "$f" "$W/contents"
done
refute "nothing outside /usr"           grep -vE '^(\.|usr/)' "$W/contents"

echo "== installed layout"
bsdtar -xf "$pkg" -C "$W/root"
M=$W/root/usr/bin/md-preview
run() { env MD_PREVIEW_DATA="$W/emptydata" "$@"; }
eq "version"                            "md-preview $(cat "$ROOT/VERSION")" "$(run "$M" version)"
check "doctor: KaTeX is packaged"       bash -c "MD_PREVIEW_DATA='$W/emptydata' '$M' doctor | grep -q '^katex .*/usr/share/md-preview/vendor/katex (packaged, '"
out=$(run "$M" build -o - "$ROOT/test-sample.md" 2>/dev/null)
check "build uses packaged KaTeX"       grep -q "src=\"$W/root/usr/share/md-preview/vendor/katex/katex.min.js\"" <<<"$out"
check "build uses packaged mermaid"     grep -q "src=\"$W/root/usr/share/md-preview/vendor/mermaid/mermaid.min.js\"" <<<"$out"
refute "no CDN"                         grep -q 'cdn.jsdelivr' <<<"$out"
check "docs site links the release tag" grep -q "/commit/v$(cat "$ROOT/VERSION")\"" "$W/root/usr/share/doc/md-preview/html/index.html"
port=$(free_port)
MD_PREVIEW_DATA=$W/emptydata MD_PREVIEW_DOCS_SERVER=python setsid "$M" docs --no-open --port "$port" >"$W/docs.log" 2>&1 &
dpid=$!
check "docs serves the packaged site"   wait_for 15 curl -sf -o /dev/null "http://localhost:$port/reference.html"
check "  from /usr/share/doc"           grep -q "$W/root/usr/share/doc/md-preview/html" "$W/docs.log"
kill -TERM "$dpid" 2>/dev/null; wait "$dpid" 2>/dev/null
check "man page renders"                bash -c "MANWIDTH=80 man -l '$W/root/usr/share/man/man1/md-preview.1.gz' | grep -qx SYNOPSIS"

finish
