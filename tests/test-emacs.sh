#!/usr/bin/env bash
# emacs: the Emacs package — byte-compiles without warnings, and in batch
# Emacs md-preview-mode starts a preview, learns its URL, and stops it
# cleanly. Needs emacs; the live part also needs entr and browser-sync.

source "$(dirname "$0")/lib.sh"
need emacs

W=$WORK/emacs
rm -rf "$W"; mkdir -p "$W/run"
EL=$ROOT/emacs/md-preview.el

echo "== byte-compile"
cp "$EL" "$W/"
check "compiles with warnings as errors" \
  emacs -Q --batch --eval "(progn (setq byte-compile-error-on-warn t) (unless (byte-compile-file \"$W/md-preview.el\") (kill-emacs 1)))"
eq "package version matches VERSION" "$(cat "$ROOT/VERSION")" "$(sed -n 's/^;; Version: //p' "$EL")"

echo "== md-preview-mode"
if ! command -v entr >/dev/null || "$MDP" doctor 2>/dev/null | grep -q '^browser-sync .*MISSING'; then
  note "live test skipped: needs entr and browser-sync"
  finish; exit
fi
cp "$ROOT/test-sample.md" "$W/doc.md"
port=$(free_port)
cat > "$W/run.el" <<EOF
;;; -*- lexical-binding: t -*-
(add-to-list 'load-path "$ROOT/emacs")
(require 'md-preview)
(setq md-preview-program "$MDP"
      md-preview-args '("--no-open" "--port" "$port")
      md-preview-environment '("MD_PREVIEW_DATA=$MD_PREVIEW_DATA" "XDG_RUNTIME_DIR=$W/run"))
(find-file "$W/doc.md")
(md-preview-mode 1)
(let ((p md-preview--process) (n 0))
  (while (and (< n 300) (process-live-p p) (not (process-get p 'md-preview-url)))
    (accept-process-output p 0.1) (setq n (1+ n)))
  (princ (format "url=%s\n" (process-get p 'md-preview-url)))
  (princ (format "mode=%s\n" md-preview-mode))
  (md-preview-mode -1)
  (setq n 0)
  (while (and (< n 60) (process-live-p p)) (accept-process-output p 0.1) (setq n (1+ n)))
  (princ (format "live=%s\nexit=%s\n" (process-live-p p) (process-exit-status p))))
EOF
out=$(emacs -Q --batch -l "$W/run.el" 2>/dev/null)
val() { sed -n "s/^$1=//p" <<<"$out"; }
eq "URL reported"            "http://localhost:$port" "$(val url)"
eq "mode enabled"            t "$(val mode)"
eq "process stopped"         nil "$(val live)"
eq "stopped by SIGTERM"      143 "$(val exit)"
check "temp directory removed" bash -c "[ -z \"\$(ls -A '$W/run')\" ]"

finish
