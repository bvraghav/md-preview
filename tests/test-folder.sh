#!/usr/bin/env bash
# folder: folder mode (`md-preview build DIR`) on tests/folder-sample —
# the page set, README/index/listing pages, link rewriting, assets by depth,
# the file tree, titles, incremental rebuilds, failures, and options.
# Works on a copy of the sample. Needs pandoc.

source "$(dirname "$0")/lib.sh"
need pandoc

W=$WORK/folder
rm -rf "$W"; mkdir -p "$W"
cp -r "$ROOT/tests/folder-sample" "$W/src"
SRC=$W/src OUT=$W/out
build() { "$MDP" build "$SRC" -o "$OUT" "$@" >"$W/build.log" 2>&1; }
page() { cat "$OUT/$1"; }
body() { sed -n '/<main/,$p' "$OUT/$1" | sed '/<nav class="mdp-tree"/d'; }   # without the tree
tree_of() { grep -o '<nav class="mdp-tree".*</nav>' "$OUT/$1"; }

echo "== build"
check "builds"                                  build
eq "pages" "guide/advanced.html guide/index.html guide/intro.html index.html notes/My Notes.html notes/README.html notes/deep/index.html notes/deep/page.html notes/index.html " \
  "$(cd "$OUT" && find . -name '*.html' | sed 's|^\./||' | LC_ALL=C sort | tr '\n' ' ')"
refute "skips hidden folders"                   test -e "$OUT/.hidden"
refute "skips node_modules"                     test -e "$OUT/node_modules"
check "copies other files (images)"             test -f "$OUT/guide/diagram.svg"
check "copies assets"                           test -f "$OUT/_md-preview/share/style.css" -a -f "$OUT/_md-preview/share/md-preview.js"

echo "== index pages"
check "README.md becomes index.html"            grep -q '<h1 id="folder-sample">Folder sample' "$OUT/index.html"
check "index.md wins over README.md"            grep -q '<h1 id="notes">Notes' "$OUT/notes/index.html"
check "  and that README is a normal page"      grep -q 'Notes README' "$OUT/notes/README.html"
check "folder without either: a listing"        grep -q '<h1 id="guide">guide</h1>' "$OUT/guide/index.html"
check "  listing links its pages"               bash -c "grep -q 'href=\"intro.html\"' <<<\"\$(sed -n '/<h1/,\$p' '$OUT/guide/index.html')\""
check "  nested listing"                        grep -q '<a href="page.html">page</a>' "$OUT/notes/deep/index.html"

echo "== links"
b=$(body index.html)
check "a.md → a.html"                           grep -q 'href="guide/intro.html"' <<<"$b"
check "keeps #fragments"                        grep -q 'href="guide/intro.html#setup"' <<<"$b"
check "folder link → its index"                 grep -q 'href="guide/index.html"' <<<"$b"
check "spaces encoded"                          grep -q 'href="notes/My%20Notes.html"' <<<"$b"
check "external links untouched"                grep -q 'href="https://pandoc.org"' <<<"$b"
b=$(body guide/advanced.html)
check "%20 in a link is understood"             grep -q 'href="../notes/My%20Notes.html"' <<<"$b"
b=$(body guide/intro.html)
check "../README.md → ../index.html"            grep -q 'href="../index.html"' <<<"$b"
b=$(body notes/deep/page.html)
check "two levels up"                           grep -q 'href="../../index.html"' <<<"$b"
check "../ folder link"                         grep -q 'href="../index.html"' <<<"$b"

echo "== assets and tree"
check "assets relative to depth"                grep -q 'href="../../_md-preview/share/style.css"' "$OUT/notes/deep/page.html"
check "root page assets"                        grep -q 'href="_md-preview/share/style.css"' "$OUT/index.html"
t=$(tree_of notes/deep/page.html)
# -exec, not a for loop over $(find): "My Notes.html" has a space
eq "tree on every page"                         0 "$(find "$OUT" -name '*.html' -path '*' ! -path '*/_md-preview/*' -exec grep -L 'class="mdp-tree"' {} + | wc -l)"
check "current page marked"                     grep -q '<a href="page.html" aria-current="page">page</a>' <<<"$t"
eq "exactly one marked"                         1 "$(grep -o 'aria-current="page"' <<<"$t" | wc -l)"
check "folders on its path open"                grep -q '<details open><summary><a href="../index.html">notes/' <<<"$t"
check "other folders closed"                    grep -q '<details><summary><a href="../../guide/index.html">guide/' <<<"$t"
check "root link"                               grep -q 'class="mdp-tree-root" href="../../index.html">src/' <<<"$t"
refute "index pages not listed twice"           grep -q '>index</a>' <<<"$t"
check "listing page marked current"             bash -c "grep -o '<nav class=\"mdp-tree\".*</nav>' '$OUT/guide/index.html' | grep -q 'href=\"index.html\" aria-current=\"page\">guide/'"

