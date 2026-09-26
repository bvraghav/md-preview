#!/usr/bin/env bash
# serve: live preview end to end — startup, served assets, localhost-only
# binding, rebuild on every kind of save, error page, reload events, and
# cleanup on SIGTERM. Needs pandoc, entr, curl and browser-sync.

source "$(dirname "$0")/lib.sh"
need pandoc entr curl python3
"$MDP" doctor 2>/dev/null | grep -q '^browser-sync .*MISSING' && skip "needs browser-sync"

W=$WORK/serve
rm -rf "$W"; mkdir -p "$W/doc/test-assets" "$W/run"
cp "$ROOT/test-sample.md" "$W/doc/doc.md"
cp "$ROOT/test-assets/badge.svg" "$W/doc/test-assets/"
DOC=$W/doc/doc.md

PID='' PORT='' LOG='' RUNS=0
# start [env assignments...]  — start serve in its own session, wait for HTTP.
# Each run logs to its own file, $LOG.
start() {
  PORT=$(free_port)
  RUNS=$((RUNS + 1)); LOG=$W/serve-$RUNS.log
  env "$@" XDG_RUNTIME_DIR="$W/run" setsid "$MDP" serve --no-open --port "$PORT" "$DOC" \
    >"$LOG" 2>&1 &
  PID=$!
  wait_for 30 curl -sf -o /dev/null "http://localhost:$PORT/"
}
stop() { [[ -n $PID ]] && kill -TERM "$PID" 2>/dev/null; wait "$PID" 2>/dev/null; PID=''; }
trap stop EXIT
page() { curl -s "http://localhost:$PORT/"; }
status() { curl -s -o /dev/null -w '%{http_code}' "http://localhost:$PORT/$1"; }
has() { page | grep -qF -- "$1"; }
# save_rename TEXT — append TEXT the way editors with backups save: write a
# new file, move the old one aside, move the new one into place.
save_rename() {
  cp "$DOC" "$W/doc/.tmp" && printf '\n%s\n' "$1" >> "$W/doc/.tmp"
  mv "$DOC" "$DOC~" && mv "$W/doc/.tmp" "$DOC"
}
reloads() { grep -c 'Reloading Browsers' "$LOG"; }
renders() { grep -c '^\[md-preview\] rendered' "$LOG"; }
# gone PATTERN — no process matches within 5 s (exits aren't instant). A plain
# loop, not `bash -c`: that shell's own command line would match PATTERN.
gone() {
  local i
  for i in $(seq 20); do
    pgrep -f "$1" >/dev/null || return 0
    sleep 0.25
  done
  return 1
}

echo "== startup"
if ! start; then
  bad "server starts"; sed 's/^/     /' "$LOG"; finish; exit
fi
ok "server starts on port $PORT"
check "renders the document"     has 'mdp-frontmatter'
eq "stylesheet served"           200 "$(status _md-preview/share/style.css)"
eq "md-preview.js served"        200 "$(status _md-preview/share/md-preview.js)"
eq "image next to the .md"       200 "$(status test-assets/badge.svg)"
if [[ -d $MD_PREVIEW_DATA/vendor ]]; then
  eq "KaTeX served"              200 "$(status _md-preview/vendor/katex/katex.min.js)"
  eq "KaTeX font served"         200 "$(status _md-preview/vendor/katex/fonts/KaTeX_Main-Regular.woff2)"
  eq "mermaid served"            200 "$(status _md-preview/vendor/mermaid/mermaid.min.js)"
fi
if command -v ss >/dev/null; then
  refute "listens on loopback only" bash -c "ss -ltnH 'sport = :$PORT' | awk '{print \$4}' | grep -vqE '^(127\.0\.0\.1|\[::1\]):'"
fi

echo "== rebuild on save"
printf '\nMARK-INPLACE\n' >> "$DOC"
check "in-place edit"                 wait_for 30 has MARK-INPLACE
save_rename MARK-RENAME
check "rename-style save"             wait_for 30 has MARK-RENAME
for n in 1 2 3; do save_rename "MARK-BURST-$n"; sleep 0.3; done
check "burst of saves: last one wins" wait_for 60 has MARK-BURST-3
# A second save while the first is still rendering (pandoc takes seconds)
# must not be lost.
printf '\nMARK-DURING-1\n' >> "$DOC"; sleep 1
printf '\nMARK-DURING-2\n' >> "$DOC"
check "save during a render is not lost" wait_for 60 has MARK-DURING-2
# browser-sync logs the reload shortly after the render lands.
check "a browser reload per render"   wait_for 10 bash -c "(( \$(grep -c 'Reloading Browsers' '$LOG') >= \$(grep -c '^\[md-preview\] rendered' '$LOG') - 1 ))"
note "renders: $(renders), reloads: $(reloads)"

echo "== errors"
cp "$DOC" "$W/good.md"
# Several error -> fix cycles: before entr ran with -a, the fixing save was
# sometimes dropped (about 1 in 8) because it landed while entr was busy.
for n in 1 2 3; do
  printf -- '---\ntitle: [unclosed\n---\n' > "$DOC"
  check "cycle $n: bad YAML shows the error page" wait_for 30 has '<h1>pandoc failed (exit'
  { cat "$W/good.md"; printf '\nMARK-FIXED-%s\n' "$n"; } > "$DOC"
  check "cycle $n: next save recovers"            wait_for 30 has "MARK-FIXED-$n"
done
check "error logged with [pandoc]"    grep -q '^\[pandoc\] ' "$LOG"

echo "== shutdown"
dir=$(ls -d "$W"/run/md-preview.* 2>/dev/null | head -1)
kill -TERM "$PID"; wait "$PID" 2>/dev/null; rc=$?; PID=''
eq "exit status on SIGTERM"           143 "$rc"
refute "temp directory removed"       test -e "$dir"
check "no entr left behind"           gone "entr .*$DOC"
check "no browser-sync left behind"   gone "browser-sync start .*$W/run"
refute "port released"                curl -sf -o /dev/null "http://localhost:$PORT/"

echo "== nvm fallback"
nvm_sh=''
for f in "${NVM_DIR:-/nonexistent}/nvm.sh" "${XDG_CONFIG_HOME:-$HOME/.config}/nvm/nvm.sh" "$HOME/.nvm/nvm.sh"; do
  [[ -r $f ]] && { nvm_sh=$f; break; }
done
if [[ -n $nvm_sh ]] && ! PATH=/usr/bin:/bin command -v browser-sync >/dev/null; then
  check "starts with node/browser-sync off PATH" start PATH=/usr/bin:/bin
  stop
else
  note "nvm fallback not applicable here"
fi

finish
