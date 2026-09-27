#!/usr/bin/env bash
# release: every place the version appears agrees with VERSION, and the
# CHANGELOG is ready for it. With TAG set (e.g. TAG=v0.1.0, as CI does on a
# tag push), the tag must match too. Needs nothing beyond coreutils.

source "$(dirname "$0")/lib.sh"
cd "$ROOT"

V=$(cat VERSION)
REPO=https://github.com/bvraghav/md-preview

echo "== VERSION $V"
check "VERSION is X.Y.Z"                     grep -qxE '[0-9]+\.[0-9]+\.[0-9]+' VERSION
eq "md-preview version"                      "md-preview $V" "$("$MDP" version)"
eq "md-preview.el ;; Version: header"        "$V" "$(sed -n 's/^;; Version: //p' emacs/md-preview.el)"
check "REFERENCE.md names this version"      grep -q "^Complete interface for md-preview $V\." REFERENCE.md
check "INSTALL.md doctor example"            grep -qx "md-preview $V" INSTALL.md
check "MANIFEST.md VERSION row"              grep -q "(\`$V\`)" MANIFEST.md

echo "== CHANGELOG"
check "has an [Unreleased] section"          grep -qx '## \[Unreleased\]' CHANGELOG.md
check "has a dated section for $V"           grep -qxE "## \[${V//./\\.}\] - [0-9]{4}-[0-9]{2}-[0-9]{2}" CHANGELOG.md
check "[$V] link is defined"                 grep -q "^\[$V\]: $REPO/" CHANGELOG.md
check "[Unreleased] compares from v$V"       grep -qx "\[Unreleased\]: $REPO/compare/v$V\.\.\.HEAD" CHANGELOG.md
eq "sections are newest first"               "$V" "$(sed -n 's/^## \[\([0-9][0-9.]*\)\].*/\1/p' CHANGELOG.md | head -1)"

if [[ -z ${RELEASE_NESTED:-} ]]; then
echo "== make bump"
# On a copy of the working tree: bumping to the next PATCH must leave a tree
# that passes these same checks, whether or not makepkg writes .SRCINFO.
B=$WORK/release
N=${V%.*}.$(( ${V##*.} + 1 ))
copy() {
  rm -rf "$B/$1"; mkdir -p "$B/$1"
  git ls-files -z | xargs -0 cp --parents -t "$B/$1" 2>/dev/null
  cp --parents tools/bump.sh -t "$B/$1"
}
copy a
if [[ -f $B/a/packaging/aur/.SRCINFO ]]; then
  # As after a release: the tarball checksum is real, not SKIP.
  h=$(printf x | sha256sum | cut -c1-64)
  sed -i "s/^sha256sums=('[^']*'/sha256sums=('$h'/" "$B/a/packaging/aur/PKGBUILD"
  sed -i "0,/^\tsha256sums = .*/s//\tsha256sums = $h/" "$B/a/packaging/aur/.SRCINFO"
fi
rm -rf "$B/b"; cp -r "$B/a" "$B/b"
check "bump to $N"                           bash -c "cd '$B/a' && MAKEPKG= make -s bump V=$N DATE=2000-01-01 >/dev/null 2>&1"
check "  the bumped tree passes"             bash -c "cd '$B/a' && RELEASE_NESTED=1 TAG= WORK='$B/work' bash tests/test-release.sh 2>&1 | grep -q ' 0 failed'"
eq "  [Unreleased] is empty again"           "## [$N] - 2000-01-01" "$(sed -n '/^## \[Unreleased\]$/{n;n;p;q}' "$B/a/CHANGELOG.md")"
eq "  pkgver"                                "pkgver=$N pkgrel=1" "$(grep -E '^pkg(ver|rel)=' "$B/a/packaging/aur/PKGBUILD" | paste -sd' ')"
check "  tarball checksum is SKIP again"     grep -q "^sha256sums=('SKIP'" "$B/a/packaging/aur/PKGBUILD"
if command -v makepkg >/dev/null; then
  check "  .SRCINFO matches the PKGBUILD"    diff <(cd "$B/a/packaging/aur" && makepkg --printsrcinfo) "$B/a/packaging/aur/.SRCINFO"
else
  note ".SRCINFO comparison needs makepkg"
fi
refute "refuses the current version"         bash -c "cd '$B/b' && make -s bump V=$V >/dev/null 2>&1"
refute "refuses a malformed version"         bash -c "cd '$B/b' && make -s bump V=${N%.*} >/dev/null 2>&1"
refute "refuses without V"                   bash -c "cd '$B/b' && make -s bump >/dev/null 2>&1"
check "  and changes nothing"                bash -c "cd '$B/b' && diff -q VERSION '$ROOT/VERSION' >/dev/null"
fi

if [[ -n ${TAG:-} ]]; then
  echo "== tag $TAG"
  eq "tag is v\$VERSION"                     "v$V" "$TAG"
  if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    # GitHub's release form makes lightweight tags; fine, but worth saying.
    [[ $(git cat-file -t "$TAG") == tag ]] || note "$TAG is a lightweight tag (git tag -a is preferred)"
    eq "tag points at HEAD"                  "$(git rev-parse HEAD)" "$(git rev-parse "$TAG^{commit}")"
  else
    note "tag $TAG not in this clone; skipping tag object checks"
  fi
fi

finish