echo "== titles"
eq "title from the first heading"               "<title>My Notes</title>" "$(grep -o '<title>[^<]*</title>' "$OUT/notes/My Notes.html")"
eq "listing title"                              "<title>guide</title>" "$(grep -o '<title>[^<]*</title>' "$OUT/guide/index.html")"

echo "== incremental"
build; check "no change: nothing rendered"      grep -q 'updated 0 of 9 pages' "$W/build.log"
sleep 1; touch "$SRC/guide/intro.md"; build
check "one edit: one page"                      grep -q 'updated 1 of 9 pages' "$W/build.log"
echo '# Added' > "$SRC/guide/added.md"; build
check "new file: everything (trees change)"     grep -q 'rendered 10 of 10 pages' "$W/build.log"
check "  new page exists"                       test -f "$OUT/guide/added.html"
check "  and is in other pages' trees"          grep -q 'guide/added.html' "$OUT/index.html"
rm "$SRC/guide/added.md"; build
refute "removed file: its page is removed"      test -e "$OUT/guide/added.html"
check "--force renders everything"              bash -c "'$MDP' build '$SRC' -o '$OUT' --force 2>&1 | grep -q 'rendered 9 of 9'"

echo "== failures"
cp "$SRC/guide/advanced.md" "$W/advanced.md"
printf -- '---\ntitle: [bad\n---\n' > "$SRC/guide/advanced.md"
refute "a broken page fails the build"          build
check "  its page shows the error"              grep -q '<h1>pandoc failed' "$OUT/guide/advanced.html"
check "  error page finds the stylesheet"       grep -q 'href="../_md-preview/share/style.css"' "$OUT/guide/advanced.html"
check "  names the file"                        grep -q 'guide/advanced.md: pandoc failed' "$W/build.log"
refute "  other pages are fine"                 grep -q 'pandoc failed' "$OUT/guide/intro.html"
cp "$W/advanced.md" "$SRC/guide/advanced.md"
check "fixed: builds again"                     build

echo "== options"
refute "--embed rejected for folders"           "$MDP" build --embed "$SRC" -o "$W/x"
refute "--assets rejected for folders"          "$MDP" build --assets x "$SRC" -o "$W/x"
refute "output = source rejected"               "$MDP" build "$SRC" -o "$SRC"
check "default output: DIR/_site"               "$MDP" build "$SRC"
check "  and it's excluded from the sources"    bash -c "'$MDP' build '$SRC' 2>&1 | grep -q 'updated 0 of 9'"
rm -rf "$SRC/_site"
"$MDP" build "$SRC" -o "$W/notree" -- -M md-preview-tree=false >/dev/null 2>&1
refute "md-preview-tree=false hides the tree"   grep -q 'class="mdp-tree"' "$W/notree/index.html"
cat > "$W/user.lua" <<'EOF'
function Link(l) if l.target == 'REPLACE-ME' then l.target = 'guide/intro.md' end return l end
EOF
printf '# U\n\n[x](REPLACE-ME)\n' > "$SRC/u.md"
"$MDP" build "$SRC" -o "$W/userfilter" -- --lua-filter "$W/user.lua" >/dev/null 2>&1
check "user filters run before md-preview's"    grep -q 'href="guide/intro.html">x' "$W/userfilter/u.html"
rm "$SRC/u.md"

echo "== single files are unchanged"
printf '# One\n\n[other](other.md)\n' > "$W/one.md"
"$MDP" build -o "$W/one.html" "$W/one.md" 2>/dev/null
check "no tree"                                 bash -c "! grep -q 'class=\"mdp-tree\"' '$W/one.html'"
check "links to .md left alone"                 grep -q 'href="other.md"' "$W/one.html"

finish
