;;; md-preview.el --- Live browser preview of Markdown via md-preview  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 B.V. Raghav

;; Author: B.V. Raghav <bvraghav@gmail.com>
;; Maintainer: B.V. Raghav <bvraghav@gmail.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: tools, text, hypermedia
;; URL: https://github.com/bvraghav/md-preview
;; SPDX-License-Identifier: MIT

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Spawns the `md-preview' command (pandoc + entr + browser-sync) for the
;; current buffer's file and opens a live-reloading preview in the browser.
;; The preview refreshes on every save; it renders YAML frontmatter,
;; mermaid diagrams and KaTeX math.
;;
;;   (require 'md-preview)
;;   (define-key markdown-mode-map (kbd "C-c C-c p") #'md-preview-mode)
;;
;; One md-preview process runs per buffer.  Its output goes to the buffer
;; " *md-preview: FILE*" (see `md-preview-show-log').  Killing the buffer or
;; disabling the mode stops the process and removes its temporary files.
;;
;; This package drives the `md-preview' command, which is installed
;; separately (Arch: the AUR package `md-preview'; elsewhere, from source).
;; See https://bvraghav.github.io/md-preview/install.html

;;; Code:

(require 'ansi-color)

(defgroup md-preview nil
  "Live browser preview of Markdown via md-preview."
  :group 'text
  :prefix "md-preview-")

(defcustom md-preview-program "md-preview"
  "The md-preview executable: a name on the variable `exec-path', or a path."
  :type 'string)

(defcustom md-preview-args nil
  "Extra arguments passed to `md-preview serve', before the file name.
For example (\"--browser\" \"firefox\") or (\"--no-open\")."
  :type '(repeat string))

(defcustom md-preview-environment nil
  "Extra environment variables for the md-preview process, as \"NAME=VALUE\".
Useful when Emacs does not inherit your shell's PATH, e.g.
  (\"MD_PREVIEW_NVM_VERSION=22\") or
  (\"MD_PREVIEW_BROWSER_SYNC=/path/to/bin/browser-sync\")."
  :type '(repeat string))

(defcustom md-preview-save-before-start t
  "When non-nil, save a modified buffer before starting the preview."
  :type 'boolean)

(defvar-local md-preview--process nil
  "The md-preview process serving this buffer, if any.")

(defvar md-preview--folders (make-hash-table :test #'equal)
  "Running folder previews: folder name (with a trailing slash) to process.")

(defconst md-preview--install-url
  "https://bvraghav.github.io/md-preview/install.html"
  "Where to read how to install the md-preview command.")

(defun md-preview--log-buffer-name (file)
  "Return the name of the log buffer for the preview of FILE."
  (format " *md-preview: %s*" (abbreviate-file-name file)))

(defun md-preview--sentinel (proc event)
  "Handle EVENT for md-preview process PROC: turn the mode off when it exits."
  (unless (process-live-p proc)
    (let ((dir (process-get proc 'md-preview-folder)))
      (when (and dir (eq (gethash dir md-preview--folders) proc))
        (remhash dir md-preview--folders)))
    (let ((buf (process-get proc 'md-preview-source)))
      (when (buffer-live-p buf)
        (with-current-buffer buf
          (when (eq md-preview--process proc)
            (setq md-preview--process nil)
            (when (bound-and-true-p md-preview-mode)
              (md-preview-mode -1))))))
    (unless (memq (process-exit-status proc) '(0 2 130 143))
      (message "md-preview: exited (%s); see %s"
               (string-trim event) (buffer-name (process-buffer proc))))))

(defun md-preview--filter (proc string)
  "Append STRING to PROC's buffer and announce the preview URL once."
  (let ((text (ansi-color-filter-apply string)))
    (when (buffer-live-p (process-buffer proc))
      (with-current-buffer (process-buffer proc)
        (goto-char (point-max))
        (insert text)))
    (unless (process-get proc 'md-preview-url)
      (when (string-match "Local: *\\(http://[^ \t\n]+\\)" text)
        (let ((url (match-string 1 text)))
          (process-put proc 'md-preview-url url)
          (message "md-preview: serving at %s" url))))))

(defun md-preview--program ()
  "Return the md-preview executable to run, or signal a helpful error.
MELPA installs only this package, not the command it drives."
  (or (and (file-name-absolute-p md-preview-program)
           (file-executable-p md-preview-program)
           md-preview-program)
      (executable-find md-preview-program)
      (user-error "The `%s' command was not found: install it (see %s), or set `md-preview-program'"
                  md-preview-program md-preview--install-url)))

(defun md-preview--spawn (target)
  "Start `md-preview serve' for TARGET, a file or a folder; return the process.
Its output goes to a log buffer named after TARGET."
  (let* ((program (md-preview--program))
         (process-environment (append md-preview-environment process-environment))
         (log (get-buffer-create (md-preview--log-buffer-name target)))
         (proc (make-process
                :name "md-preview"
                :buffer log
                :command `(,program "serve" ,@md-preview-args ,target)
                :connection-type 'pipe
                :noquery t
                :filter #'md-preview--filter
                :sentinel #'md-preview--sentinel)))
    (with-current-buffer log
      (goto-char (point-max))
      (insert (format "\n--- %s: %s\n" (current-time-string) target)))
    proc))

;;;###autoload
(defun md-preview-start ()
  "Start a live preview of the current buffer's file."
  (interactive)
  (unless buffer-file-name
    (user-error "Buffer is not visiting a file"))
  (if (process-live-p md-preview--process)
      (message "md-preview: already running%s"
               (let ((url (process-get md-preview--process 'md-preview-url)))
                 (if url (concat " at " url) "")))
    (when (and md-preview-save-before-start (buffer-modified-p))
      (save-buffer))
    (let* ((file (expand-file-name buffer-file-name))
           (proc (md-preview--spawn file)))
      (process-put proc 'md-preview-source (current-buffer))
      (setq md-preview--process proc)
      (add-hook 'kill-buffer-hook #'md-preview-stop nil t)
      (message "md-preview: starting for %s" (file-name-nondirectory file)))))

;;;###autoload
(defun md-preview-stop ()
  "Stop the live preview of the current buffer."
  (interactive)
  (let ((proc md-preview--process))
    (setq md-preview--process nil)
    (when (process-live-p proc)
      ;; SIGTERM lets md-preview clean up its children and temp directory.
      ;; (Not SIGINT: a shell that started with SIGINT ignored cannot trap it.)
      (signal-process proc 'SIGTERM)
      (run-at-time 3 nil (lambda ()
                           (when (process-live-p proc)
                             (kill-process proc)))))))

(defun md-preview-show-log ()
  "Show the md-preview process output for the current buffer."
  (interactive)
  (unless buffer-file-name
    (user-error "Buffer is not visiting a file"))
  (let ((buf (get-buffer (md-preview--log-buffer-name
                          (expand-file-name buffer-file-name)))))
    (if buf (display-buffer buf) (message "md-preview: no log yet"))))

(defun md-preview-browse ()
  "Open the running preview's URL in a browser again."
  (interactive)
  (let ((url (and md-preview--process
                  (process-get md-preview--process 'md-preview-url))))
    (if url (browse-url url) (user-error "No md-preview running for this buffer"))))

;;; Folder previews

(declare-function project-current "project")
(declare-function project-root "project")

(defun md-preview--default-folder ()
  "The folder to preview by default: the current project's root, if any."
  (or (and (require 'project nil t)
           (fboundp 'project-root)
           (let ((proj (project-current)))
             (and proj (project-root proj))))
      default-directory))

;;;###autoload
(defun md-preview-folder (dir)
  "Start a live preview of the Markdown files in DIR, with a file tree.
Interactively, ask for DIR, defaulting to the current project's root.  If
DIR is already being previewed, open it in the browser again."
  (interactive (list (read-directory-name "Preview folder: " (md-preview--default-folder) nil t)))
  (let* ((dir (file-name-as-directory (expand-file-name dir)))
         (proc (gethash dir md-preview--folders)))
    (if (process-live-p proc)
        (let ((url (process-get proc 'md-preview-url)))
          (if url (browse-url url) (message "md-preview: %s is starting" dir)))
      (setq proc (md-preview--spawn (directory-file-name dir)))
      (process-put proc 'md-preview-folder dir)
      (puthash dir proc md-preview--folders)
      (message "md-preview: starting for %s" dir))))

(defun md-preview-folder-stop (dir)
  "Stop the live preview of folder DIR.
Interactively, choose among the running folder previews."
  (interactive
   (let ((running (let (l)
                    (maphash (lambda (k p) (when (process-live-p p) (push k l))) md-preview--folders)
                    l)))
     (unless running (user-error "No folder preview is running"))
     (list (if (cdr running)
               (completing-read "Stop folder preview: " running nil t)
             (car running)))))
  (let* ((dir (file-name-as-directory (expand-file-name dir)))
         (proc (gethash dir md-preview--folders)))
    (remhash dir md-preview--folders)
    (when (process-live-p proc)
      (signal-process proc 'SIGTERM)
      (run-at-time 3 nil (lambda ()
                           (when (process-live-p proc)
                             (kill-process proc)))))))

;;;###autoload
(define-minor-mode md-preview-mode
  "Live browser preview of the current Markdown file.
Enabling starts `md-preview serve' for the file; disabling stops it."
  :lighter " MdP"
  (if md-preview-mode
      (condition-case err
          (md-preview-start)
        (error (setq md-preview-mode nil)
               (signal (car err) (cdr err))))
    (md-preview-stop)))

(provide 'md-preview)
;;; md-preview.el ends here
