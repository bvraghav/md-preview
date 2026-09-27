# md-preview for Emacs

`md-preview.el` adds `md-preview-mode`: turn it on in a Markdown buffer and
a live preview opens in your browser, refreshing on every save. Turn it off,
or kill the buffer, and the preview stops.

`M-x md-preview-folder` previews a **whole folder** instead: every Markdown
file in it, with a file tree on each page and links between the files
working (see [folder mode](../REFERENCE.md#folder-mode)). It defaults to
the current project's root; `M-x md-preview-folder-stop` stops it.

The package drives the **`md-preview` command**, which is installed
separately; see [INSTALL.md](../INSTALL.md). Check it with
`md-preview doctor` in a terminal first.

## Install the package

### From MELPA

```elisp
(use-package md-preview
  :ensure t
  :commands (md-preview-mode md-preview-start md-preview-stop
             md-preview-folder md-preview-folder-stop)
  :bind (:map markdown-mode-map ("C-c C-c p" . md-preview-mode)
         ("C-c C-c P" . md-preview-folder)))
```

or `M-x package-install RET md-preview RET`. MELPA installs only the Elisp;
you still need the `md-preview` command.

### With the Arch package or `make install`

The package is already installed, in `/usr/share/emacs/site-lisp` (Arch package) or
`~/.local/share/emacs/site-lisp` (`make install`). The first is on Emacs'
`load-path` by default; for the second:

```elisp
(add-to-list 'load-path "~/.local/share/emacs/site-lisp")
```

Then configure it as below, without `:ensure t`.

### With straight.el or Elpaca

```elisp
(use-package md-preview
  :straight (:host github :repo "bvraghav/md-preview" :files ("emacs/md-preview.el")))

(use-package md-preview
  :ensure (:host github :repo "bvraghav/md-preview" :files ("emacs/md-preview.el")))
```

## Configure

```elisp
(use-package md-preview
  :commands (md-preview-mode md-preview-start md-preview-stop)
  :bind (:map markdown-mode-map ("C-c C-c p" . md-preview-mode))
  :custom
  (md-preview-args '("--browser" "firefox")))
```

Without `use-package`:

```elisp
(require 'md-preview)
(with-eval-after-load 'markdown-mode
  (define-key markdown-mode-map (kbd "C-c C-c p") #'md-preview-mode)
  (define-key markdown-mode-map (kbd "C-c C-c P") #'md-preview-folder))
```

## Commands and options

| Command                 | Does                                                  |
|-------------------------|-------------------------------------------------------|
| `md-preview-mode`       | toggle the preview for this buffer                    |
| `md-preview-start/stop` | the same, as separate commands                        |
| `md-preview-browse`     | open the running preview's URL again                  |
| `md-preview-show-log`   | show the process output (pandoc warnings, errors)     |
| `md-preview-folder`     | preview a folder (default: the project root); again for the same folder, reopen it in the browser |
| `md-preview-folder-stop`| stop a folder preview, chosen among the running ones  |

A folder preview's output is in the buffer ` *md-preview: DIR*`; killing
that buffer also stops it. `md-preview-args` and the other options apply to
folder previews too.

| Option                         | Default          | Meaning |
|--------------------------------|------------------|---------|
| `md-preview-program`           | `"md-preview"`   | the command: a name on `exec-path`, or an absolute path |
| `md-preview-args`              | `nil`            | extra `serve` options, e.g. `("--browser" "firefox")` or `("--no-open")` |
| `md-preview-environment`       | `nil`            | extra `"NAME=VALUE"` environment entries for the process |
| `md-preview-save-before-start` | `t`              | save a modified buffer before starting |

## When Emacs can't find things

A GUI Emacs often doesn't inherit your shell's `PATH`.

- **"The `md-preview' command was not found".** Set `md-preview-program`
  to its absolute path, e.g. `"~/.local/bin/md-preview"` expanded, or use
  [`exec-path-from-shell`](https://github.com/purcell/exec-path-from-shell).
- **browser-sync not found**, although it works in a terminal. md-preview
  already looks for a browser-sync installed under nvm, even when nvm isn't
  loaded. If yours is elsewhere, point to it:
  ```elisp
  (setq md-preview-environment
        '("MD_PREVIEW_BROWSER_SYNC=/path/to/bin/browser-sync"))
  ```
  or choose the node version nvm should use with
  `"MD_PREVIEW_NVM_VERSION=22"`.
- **Anything else:** `M-x md-preview-show-log` shows md-preview's output,
  including pandoc's warnings and errors.

## Testing an unreleased version

To try the package from a checkout before it's released (or before MELPA
has it):

```elisp
;; one-off: install the file as a package (M-x package-install-file)
(package-install-file "~/scratchpad/md-preview/emacs/md-preview.el")

;; or load it straight from the checkout
(use-package md-preview
  :load-path "~/scratchpad/md-preview/emacs")

;; or, on Emacs 29+, from GitHub
(package-vc-install '(md-preview :url "https://github.com/bvraghav/md-preview"
                                 :lisp-dir "emacs"))
```

Use the matching command from the same checkout (`make link` in the
repository), so the package and the command are the same version.
`make -C tests emacs` runs the package's tests, including a live preview
started and stopped from batch Emacs.
