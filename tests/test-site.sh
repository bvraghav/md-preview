#!/usr/bin/env bash
# site: the project website built by site/Makefile — page set, link
# rewriting, frontmatter and TOC placement, footer, View Source round trip,
# and every page and asset over HTTP. Needs pandoc, make, curl, python3;
# fetches KaTeX and mermaid on first run.

source "$(dirname "$0")/lib.sh"
need pandoc make curl python3

cd "$ROOT"
OUT=site/_site

echo "== build"
if make -s -C site >"$WORK/site-build.log" 2>&1; then ok "make -C site"; else
  bad "make -C site"; sed 's/^/     /' "$WORK/site-build.log"; finish; exit
fi
refute "no pandoc warnings"  grep -q '^\[WARNING\]' "$WORK/site-build.log"

pages="index install demo demo-source changelog license manifest reference todo contributing"
for p in $pages; do check "page $p.html" test -s "$OUT/$p.html"; done
eq "no unexpected pages"  "$(echo $pages | tr ' ' '\n' | sort | tr '\n' ' ')" \
  "$(cd "$OUT" && ls *.html | sed 's/\.html$//' | sort | tr '\n' ' ')"

echo "== links"
refute "no links to repo .md files remain" \
  grep -lE 'href="(README|CHANGELOG|MANIFEST|REFERENCE|TODO|INSTALL|CONTRIBUTING|test-sample)\.md' "$OUT"/*.html
check "README → install.html"              grep -q 'href="install.html"' "$OUT/index.html"
refute "no links to LICENSE remain"        grep -l 'href="LICENSE"' "$OUT"/*.html
check "README → reference.html"            grep -q 'href="reference.html"' "$OUT/index.html"
check "README → demo.html (via test-sample.md)" grep -q 'href="demo.html"' "$OUT/index.html"
check "other files → GitHub at the commit" grep -qE 'href="https://github.com/[^"]*/blob/[0-9a-f]{40}/site/Makefile"' "$OUT/index.html"
check "source page links back to demo"     grep -q 'href="demo.html">← Back' "$OUT/demo-source.html"
check "demo links to its source"           grep -q 'href="demo-source.html"' "$OUT/demo.html"

echo "== per-page features"
for p in $pages; do
  n=$(count '<details class="mdp-frontmatter"' "$OUT/$p.html")
  if [[ $p == demo ]]; then eq "frontmatter box on $p" 1 "$n"; else eq "no frontmatter box on $p" 0 "$n"; fi
done
for p in index demo-source license; do eq "no TOC on $p" 0 "$(count '<nav id="TOC" class="mdp-toc"' "$OUT/$p.html")"; done
for p in demo reference changelog manifest todo install contributing; do eq "TOC on $p" 1 "$(count '<nav id="TOC" class="mdp-toc"' "$OUT/$p.html")"; done
check "nav on every page"     bash -c "for f in $OUT/*.html; do grep -q 'class=\"site-nav\"' \$f || exit 1; done"
check "footer with version"   grep -q "Rendered by md-preview $(cat VERSION)" "$OUT/index.html"
check "live-preview bar hidden by site.css" grep -q '\.mdp-bar { display: none; }' "$OUT/_md-preview/site.css"

echo "== install-docs"
D=$WORK/site-destdir; rm -rf "$D"
check "make install-docs DESTDIR"        make -s install-docs DESTDIR="$D" PREFIX=/usr
check "  site installed for docs"        test -f "$D/usr/share/doc/md-preview/html/index.html" -a -f "$D/usr/share/doc/md-preview/html/demo.html"
check "  with its assets"                test -f "$D/usr/share/doc/md-preview/html/_md-preview/share/md-preview.js"

echo "== View Source round trip"
check "demo-source.html reproduces test-sample.md" python3 site/roundtrip.py "$OUT/demo-source.html" test-sample.md

echo "== over HTTP"
port=$(free_port)
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$OUT" >/dev/null 2>&1 &
srv=$!
trap 'kill $srv 2>/dev/null' EXIT
wait_for 10 curl -sf -o /dev/null "http://127.0.0.1:$port/"
for u in "" $(for p in $pages; do echo "$p.html"; done) test-assets/badge.svg \
         _md-preview/share/style.css _md-preview/share/md-preview.js _md-preview/site.css \
         _md-preview/vendor/katex/katex.min.js _md-preview/vendor/katex/fonts/KaTeX_Main-Regular.woff2 \
         _md-preview/vendor/katex/contrib/mhchem.min.js _md-preview/vendor/mermaid/mermaid.min.js; do
  eq "GET /$u" 200 "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/$u")"
done

finish
