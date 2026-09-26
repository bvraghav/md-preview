# md-preview

Live browser preview for Markdown with YAML frontmatter, mermaid diagrams
and KaTeX math. Built from pandoc, entr and browser-sync. Meant to be
started from Emacs, but works from any shell.

```sh
md-preview notes.md
```

That renders `notes.md`, opens it in your browser, and re-renders and
reloads the page every time you save the file. Stop it with `Ctrl-C`.

**Website:** <https://bvraghav.github.io/md-preview/>  
**Live demo:**
[`test-sample.md` as rendered by
md-preview](https://bvraghav.github.io/md-preview/demo.html)  
The whole site is built with md-preview itself; see [`site/`](site/Makefile).

---

## Contents

- [What you get](#what-you-get)
- [Setup](#setup)
- [Everyday use](#everyday-use)
- [Robustness](#robustness)
- [Publishing pages](#publishing-pages)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## What you get

- **Frontmatter**: YAML metadata becomes the title block (title, subtitle,
  authors, date, abstract). A collapsible table above the title lists every
  key, including nested maps and lists.
- **KaTeX math**: `$…$`, `$$…$$`, `\(…\)`, `\[…\]`, fenced `math` blocks,
  and bare `align`, `equation` and `gather` environments. `\newcommand`
  macros work, and so do `mhchem` (`\ce{…}`, `\pu{…}`) and copy-as-TeX.
- **Mermaid diagrams**: fenced `mermaid` blocks render in the browser, with
  a dark theme when your system uses dark mode.
- **Pandoc Markdown**: tables, footnotes, task lists, definition lists,
  GitHub alerts (`> [!NOTE]`), `==mark==`, `:emoji:`, fenced divs,
  syntax highlighting, citations.
- **Easy to navigate**: an automatic table of contents (a sidebar on wide
  screens, which highlights the section you're reading), `#` links on
  headings, and Copy buttons on code blocks.
- **Live reload that keeps your place**: the scroll position survives
  reloads. If pandoc fails, the browser shows its error message instead
  of the page.
- **Private and offline**: the server binds to `localhost`. After a
  one-time `md-preview fetch`, no network access is needed.

Full details are in [REFERENCE.md](REFERENCE.md).

## Setup

On Arch Linux:

```sh
sudo pacman -S pandoc-cli entr make
npm install -g browser-sync
git clone https://github.com/bvraghav/md-preview.git
cd md-preview && make install      # into ~/.local
md-preview fetch                   # KaTeX + mermaid, for offline use
md-preview doctor                  # check everything is found
```

**[INSTALL.md](INSTALL.md)** has the details: requirements and versions
(including a much faster pandoc build), install locations, `make link` for
hacking on md-preview, the Emacs package, upgrading and uninstalling.

## Everyday use

```sh
md-preview notes.md                     # live preview (same as: md-preview serve notes.md)
md-preview serve -p 4000 notes.md       # fixed port
md-preview serve -b firefox notes.md    # a specific browser
md-preview serve --no-open notes.md     # just serve; open the printed URL yourself
md-preview serve notes.md -- --toc      # extra pandoc options after --

md-preview build notes.md               # one-shot: writes notes.html next to notes.md
md-preview build --embed notes.md -o /tmp/notes.html   # single self-contained file
```

Relative image links resolve against the Markdown file's directory.

## Robustness

The demo has a **View source** link. That page is itself built by md-preview:
[`site/source-page.sh`](site/source-page.sh) puts `test-sample.md`
verbatim inside a fenced code block, and md-preview renders it like any
other page. [`site/roundtrip.py`](site/roundtrip.py) then extracts the text
back out of the rendered HTML and compares it with the original, byte for
byte; `make check` and every CI run fail if a single character differs.

What that proves the pipeline leaves alone inside a code block:

- the YAML frontmatter, including its `---` markers and `$\\LaTeX$` in a
  quoted title
- `\newcommand` (pandoc must not expand it), `$…$`, `\(…\)` and
  `$$…$$` math, and `$20` prices
- ```` ```mermaid ```` and ```` ```math ```` fences (the filter must not turn
  them into diagrams or equations), even nested inside a longer fence
- HTML entities (`&amp;`, `&#x2603;`), a literal `</code></pre>`, raw
  `<details>` blocks and HTML comments
- tabs, trailing double spaces, a whitespace-only line, and text in Greek,
  Cyrillic, Arabic, Japanese and emoji

Two details make it work. The outer fence is one backtick longer than the
longest backtick run in the file, so nothing inside can close it early. And
the page is rendered with `--preserve-tabs`; without it pandoc turns tabs
into spaces, and the check catches exactly that.

## Publishing pages

`build --assets PREFIX` makes a page link to its stylesheet, KaTeX and
mermaid under the relative URL `PREFIX/`, instead of absolute local paths.
`md-preview assets DIR` copies those files into place, so the output can
go on any static web host:

```sh
md-preview fetch                                  # once, to self-host KaTeX + mermaid
md-preview build --assets _md-preview notes.md -o public/index.html
md-preview assets public/_md-preview
```

The [project website](https://bvraghav.github.io/md-preview/) is built this way: see
[`site/Makefile`](site/Makefile) and the GitHub Actions workflow in
[`.github/workflows/site.yml`](.github/workflows/site.yml), which
rebuilds and deploys it to GitHub Pages on every push to `main`.

```sh
make -C site          # build into site/_site/
make -C site serve    # preview at http://localhost:8000
```

## Testing

```sh
make test                  # all suites (same as: make -C tests)
make -C tests build        # one suite
make -k -C tests           # keep going after a failure
```

| Suite     | Covers | Needs |
|-----------|--------|-------|
| `build`   | rendering `test-sample.md`, output modes (`--assets`, `--embed`, `-o -`), frontmatter and TOC settings, `gfm`, untitled pages, CLI errors, `assets`, `make install`, the View Source round trip | pandoc, python3 |
| `site`    | the website: page set, link rewriting, frontmatter and TOC per page, footer, every page and asset over HTTP | pandoc, python3 |
| `serve`   | live preview: served assets, localhost-only binding, in-place, rename-style and rapid saves, error page and recovery, browser reloads, cleanup on SIGTERM, the nvm fallback | entr, browser-sync |
| `browser` | the site in headless Chromium: KaTeX and mermaid actually render, images, anchors, copy buttons, TOC layout, highlight and toggle, the navbar dropdown, line numbers | chromium or Chrome |
| `emacs`   | the Emacs package compiles cleanly; `md-preview-mode` starts, reports its URL and stops cleanly | emacs |

A suite whose tools are missing is skipped rather than failed. GitHub
Actions runs `build`, `site`, `browser` and `serve` on every push and pull
request. `make check` is still there as a quick smoke test.

## Troubleshooting

**Every save takes 3–4 seconds to show up.** That's pandoc starting up.
Run `time pandoc --version`; if it takes more than about 0.3 s, switch to
the static pandoc build (see [INSTALL.md](INSTALL.md#1-requirements)).

**`browser-sync not found`.** Run `md-preview doctor`. If browser-sync is
somewhere unusual, set `MD_PREVIEW_BROWSER_SYNC=/path/to/browser-sync`.
Node must also be on `PATH`, or reachable through nvm.

**Math shows as raw TeX.** Most likely KaTeX didn't load. If you haven't
run `md-preview fetch`, check your network. A single expression in red
means KaTeX couldn't parse it; hover over it to see the error.

**A price like `$20` turned into math.** Pandoc pairs dollar signs within
a paragraph. Write `\$20` in paragraphs that contain math.

**`\(` no longer produces a literal parenthesis.** md-preview enables
`tex_math_single_backslash`, which makes `\(…\)` math. To turn it off, set
`MD_PREVIEW_FROM=markdown+alerts+mark+emoji`.

**Stale temp directories.** Each preview uses a directory under
`$XDG_RUNTIME_DIR` that's removed on exit. It is left behind only if the
process is killed with `SIGKILL`, and it's cleared at logout anyway.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for working on md-preview and the
release checklist, and [TODO.md](TODO.md) for the roadmap.

## License

MIT, see [LICENSE](LICENSE).
