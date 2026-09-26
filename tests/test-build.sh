#!/usr/bin/env bash
# build: rendering, output modes, option precedence, CLI, assets, install
# and the View Source round trip. Needs pandoc and python3; no network.

source "$(dirname "$0")/lib.sh"
need pandoc python3

W=$WORK/build
rm -rf "$W"; mkdir -p "$W"
cd "$ROOT"

# render SRC OUT [build options / -- pandoc args]  (stderr -> OUT.err)
render() { local src=$1 out=$2; shift 2; "$MDP" build -o "$out" "$src" "$@" 2>"$out.err"; }

echo "== test-sample.md"
S=$W/sample.html
check "renders"                         render test-sample.md "$S"
refute "no pandoc warnings"             grep -q '^\[WARNING\]' "$S.err"
eq "mermaid blocks"          10 "$(count '<pre class="mermaid"' "$S")"
eq "display math spans"      13 "$(count 'class="math display"' "$S")"
ge "inline math spans"       30 "$(count 'class="math inline"' "$S")"
check "frontmatter table"               grep -q '<details class="mdp-frontmatter"' "$S"
check "title block"                     grep -q 'id="title-block-header"' "$S"
check "GitHub alerts"                   grep -q 'class="note"' "$S"
check "table of contents"               grep -q '<nav id="TOC" class="mdp-toc"' "$S"
check "md-preview.js loaded"            grep -q 'md-preview.js"' "$S"
check "KaTeX mhchem + copy-tex loaded"  grep -q 'contrib/mhchem.min.js' "$S"
check "mermaid.js loaded"               grep -q 'mermaid' "$S"
check "\\newcommand expanded"           grep -q 'x \\in \\mathbb{R}^n' "$S"
check "text code block left alone"      grep -q 'graph TD; this is not a diagram' "$S"
eq "frontmatter key count"   "frontmatter · 13 keys" "$(grep -o 'frontmatter · [0-9]* keys' "$S")"

echo "== output modes"
out=$W/plain.html; render test-sample.md "$out"
check "plain: absolute stylesheet path"  grep -q "href=\"$ROOT/share/md-preview/style.css\"" "$out"
check "plain: absolute script path"      grep -q "src=\"$ROOT/share/md-preview/md-preview.js\"" "$out"
out=$W/assets.html; render test-sample.md "$out" --assets _x
check "--assets: relative stylesheet"    grep -q 'href="_x/share/style.css"' "$out"
check "--assets: relative script"        grep -q 'src="_x/share/md-preview.js"' "$out"
if [[ -r $MD_PREVIEW_DATA/vendor/katex/katex.min.js ]]; then
  check "--assets: relative KaTeX"       grep -q 'src="_x/vendor/katex/katex.min.js"' "$out"
else
  check "--assets: KaTeX from CDN (not fetched)" grep -q 'cdn.jsdelivr.net/npm/katex' "$out"
fi
out=$W/embed.html
if render test-sample.md "$out" --embed; then
  ok "--embed renders"
  refute "--embed: no local file references"  grep -qE '(src|href)="/' "$out"
  check "--embed: script inlined"             grep -q 'mdp-copy-wrap' "$out"
  check "--embed: image inlined"              grep -q 'data:image/svg+xml' "$out"
else
  note "--embed needs fetched assets or network: $(tail -1 "$out.err")"
  bad "--embed renders"
fi
check "-o - writes to stdout"  bash -c "'$MDP' build -o - test-sample.md 2>/dev/null | head -1 | grep -q '<!DOCTYPE html>'"
refute "--embed with --assets is rejected"  "$MDP" build --embed --assets x -o "$W/x.html" test-sample.md

echo "== frontmatter setting"
printf -- '---\nmd-preview-frontmatter: open\nx: 1\n---\nhi\n' > "$W/fm.md"
fm() { MD_PREVIEW_FRONTMATTER=$1 "$MDP" build -o - "$W/fm.md" 2>/dev/null | grep -o '<details class="mdp-frontmatter"[^>]*>' || echo none; }
eq "document key (open) when env unset"  '<details class="mdp-frontmatter" open>' "$(fm '')"
eq "env hide overrides document"         none "$(fm hide)"
eq "env closed overrides document"       '<details class="mdp-frontmatter">' "$(fm closed)"

