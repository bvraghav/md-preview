#!/bin/sh
# source-page.sh FILE [INTRO] — print a Markdown page showing FILE verbatim.
#
# FILE goes into a fenced code block whose fence is one backtick longer than
# the longest run of backticks in FILE (and at least three), so nothing in
# FILE can close it early. INTRO, if given, is Markdown placed above it.
# Render the result with pandoc's --preserve-tabs to keep tabs intact.

set -eu

file=$1
intro=${2:-}

n=$(grep -o '`\{1,\}' "$file" | awk '{ if (length > m) m = length } END { print (m < 3 ? 3 : m + 1) }')
fence=$(printf "%${n}s" '' | tr ' ' '`')

printf '# Source of `%s`\n\n' "$(basename "$file")"
if [ -n "$intro" ]; then printf '%s\n\n' "$intro"; fi
printf '%s {.markdown .numberLines}\n' "$fence"
cat "$file"
# The closing fence must start on its own line.
if [ -n "$(tail -c 1 "$file")" ]; then echo; fi
printf '%s\n' "$fence"
