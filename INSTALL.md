# Installing md-preview

**On Arch Linux**, install the AUR package:

```sh
yay -S md-preview              # or any AUR helper; or makepkg from the AUR repo
npm install -g browser-sync    # for live reload (optional, but recommended)
```

It includes KaTeX and mermaid (no `md-preview fetch` needed), the
documentation (`md-preview docs`), the man page, shell completion and the
Emacs package. For Emacs setup, see [emacs/INSTALL.md](emacs/INSTALL.md).

The rest of this page covers **installation from source**. The commands are
for Arch Linux; other distributions have the same tools under the same or
similar package names.

## Requirements

| Tool           | Why                                   | Install (Arch)                  |
|----------------|---------------------------------------|---------------------------------|
| `pandoc` ≥ 3.9 | Markdown → HTML, Lua filter           | `sudo pacman -S pandoc-cli`     |
| `entr`         | re-runs pandoc when the file changes  | `sudo pacman -S entr`           |
| `browser-sync` | local server + browser live reload    | `npm install -g browser-sync`   |
| `make`         | installing (pandoc builds the man page) | `sudo pacman -S make`         |
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

## Install from source

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
| `~/.local/share/man/man1/md-preview.1`         | the man page (`man md-preview`) |
| `~/.local/share/bash-completion/completions/md-preview` | bash completion |
| `~/.local/share/zsh/site-functions/_md-preview` | zsh completion |

bash-completion picks up its file from `~/.local` by itself, and `man`
finds the page when `~/.local/bin` is on your `PATH`. zsh needs the
directory on its `fpath`, before `compinit`, in `~/.zshrc`:

```zsh
fpath=(~/.local/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit
```

With `PREFIX=/usr/local` or a package, all three are found without any
setup.

Variations:

```sh
sudo make install PREFIX=/usr/local   # system-wide
make link                             # symlink ~/.local/bin/md-preview -> ./bin/md-preview
```

`make link` is for working on md-preview itself: the script finds its
support files by following its own symlink, so it uses the repository's
`share/md-preview/`, and edits take effect on the next save.

## Fetch KaTeX and mermaid for offline use

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

## Check the installation

```sh
md-preview doctor
```

```
md-preview 0.2.0

pandoc         pandoc 3.10.2
entr           /usr/bin/entr
browser-sync   /home/you/.config/nvm/versions/node/v24.19.0/bin/browser-sync (3.0.4)
share          /home/you/.local/share/md-preview
katex          /home/you/.local/share/md-preview/vendor/katex (fetched, 0.18.9)
mermaid        /home/you/.local/share/md-preview/vendor/mermaid (fetched, 12.0.0)

all good
```

## Try it

From the repository:

```sh
md-preview test-sample.md      # live, in the browser
make test                      # the regression suites; see tests/README.md
```

[`test-sample.md`](test-sample.md) exercises every supported feature. Each
section has an **Expect:** note saying what should appear.

## Emacs

`make install` puts `md-preview.el` in `~/.local/share/emacs/site-lisp/`.
It adds a minor mode that starts one `md-preview` process per buffer and
stops it when you disable the mode or kill the buffer. For MELPA,
straight.el/Elpaca, all options, and PATH problems in a GUI Emacs, see
[emacs/INSTALL.md](emacs/INSTALL.md).

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

## Documentation offline

```sh
make install-docs
md-preview docs          # http://localhost:6996
```

`install-docs` builds this website (README, this page, the reference, the
demo, …) and installs it to `~/.local/share/doc/md-preview/html`. Building
it needs KaTeX and mermaid, which it fetches if `md-preview fetch` hasn't
already. From a source checkout, `make -C site` alone is enough:
`md-preview docs` finds `site/_site` too.

## Packagers

All install targets honour `DESTDIR` and `PREFIX`:

```sh
make install        DESTDIR="$pkgdir" PREFIX=/usr
make install-docs   DESTDIR="$pkgdir" PREFIX=/usr   # needs KaTeX + mermaid, see below
make install-vendor DESTDIR="$pkgdir" PREFIX=/usr VENDOR_SRC=/path/to/vendor
```

`install-vendor` copies a vendor directory laid out like
`md-preview fetch` makes it (`katex/` holding KaTeX's `dist/`, and
`mermaid/mermaid.min.js`) to `/usr/share/md-preview/vendor`, so the package
works offline without `md-preview fetch`. With the same directory at
`$MD_PREVIEW_DATA/vendor`, `install-docs` builds without network access.
The AUR package does exactly this; see `packaging/aur/`.

## Upgrading

```sh
git pull
make install          # not needed with make link
```

Fetched KaTeX and mermaid are kept; `md-preview fetch --force` refreshes
them.

## Uninstalling

```sh
make uninstall                          # same PREFIX as used for install (also removes docs)
rm -rf ~/.local/share/md-preview        # fetched KaTeX / mermaid
npm uninstall -g browser-sync           # if nothing else uses it
```
