;;; md-preview.el --- Live browser preview of Markdown via md-preview  -*- lexical-binding: t; -*-

;; Version: 0.0.3
;; Package-Requires: ((emacs "27.1"))
;; Keywords: markdown, tools, preview
;; URL: https://github.com/bvraghav/md-preview

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

;;; Code:

(require 'ansi-color)

(defgroup md-preview nil
  "Live browser preview of Markdown via md-preview."
  :group 'text
  :prefix "md-preview-")

(defcustom md-preview-program "md-preview"
  "The md-preview executable: a name on `exec-path' or an absolute path."
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

(defun md-preview--log-buffer-name (file)
  (format " *md-preview: %s*" (abbreviate-file-name file)))

(defun md-preview--sentinel (proc event)
  (unless (process-live-p proc)
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
      (let ((url (match-string 1 string)))
          (process-put proc 'md-preview-url url)
          (message "md-preview: serving at %s" url))))))

;;;###autoload
(defun md-preview-start ()
  "Start a live preview of the current buffer's file."
  (interactive)
  (unless buffer-file-name
    (user-error "md-preview: buffer is not visiting a file"))
  (if (process-live-p md-preview--process)
      (message "md-preview: already running%s"
               (let ((url (process-get md-preview--process 'md-preview-url)))
                 (if url (concat " at " url) "")))
    (when (and md-preview-save-before-start (buffer-modified-p))
      (save-buffer))
    (let* ((file (expand-file-name buffer-file-name))
           (process-environment (append md-preview-environment process-environment))
           (log (get-buffer-create (md-preview--log-buffer-name file)))
           (proc (make-process
                  :name "md-preview"
                  :buffer log
                  :command `(,md-preview-program "serve" ,@md-preview-args ,file)
                  :connection-type 'pipe
                  :noquery t
                  :filter #'md-preview--filter
                  :sentinel #'md-preview--sentinel)))
      (with-current-buffer log
        (goto-char (point-max))
        (insert (format "\n--- %s: %s\n" (current-time-string) file)))
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
    (user-error "md-preview: buffer is not visiting a file"))
  (let ((buf (get-buffer (md-preview--log-buffer-name
                          (expand-file-name buffer-file-name)))))
    (if buf (display-buffer buf) (message "md-preview: no log yet"))))

(defun md-preview-browse ()
  "Open the running preview's URL in a browser again."
  (interactive)
  (let ((url (and md-preview--process
                  (process-get md-preview--process 'md-preview-url))))
    (if url (browse-url url) (user-error "md-preview: no preview running"))))

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
