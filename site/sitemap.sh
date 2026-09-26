#!/bin/sh
# sitemap.sh BASE-URL ROOT PAGES-YAML FOLDER-TREE — print sitemap.xml
#
# One <url> per page: the site's pages from pages.yaml (page -> source), and
# the folder demo's from its folder build's tree file (source -> page, under
# folder-demo/). <lastmod> is the date of the last commit touching the page's
# source, or the file's own date outside a git checkout (release tarballs).

set -eu

base=${1%/}/
root=$2
pages=$3
tree=$4

lastmod() {
  d=''
  if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    d=$(git -C "$root" log -1 --format=%cs -- "$1" 2>/dev/null || true)
  fi
  [ -n "$d" ] || d=$(date -r "$root/$1" +%Y-%m-%d)
  printf '%s' "$d"
}

# URL-encode the few characters that occur in our paths, XML-escape &.
url() { printf '%s' "$1" | sed -e 's/%/%25/g' -e 's/ /%20/g' -e 's/&/\&amp;/g'; }

entry() {
  printf '  <url><loc>%s%s</loc><lastmod>%s</lastmod></url>\n' "$base" "$(url "$1")" "$(lastmod "$2")"
}

printf '<?xml version="1.0" encoding="UTF-8"?>\n'
printf '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'

awk '/^ *- page:/ { page = $3 } /^ *source:/ { print page "\t" $2 }' "$pages" |
  while IFS='	' read -r page source; do
    if [ "$page" = index ]; then entry '' "$source"; else entry "$page.html" "$source"; fi
  done

# P <tab> source <tab> page, for every Markdown file of the folder demo
# (listing pages have no source of their own; they're reachable from the tree).
grep '^P	' "$tree" | while IFS='	' read -r _ source page; do
  entry "folder-demo/$page" "tests/folder-sample/$source"
done

printf '</urlset>\n'
