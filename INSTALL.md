# Installing md-preview

This page covers **installation from source**. The commands are for Arch
Linux; other distributions have the same tools under the same or similar
package names.

- [1. Requirements](#1-requirements)
- [2. Install from source](#2-install-from-source)
- [3. Fetch KaTeX and mermaid for offline use](#3-fetch-katex-and-mermaid-for-offline-use)
- [4. Check the installation](#4-check-the-installation)
- [5. Try it](#5-try-it)
- [6. Emacs](#6-emacs)
- [Upgrading](#upgrading)
- [Uninstalling](#uninstalling)

## 1. Requirements

| Tool           | Why                                   | Install (Arch)                  |
|----------------|---------------------------------------|---------------------------------|
| `pandoc` ≥ 3.9 | Markdown → HTML, Lua filter           | `sudo pacman -S pandoc-cli`     |
| `entr`         | re-runs pandoc when the file changes  | `sudo pacman -S entr`           |
| `browser-sync` | local server + browser live reload    | `npm install -g browser-sync`   |
| `make`         | installing                            | `sudo pacman -S make`           |
| `curl`, `tar`  | `md-preview fetch` only               | usually already installed       |

**pandoc.** Version 3.9 or newer is needed for GitHub-style alerts in
pandoc Markdown, which md-preview enables by default. With an older 3.x,
set `MD_PREVIEW_FROM=markdown+tex_math_single_backslash+mark+emoji`.

On Arch, `pandoc-cli` is linked against about 250 Haskell shared libraries
and takes about 1.5 s just to start, so each re-render takes several
seconds. The statically linked release starts in well under a second and
makes live preview much snappier:

```sh
# either: the AUR binary package
yay -S pandoc-bin
# or: the upstream static release
curl -LO https://github.com/jgm/pandoc/releases/download/3.10.2/pandoc-3.10.2-linux-amd64.tar.gz
tar -xzf pandoc-3.10.2-linux-amd64.tar.gz -C ~/.local --strip-components=1
```

**browser-sync** needs Node.js. If you manage Node with
[nvm](https://github.com/nvm-sh/nvm):

```sh
nvm use stable
npm install -g browser-sync
```

md-preview finds a browser-sync installed under nvm even when nvm isn't
loaded, for example when a GUI Emacs starts it without your shell's PATH.
It checks `$NVM_DIR`, `~/.config/nvm`, `~/.nvm` and `/usr/share/nvm`, in
that order, then runs `nvm use stable`.

## 2. Install from source

```sh
git clone https://github.com/bvraghav/md-preview.git
cd md-preview
make install
```

That installs into `~/.local` (make sure `~/.local/bin` is on your `PATH`):

| Path                                          | What |
|-----------------------------------------------|------|
| `~/.local/bin/md-preview`                     | the command |
| `~/.local/share/md-preview/`                  | template, Lua filter, stylesheet, script, `VERSION` |
| `~/.local/share/emacs/site-lisp/md-preview.el` | the Emacs package |

Variations:

```sh
sudo make install PREFIX=/usr/local   # system-wide
make link                             # symlink ~/.local/bin/md-preview -> ./bin/md-preview
```

`make link` is for working on md-preview itself: the script finds its
support files by following its own symlink, so it uses the repository's
`share/md-preview/`, and edits take effect on the next save.

## 3. Fetch KaTeX and mermaid for offline use

```sh
md-preview fetch
```

This downloads pinned versions (KaTeX 0.18.9, mermaid 12.0.0) into
`~/.local/share/md-preview/vendor/`, about 7 MB. Without it, pages load
both libraries from the jsDelivr CDN. That also works, but needs a network
connection and is slower.

To use different versions:

```sh
MD_PREVIEW_KATEX_VERSION=0.16.22 MD_PREVIEW_MERMAID_VERSION=11.12.0 md-preview fetch --force
```

The same variables must also be set when running `md-preview` if the vendor
directory is absent and you want those versions from the CDN.

## 4. Check the installation

```sh
md-preview doctor
```

```
md-preview 0.0.3

pandoc         pandoc 3.10.2
entr           /usr/bin/entr
browser-sync   /home/you/.config/nvm/versions/node/v24.19.0/bin/browser-sync (3.0.4)
share          /home/you/.local/share/md-preview
katex          /home/you/.local/share/md-preview/vendor/katex (local, 0.18.9)
mermaid        /home/you/.local/share/md-preview/vendor/mermaid (local, 12.0.0)

all good
```

## 5. Try it

From the repository:

```sh
md-preview test-sample.md      # live, in the browser
make test                      # the regression suites; see tests/README.md
```

[`test-sample.md`](test-sample.md) exercises every supported feature. Each
section has an **Expect:** note saying what should appear.

## 6. Emacs

`make install` puts `md-preview.el` in `~/.local/share/emacs/site-lisp/`.
It adds a minor mode that starts one `md-preview` process per buffer and
stops it when you disable the mode or kill the buffer.

```elisp
(add-to-list 'load-path "~/.local/share/emacs/site-lisp")
(require 'md-preview)

(with-eval-after-load 'markdown-mode
  (define-key markdown-mode-map (kbd "C-c C-c p") #'md-preview-mode))
```

Or with `use-package`:

```elisp
(use-package md-preview
  :load-path "~/.local/share/emacs/site-lisp"
  :commands (md-preview-mode md-preview-start md-preview-stop)
  :bind (:map markdown-mode-map ("C-c C-c p" . md-preview-mode))
  :custom
  (md-preview-args '("--browser" "firefox")))
```

| Command                 | Does                                                  |
|-------------------------|-------------------------------------------------------|
| `md-preview-mode`       | toggle the preview for this buffer                    |
| `md-preview-start/stop` | the same, as separate commands                        |
| `md-preview-browse`     | open the running preview's URL again                  |
| `md-preview-show-log`   | show the process output (pandoc warnings, errors)     |

If `md-preview` itself isn't on Emacs' `exec-path`, set
`md-preview-program` to its absolute path, or use
[`exec-path-from-shell`](https://github.com/purcell/exec-path-from-shell).

## Upgrading

```sh
git pull
make install          # not needed with make link
```

Fetched KaTeX and mermaid are kept; `md-preview fetch --force` refreshes
them.

## Uninstalling

```sh
make uninstall                          # same PREFIX as used for install
rm -rf ~/.local/share/md-preview        # fetched KaTeX / mermaid
npm uninstall -g browser-sync           # if nothing else uses it
```
