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

echo "== MELPA readiness"
cd_el() { (cd "$ROOT/emacs" && "$@"); }
out=$(cd_el emacs -Q --batch --eval '(progn (require (quote checkdoc)) (setq checkdoc-diagnostic-buffer "*warn*") (checkdoc-file "md-preview.el") (with-current-buffer (get-buffer-create "*warn*") (princ (buffer-string))))' 2>&1)
eq "checkdoc: no warnings"   0 "$(grep -c '^md-preview.el:[0-9]' <<<"$out")"
[[ $(grep -c '^md-preview.el:[0-9]' <<<"$out") == 0 ]] || grep '^md-preview.el:[0-9]' <<<"$out" | sed 's/^/     /'
ELPA=$WORK/elpa
emacs -Q --batch --eval "(progn (setq package-user-dir \"$ELPA\" package-archives '((\"melpa\" . \"https://melpa.org/packages/\"))) (package-initialize) (unless (package-installed-p 'package-lint) (package-refresh-contents) (package-install 'package-lint)))" >/dev/null 2>&1
if ls -d "$ELPA"/package-lint-* >/dev/null 2>&1; then
  out=$(cd_el emacs -Q --batch --eval "(progn (setq package-user-dir \"$ELPA\") (package-initialize) (require 'package-lint) (setq package-lint-main-file \"md-preview.el\") (package-lint-batch-and-exit))" md-preview.el 2>&1)
  rc=$?
  eq "package-lint: clean"   0 "$rc"
  (( rc == 0 )) || sed 's/^/     /' <<<"$out"
else
  note "package-lint not available (offline?); skipped"
fi
for h in Author Maintainer Version Package-Requires Keywords URL SPDX-License-Identifier; do
  check "header: $h"         grep -q "^;; $h: " "$EL"
done

echo "== behaviour without the command"
out=$(emacs -Q --batch -L "$ROOT/emacs" --eval "(progn (require 'md-preview) (setq md-preview-program \"md-preview-does-not-exist\") (find-file \"$ROOT/test-sample.md\") (condition-case err (md-preview-start) (user-error (princ (cadr err)))))" 2>/dev/null)
check "missing command: says so"          grep -q "command was not found" <<<"$out"
check "  and where to read about installing" grep -q "install.html" <<<"$out"
out=$(emacs -Q --batch -L "$ROOT/emacs" --eval "(progn (require 'md-preview) (setq md-preview-program \"md-preview-does-not-exist\") (find-file \"$ROOT/test-sample.md\") (condition-case nil (md-preview-mode 1) (user-error nil)) (princ (format \"mode=%s\" md-preview-mode)))" 2>/dev/null)
eq "  and the mode stays off"            "mode=nil" "$out"

echo "== output parsing"
# browser-sync may colour its output; the URL must still come out clean.
out=$(emacs -Q --batch -L "$ROOT/emacs" --eval "(progn (require 'md-preview) (let ((p (start-process \"t\" nil \"sleep\" \"5\"))) (md-preview--filter p (concat \"[Browsersync] Access URLs:\\n \\e[1mLocal:\\e[22m \\e[35mhttp://localhost:3005\\e[39m\\n\")) (princ (process-get p 'md-preview-url)) (delete-process p)))" 2>/dev/null)
eq "URL from coloured output"  "http://localhost:3005" "$out"

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

echo "== md-preview-folder"
cp -r "$ROOT/tests/folder-sample" "$W/folder"
port=$(free_port)
cat > "$W/folder.el" <<EOF
;;; -*- lexical-binding: t -*-
(add-to-list 'load-path "$ROOT/emacs")
(require 'md-preview)
(setq md-preview-program "$MDP"
      md-preview-args '("--no-open" "--port" "$port")
      md-preview-environment '("MD_PREVIEW_DATA=$MD_PREVIEW_DATA" "XDG_RUNTIME_DIR=$W/run"))
(md-preview-folder "$W/folder")
(let* ((dir (file-name-as-directory "$W/folder"))
       (p (gethash dir md-preview--folders)) (n 0))
  (while (and (< n 300) (process-live-p p) (not (process-get p 'md-preview-url)))
    (accept-process-output p 0.1) (setq n (1+ n)))
  (princ (format "url=%s\n" (process-get p 'md-preview-url)))
  (princ (format "page=%s\n" (with-temp-buffer
                                (call-process "curl" nil t nil "-s" (format "http://localhost:$port/"))
                                (if (search-backward "mdp-tree" nil t) "tree" "none"))))
  (md-preview-folder-stop dir)
  (setq n 0)
  (while (and (< n 60) (process-live-p p)) (accept-process-output p 0.1) (setq n (1+ n)))
  (princ (format "live=%s\nexit=%s\nregistered=%s\n" (process-live-p p) (process-exit-status p)
                 (hash-table-count md-preview--folders))))
EOF
out=$(emacs -Q --batch -l "$W/folder.el" 2>/dev/null)
eq "URL reported"            "http://localhost:$port" "$(val url)"
eq "serves the folder, with its tree" tree "$(val page)"
eq "stopped"                 nil "$(val live)"
eq "stopped by SIGTERM"      143 "$(val exit)"
eq "no longer registered"    0 "$(val registered)"
check "temp directory removed" bash -c "[ -z \"\$(ls -A '$W/run')\" ]"

finish
