#!/usr/bin/env bash
# bump.sh X.Y.Z [YYYY-MM-DD] — prepare release X.Y.Z (run as `make bump V=X.Y.Z`).
#
# Rewrites every copy of the version that the release suite checks, and the
# AUR PKGBUILD (pkgver, pkgrel=1, tarball checksum back to SKIP until the tag
# exists); renames the CHANGELOG's [Unreleased] to a section dated today (or
# the given date) and updates its links. Commits nothing: review the diff,
# run `make test`, then follow CONTRIBUTING.md from "Commit and push".

set -euo pipefail
cd "$(dirname "$0")/.."

die() { printf 'bump: %s\n' "$*" >&2; exit 1; }

NEW=${1:-}
DATE=${2:-$(date +%F)}
OLD=$(cat VERSION)
REPO=https://github.com/bvraghav/md-preview

[[ $NEW =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]   || die "usage: make bump V=X.Y.Z [DATE=YYYY-MM-DD]"
[[ $DATE =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || die "date must be YYYY-MM-DD, not '$DATE'"
[[ $(printf '%s\n' "$OLD" "$NEW" | sort -V | tail -1) == "$NEW" && $NEW != "$OLD" ]] ||
  die "$NEW is not newer than the current version $OLD"
grep -qx '## \[Unreleased\]' CHANGELOG.md || die "CHANGELOG.md has no '## [Unreleased]' section"
! grep -q "^## \[$NEW\]" CHANGELOG.md     || die "CHANGELOG.md already has a section for $NEW"

# What [Unreleased] holds, to warn about an empty release.
notes=$(sed -n '/^## \[Unreleased\]$/,/^## \[/{/^## /d;/^[[:space:]]*$/d;p}' CHANGELOG.md)

esc() { printf '%s' "${1//./\\.}"; }
o=$(esc "$OLD")

printf '%s\n' "$NEW" > VERSION
sed -i "s/^;; Version: $o\$/;; Version: $NEW/" emacs/md-preview.el
sed -i "s/^Complete interface for md-preview $o\./Complete interface for md-preview $NEW./" REFERENCE.md
sed -i "s/^md-preview $o\$/md-preview $NEW/" INSTALL.md
sed -i "s/(\`$o\`)/(\`$NEW\`)/" MANIFEST.md
sed -i -e "s/^pkgver=.*/pkgver=$NEW/" -e "s/^pkgrel=.*/pkgrel=1/" \
       -e "s/^sha256sums=('[^']*'/sha256sums=('SKIP'/" packaging/aur/PKGBUILD
MAKEPKG=${MAKEPKG-makepkg}     # MAKEPKG= forces the fallback (tests)
if [[ -n $MAKEPKG ]] && command -v "$MAKEPKG" >/dev/null; then
  (cd packaging/aur && "$MAKEPKG" --printsrcinfo > .SRCINFO)
else
  # The fields bump changes, so .SRCINFO still matches the PKGBUILD.
  sed -i -e "s/^\tpkgver = .*/\tpkgver = $NEW/" -e "s/^\tpkgrel = .*/\tpkgrel = 1/" \
         -e "s|^\tsource = md-preview-$o\.tar\.gz::\(.*\)/v$o\.tar\.gz\$|\tsource = md-preview-$NEW.tar.gz::\1/v$NEW.tar.gz|" \
         -e "0,/^\tsha256sums = .*/s//\tsha256sums = SKIP/" \
         packaging/aur/.SRCINFO
fi

# CHANGELOG: a new empty [Unreleased] above the dated section, and the links.
sed -i -e "s/^## \[Unreleased\]\$/## [Unreleased]\n\n## [$NEW] - $DATE/" \
       -e "s|^\[Unreleased\]: .*|[Unreleased]: $REPO/compare/v$NEW...HEAD\n[$NEW]: $REPO/compare/v$OLD...v$NEW|" \
       CHANGELOG.md

echo "bumped $OLD -> $NEW ($DATE)"
[[ -n $notes ]] || echo "bump: warning: [Unreleased] was empty; add the notes under [$NEW]" >&2
cat <<EOF
Next: review 'git diff', run 'make test', commit, push, wait for green, then
  git tag -a v$NEW -m "md-preview $NEW" && git push upstream v$NEW
and publish the GitHub release: the aur workflow attaches the Arch package
to it (and pushes to the AUR once that is set up; see packaging/aur/README.md).
EOF
