#!/usr/bin/env bash
# completions: the bash and zsh completion functions offer the right things,
# and the man page builds. bash needs nothing extra; the zsh checks drive a
# real interactive zsh through zsh/zpty (skipped without zsh); the man page
# needs pandoc (and man, to render it).

source "$(dirname "$0")/lib.sh"

W=$WORK/completions
rm -rf "$W"; mkdir -p "$W/dir/sub"
touch "$W/dir/a.md" "$W/dir/b.markdown" "$W/dir/c.txt"

echo "== bash"
# comp WORDS... — COMPREPLY for the last word, sorted, space-separated
comp() {
  (cd "$W/dir" && bash -c '
    source "$1"; shift
    COMP_WORDS=("$@"); COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))
    _md_preview
    (( ${#COMPREPLY[@]} )) && printf "%s\n" "${COMPREPLY[@]}" | sort | tr "\n" " "' _ "$ROOT/completions/md-preview.bash" "$@")
}
eq "first word: commands, .md files, dirs"  "a.md assets b.markdown build docs doctor fetch help serve sub version " "$(comp md-preview '')"
eq "serve: Markdown files and dirs only"    "a.md b.markdown sub " "$(comp md-preview serve '')"
eq "serve options"                          "--no-open " "$(comp md-preview serve --n)"
eq "default command takes serve options"    "--listen " "$(comp md-preview --l)"
eq "build options"                          "--embed " "$(comp md-preview build --e)"
eq "--assets takes a directory"             "sub " "$(comp md-preview build --assets '')"
eq "docs: options only"                     "--browser --no-open --port " "$(comp md-preview docs --)"
eq "docs: no files"                         "" "$(comp md-preview docs '')"
eq "fetch: --force"                         "--force " "$(comp md-preview fetch --)"
eq "assets: directories"                    "sub " "$(comp md-preview assets '')"
eq "browser names"                          "firefox " "$(comp md-preview serve -b f)"
eq "after --: any file (pandoc args)"       "a.md b.markdown c.txt sub " "$(comp md-preview build a.md -- '')"
eq "doctor: nothing"                        "" "$(comp md-preview doctor '')"

echo "== zsh"
if command -v zsh >/dev/null; then
  zc() { (cd "$W/dir" && FPATH_ADD=$ROOT/completions zsh -f "$ROOT/tests/zcomp.zsh" "$1"); }
  out=$(zc 'md-preview ')
  for w in serve build fetch assets docs doctor a.md b.markdown sub/; do
    check "first word offers $w"      grep -qF -- "$w" <<<"$out"
  done
  refute "first word hides c.txt"     grep -qF c.txt <<<"$out"
  out=$(zc 'md-preview build --')
  check "build options"               bash -c 'grep -q -- --embed <<<"$1" && grep -q -- --assets <<<"$1" && grep -q -- --output <<<"$1"' _ "$out"
  out=$(zc 'md-preview docs --')
  check "docs options"                bash -c 'grep -q -- --port <<<"$1" && grep -q -- --no-open <<<"$1"' _ "$out"
  refute "docs: no build options"     grep -q -- --embed <<<"$out"
  out=$(zc 'md-preview -')
  check "default command: serve options" grep -q -- --listen <<<"$out"
else
  note "zsh checks skipped: no zsh"
fi

echo "== man page"
if command -v pandoc >/dev/null; then
  check "make man"                    make -s -C "$ROOT" man
  # groff escapes the hyphen: md\-preview
  check "has the version"             grep -qF "md\\-preview $(cat "$ROOT/VERSION")" "$ROOT/man/md-preview.1"
  if command -v man >/dev/null; then
    page=$(MANWIDTH=80 man -l "$ROOT/man/md-preview.1" 2>&1)
    for sec in NAME SYNOPSIS DESCRIPTION COMMANDS OPTIONS ENVIRONMENT FILES 'EXIT STATUS' EXAMPLES 'SEE ALSO'; do
      check "section $sec"            grep -qx "$sec" <<<"$page"
    done
    refute "no groff warnings"        grep -q 'warning' <<<"$page"
  fi
else
  note "man page checks skipped: no pandoc"
fi

finish
