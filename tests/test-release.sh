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