echo "== table of contents setting"
printf '# a\n\n## b\n' > "$W/toc2.md"
printf '# a\n\n## b\n\n## c\n' > "$W/toc3.md"
printf -- '---\nmd-preview-toc: false\n---\n# a\n\n## b\n\n## c\n' > "$W/tocoff.md"
toc() { MD_PREVIEW_TOC=${2:-} "$MDP" build -o - "$1" 2>/dev/null | grep -c '<nav id="TOC" class="mdp-toc"'; }
eq "2 headings: no TOC"                  0 "$(toc "$W/toc2.md")"
eq "3 headings: TOC"                     1 "$(toc "$W/toc3.md")"
eq "md-preview-toc: false hides it"      0 "$(toc "$W/tocoff.md")"
eq "MD_PREVIEW_TOC=true forces it"       1 "$(toc "$W/toc2.md" true)"
eq "MD_PREVIEW_TOC=true beats document"  1 "$(toc "$W/tocoff.md" true)"

echo "== dialects and titles"
out=$W/gfm.html
check "MD_PREVIEW_FROM=gfm renders"  env MD_PREVIEW_FROM=gfm "$MDP" build -o "$out" test-sample.md
check "gfm: frontmatter and math"    grep -q 'mdp-frontmatter' "$out"
printf 'no title here\n' > "$W/untitled.md"
render "$W/untitled.md" "$W/untitled.html"
eq "untitled: file name as <title>"  '<title>untitled.md</title>' "$(grep -o '<title>[^<]*</title>' "$W/untitled.html")"
refute "untitled: no title warning"  grep -q WARNING "$W/untitled.html.err"
printf -- '---\ntitle: [unclosed\n---\n' > "$W/bad.md"
refute "bad YAML: build fails"       "$MDP" build -o "$W/bad.html" "$W/bad.md"

echo "== command line"
eq "version matches VERSION"   "md-preview $(cat VERSION)" "$("$MDP" version)"
check "help exits 0"           "$MDP" help
refute "unknown option fails"  "$MDP" build --bogus test-sample.md
refute "missing file fails"    "$MDP" build "$W/does-not-exist.md"
refute "no input fails"        "$MDP" build

echo "== assets"
"$MDP" assets "$W/pub" 2>/dev/null
check "assets: style.css"      test -f "$W/pub/share/style.css"
check "assets: md-preview.js"  test -f "$W/pub/share/md-preview.js"
if [[ -d $MD_PREVIEW_DATA/vendor ]]; then
  check "assets: KaTeX copied, not linked"    test -f "$W/pub/vendor/katex/katex.min.js" -a ! -L "$W/pub/vendor"
  check "assets: mermaid copied"              test -f "$W/pub/vendor/mermaid/mermaid.min.js"
fi

echo "== install"
P=$W/prefix
check "make install"                 make -s install PREFIX="$P"
eq "installed version"               "md-preview $(cat VERSION)" "$("$P/bin/md-preview" version)"
check "installed share files"        test -f "$P/share/md-preview/md-preview.js" -a -f "$P/share/md-preview/filter.lua"
check "installed Emacs package"      test -f "$P/share/emacs/site-lisp/md-preview.el"
check "installed build works"        "$P/bin/md-preview" build -o "$W/inst.html" test-sample.md
check "make uninstall"               make -s uninstall PREFIX="$P"
refute "uninstall removed the script" test -e "$P/bin/md-preview"

