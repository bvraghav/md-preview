#!/usr/bin/env bash
# browser: the built site in headless Chromium — KaTeX, mermaid, images,
# heading anchors, copy buttons, TOC layout/highlight/toggle, the navbar
# dropdown, and line numbers on the source page. Each check runs a probe
# script from probes/ injected into a copy of the page, which reports
# key=value lines. Needs chromium (or Chrome), python3, and a built site
# (run the site suite first, or `make -C site`).

source "$(dirname "$0")/lib.sh"
need python3 curl

CHROME=${CHROME:-}
if [[ -z $CHROME ]]; then
  for c in chromium chromium-browser google-chrome google-chrome-stable; do
    command -v "$c" >/dev/null && { CHROME=$c; break; }
  done
fi
[[ -n $CHROME ]] || skip "needs chromium or google-chrome (or set CHROME)"
[[ -f $ROOT/site/_site/demo.html ]] || skip "site not built (run: make -C site)"

WWW=$WORK/www
rm -rf "$WWW"; cp -r "$ROOT/site/_site" "$WWW"; mkdir -p "$WWW/__probe"
cp "$(dirname "$0")"/probes/*.js "$WWW/__probe/"

port=$(free_port)
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$WWW" >/dev/null 2>&1 &
srv=$!
trap 'kill $srv 2>/dev/null' EXIT
wait_for 10 curl -sf -o /dev/null "http://127.0.0.1:$port/" || skip "http server did not start"

# probe PAGE PROBE WIDTH — load PAGE with probes/PROBE.js at WIDTH px; the
# results go to $R (key=value lines). The page keeps its own file name, so
# anything that depends on the URL (like the nav's current page) still works.
R=$WORK/probe.out
probe() {
  local page=$1 name=$2 width=$3
  cp "$WWW/$page" "$WWW/$page.orig"
  sed -i "s|</body>|<script src=\"__probe/$name.js\"></script></body>|" "$WWW/$page"
  timeout 90 "$CHROME" --headless=new --disable-gpu --no-sandbox --hide-scrollbars \
    --window-size="$width,900" --virtual-time-budget=25000 \
    --dump-dom "http://127.0.0.1:$port/$page" 2>/dev/null |
    sed -n '/<pre id="probe">/,/<\/pre>/p' | sed 's/<[^>]*>//g; s/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g' > "$R"
  mv "$WWW/$page.orig" "$WWW/$page"
  [[ -s $R ]] || bad "probe $name on $page returned nothing (chrome failed?)"
}
val() { sed -n "s/^$1=//p" "$R"; }

echo "== demo.html (1500px)"
probe demo.html render 1500
eq "KaTeX errors (only the deliberate one)"  1 "$(val katex_errors)"
ge "KaTeX rendered"                          45 "$(val katex)"
eq "no unrendered math"                      0 "$(val unrendered_math)"
eq "mermaid diagrams"                        10 "$(val mermaid_svgs)"
eq "mermaid ids unique"                      10 "$(val mermaid_unique_ids)"
eq "no collapsed diagrams"                   0 "$(val mermaid_zero_height)"
eq "image loads"                             true "$(val image_loaded)"
eq "an anchor per heading"                   "$(val headings)" "$(val anchors)"
eq "a copy button per code block"            "$(val code_blocks)" "$(val copy_buttons)"
eq "TOC is a fixed sidebar"                  fixed "$(val toc_position)"
eq "TOC sidebar open by default"             true "$(val toc_open)"

echo "== demo.html (800px)"
probe demo.html render 800
eq "TOC is inline"                           static "$(val toc_position)"
eq "TOC inline closed by default"            false "$(val toc_open)"

echo "== TOC behaviour"
for w in 1500 800; do
  probe demo.html toc $w
  eq "${w}px: highlights the current section"  "3.5 Entity relationship" "$(val active)"
  eq "${w}px: exactly one highlighted"         1 "$(val active_count)"
  eq "${w}px: toggle remembered"               true "$(val saved_matches)"
done

echo "== navbar dropdown"
probe todo.html dropdown 1000
eq "More marked current on a page inside it" true "$(val more_current)"
eq "page marked aria-current"                TODO "$(val aria_current)"
eq "opens on click"                          true "$(val opens)"
eq "closes on outside click"                 true "$(val outside_click_closes)"
eq "closes on Escape"                        true "$(val escape_closes)"
eq "Escape returns focus to More"            true "$(val escape_refocuses)"
eq "closes when focus leaves"                true "$(val focus_leaving_closes)"
eq "stays open when focus moves within"      true "$(val focus_within_stays)"
eq "menu within viewport (1000px)"           true "$(val menu_in_viewport)"
probe todo.html dropdown 500
eq "menu within viewport (500px)"            true "$(val menu_in_viewport)"
eq "menu flips on narrow screens"            true "$(val flipped)"

echo "== demo-source.html"
probe demo-source.html source 1000
eq "line numbers generated"                  "counter(source-line)" "$(val line_number_content)"
eq "line numbers not underlined"             false "$(val line_number_underlined)"
eq "line numbers not clipped"                true "$(val line_number_visible)"
eq "one copy button"                         1 "$(val copy_buttons)"
eq "every source line shown"                 "$(wc -l < "$ROOT/test-sample.md")" "$(val lines)"

finish