echo "== packaged KaTeX/mermaid"
if [[ -d $MD_PREVIEW_DATA/vendor ]]; then
  pk=$W/pkgshare; rm -rf "$pk"; cp -r share/md-preview "$pk"; cp -rL "$MD_PREVIEW_DATA/vendor" "$pk/vendor"
  empty=$W/emptydata; mkdir -p "$empty"
  out=$(MD_PREVIEW_DATA=$empty MD_PREVIEW_SHARE=$pk "$MDP" build -o - test-sample.md 2>/dev/null)
  check "used when nothing is fetched"       grep -q "src=\"$pk/vendor/katex/katex.min.js\"" <<<"$out"
  out=$(MD_PREVIEW_SHARE=$pk "$MDP" build -o - test-sample.md 2>/dev/null)
  check "a fetched copy wins"                grep -q "src=\"$MD_PREVIEW_DATA/vendor/katex/katex.min.js\"" <<<"$out"
  check "doctor says packaged"               bash -c "MD_PREVIEW_DATA='$empty' MD_PREVIEW_SHARE='$pk' '$MDP' doctor | grep -q '^katex .*(packaged, '"
  MD_PREVIEW_DATA=$empty MD_PREVIEW_SHARE=$pk "$MDP" fetch >/dev/null 2>&1 || true
  check "fetch writes to the data dir, not the packaged one" test -r "$empty/vendor/katex/katex.min.js"
fi

echo "== staged install (DESTDIR)"
D=$W/destdir
check "make install DESTDIR"          make -s install DESTDIR="$D" PREFIX=/usr
check "  script in /usr/bin"          test -x "$D/usr/bin/md-preview"
check "  support files"               test -f "$D/usr/share/md-preview/md-preview.js"
check "  Emacs package"               test -f "$D/usr/share/emacs/site-lisp/md-preview.el"
check "  man page"                    test -f "$D/usr/share/man/man1/md-preview.1"
check "  bash completion"             test -f "$D/usr/share/bash-completion/completions/md-preview"
check "  zsh completion"              test -f "$D/usr/share/zsh/site-functions/_md-preview"
if [[ -d $MD_PREVIEW_DATA/vendor ]]; then
  check "make install-vendor"         make -s install-vendor DESTDIR="$D" PREFIX=/usr VENDOR_SRC="$MD_PREVIEW_DATA/vendor"
  check "  KaTeX and mermaid copied"  test -f "$D/usr/share/md-preview/vendor/katex/katex.min.js" -a -f "$D/usr/share/md-preview/vendor/mermaid/mermaid.min.js"
fi
refute "install-vendor without a source fails" make -s install-vendor DESTDIR="$D" PREFIX=/usr VENDOR_SRC="$W/none"
check "make uninstall DESTDIR"        make -s uninstall DESTDIR="$D" PREFIX=/usr
refute "  nothing left in /usr/bin"   test -e "$D/usr/bin/md-preview"
check "  nothing left at all"        bash -c "[ -z \"\$(find '$D' -type f)\" ]"

echo "== docs without documentation"
P=$W/prefix-nodocs; make -s install PREFIX="$P" >/dev/null
refute "docs fails when none is installed"   env MD_PREVIEW_DOCS= "$P/bin/md-preview" docs --no-open
check "  and says how to get it"             bash -c "'$P/bin/md-preview' docs --no-open 2>&1 | grep -q 'make install-docs'"
refute "unknown docs option fails"           "$MDP" docs --bogus

echo "== View Source round trip"
sh site/source-page.sh test-sample.md > "$W/src.md"
fence=$(grep -o '`\{1,\}' test-sample.md | awk '{ if (length > m) m = length } END { print m + 1 }')
check "outer fence is longest run + 1 ($fence)"  grep -qx "$(printf "%${fence}s" '' | tr ' ' '`') {.markdown .numberLines}" "$W/src.md"
render "$W/src.md" "$W/src.html" -- --preserve-tabs
check "source page reproduces the file"          python3 site/roundtrip.py "$W/src.html" test-sample.md
render "$W/src.md" "$W/src-tabs.html"
refute "check catches lost tabs (no --preserve-tabs)"  python3 site/roundtrip.py "$W/src-tabs.html" test-sample.md

finish
