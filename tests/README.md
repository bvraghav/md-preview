# Regression tests

Nine suites with a Makefile. From the repository root:

```sh
make test                   # all suites (same as: make -C tests)
make -C tests build         # one suite
make -k -C tests            # keep going after a failing suite
make -C tests ci            # release build site browser serve: what CI runs
make -C tests release TAG=v0.1.0   # the release checks, including the tag
make -C tests clean         # remove _work/
```

At 0.2.0 all nine pass: **420 checks**, about 2½ minutes. CI runs fewer:
`emacs` and `aur` don't run there, and the zsh and nvm-fallback checks
don't apply on the runner.

| Suite | Checks | Covers | Needs |
|---|---|---|---|
| `build` | 78 | rendering `test-sample.md`, output modes (`--assets`, `--embed`, `-o -`), frontmatter and TOC precedence, `gfm`, untitled pages, CLI errors, `assets`, `make install`, the View Source round trip | pandoc, python3 |
| `folder` | 55 | folder mode on `tests/folder-sample`: the page set, README/index/listing pages, link rewriting (`../`, anchors, folders, spaces), assets relative to depth, the file tree (current page, open folders), titles, incremental rebuilds (edit, add, remove, `--force`), a broken page, options, user-filter order, single files unchanged | pandoc |
| `completions` | 41 | bash completion called directly; zsh completion in a real interactive zsh (driven through `zsh/zpty` by `zcomp.zsh`); the man page builds and has every section | zsh, pandoc, man |
| `site` | 83 | the website: page set, link rewriting, frontmatter and TOC per page, footer, every page and asset over HTTP | pandoc, python3 |
| `serve` | 56 | live preview: served assets, localhost-only binding, in-place, rename-style, rapid and mid-render saves, three error→fix cycles, browser reloads, cleanup on SIGTERM, the nvm fallback; for a folder: edits, new and deleted files, a file in a new subfolder, a folder created empty and filled later, a broken page, cleanup | entr, browser-sync |
| `browser` | 43 | the site in headless Chromium: KaTeX and mermaid actually render, images, anchors, copy buttons, TOC layout, highlight and toggle, the navbar dropdown, line numbers | chromium or Chrome |
| `release` | 11 | every copy of the version (`VERSION`, the Elisp header, REFERENCE, README, MANIFEST) agrees, and the CHANGELOG has a dated section and links for it; with `TAG=vX.Y.Z`, the tag matches and points at the tested commit | nothing |
| `aur` | 25 | builds the AUR package from a tarball of `HEAD` (checks run inside), checks its contents, and runs md-preview from the unpacked package with nothing fetched: packaged KaTeX and mermaid, `docs` from `/usr/share/doc`, the man page; `.SRCINFO` matches the PKGBUILD | makepkg (Arch; not on CI) |
| `emacs` | 26 | the Emacs package byte-compiles cleanly and passes `checkdoc` and `package-lint` (MELPA's checks) with a full header; a missing `md-preview` command gives a helpful error and leaves the mode off; the URL is parsed from coloured output; `md-preview-mode` and `md-preview-folder` start, report their URL and stop cleanly | emacs (package-lint is fetched from MELPA) |

A suite whose tools are missing is **skipped, not failed**. GitHub
Actions runs `build`, `site`, `browser` and `serve` on every push and pull
request; `emacs` runs locally only. `make check` in the root is still
there as a quick smoke test.

## What the suites cover in 0.0.3

- **TOC:** built by pandoc at render time. On wide screens it's a sidebar
  that highlights the section you're reading; narrower, it's a collapsible
  box below the title. It remembers whether you left it open, and appears
  only when a page has 3+ headings; `md-preview-toc: false` or
  `MD_PREVIEW_TOC` overrides that. The site turns it off for README, which
  has its own Contents.
- **Anchors and copy buttons:** `#` links on headings and a Copy button on
  every code block, from one new file, `share/md-preview/md-preview.js`.
- **View Source:** the demo links to `demo-source.html`, which md-preview
  renders from `test-sample.md` placed verbatim in a code block.
  `test-sample.md` has an edge-case section (nested fences, tabs,
  entities, a literal `</code></pre>`, mixed scripts). `site/roundtrip.py`
  extracts the text back out of the HTML, and it matches the original byte
  for byte (562 lines). The check fails if tabs are lost, which shows it
  catches real differences.

## Bugs the tests found

- **`serve` could drop a save.** By default entr discards events that
  arrive while the render it started is still running, and a render takes
  seconds. Fixed with `entr -a`: 1 save lost in 8 error→fix cycles before
  the fix, none in 24 after. The `serve` suite keeps three such cycles as a
  regression test.
- **Hidden line numbers:** the stylesheet clipped the numbers on
  `.numberLines` code blocks.
- **pandoc's styles overrode ours:** its syntax-highlighting CSS loaded
  after md-preview's stylesheet. It now loads first.
- **A folder's `index.html` replaced the preview** (0.1.0, reported by a
  user): browser-sync tries `--serveStatic` folders first. The serve suite's
  document folder now always has an `index.html`.
- **Deep links landed in the wrong place** on pages with diagrams (0.1.0):
  found when the TOC-highlight probe failed on the slower CI runner.

In 0.2.0, the folder-mode tests found:

- **A file in a new subfolder was never picked up**, when it appeared while
  the watcher was rebuilding: the file list was taken after the build, so it
  already included the new file that the build hadn't seen.
- **A save during a folder build was lost**: a page rendered from the old
  text came out newer than its source, and entr wasn't running yet. Pages
  now carry their source's mtime from before rendering, and entr starts
  before each build.
- **Every folder build after the first hung**: the serve process kept the
  build lock's file descriptor open. Found when the serve suite took over
  ten minutes instead of one.
- **The site's stylesheet stopped overriding md-preview's**, after user
  options were moved before md-preview's own; the preview bar would have
  shown on the website. The browser suite now checks the bar is hidden.
- **Mistakes in the tests themselves**, each caught and fixed while
  writing them:
  - (0.2.0) a `for f in $(find …)` loop in a check split "My Notes.html",
    the very file name that's there to catch that bug in md-preview
  - `pgrep -f` inside `bash -c` matched that shell's own command line
  - `-- ARGS` placed before `-o` sent the output option to pandoc
  - a check for `class="mdp-frontmatter"` matched REFERENCE.md, which
    documents that markup; checks now match the element (`<details class=…`)
  - an error-page check looked for "pandoc failed", which `test-sample.md`
    itself contains; it now matches the page's `<h1>pandoc failed (exit`
  - two checks assumed things about the machine, and failed on the first
    CI run: the nvm-fallback check ran where nvm had no browser-sync (CI
    installs it with `sudo npm -g`), and the dropdown check expected the
    menu to flip at 500px, which depends on how fonts make the nav wrap.
    The first now runs only when nvm has browser-sync; the second checks
    that the menu flips exactly when it would overflow, and forces a case
    that needs it by moving "More" to the left edge

## Known issue

One early `serve` run failed four checks in a row. It came right after a
stress run, and the following 13 runs passed, so it couldn't be reproduced.
If it recurs, the logs are in `_work/serve/serve-N.log`.

## How it works

- **`lib.sh`** is sourced by every suite. It provides `check` / `refute`
  (a command succeeds / fails), `eq` and `ge` (compare values), `count`,
  `wait_for` (poll until a command succeeds), `need` / `skip`, `free_port`,
  and `finish`, which prints the summary and sets the exit status.
- **Scratch space** is `_work/`. KaTeX and mermaid are fetched once into
  `$MD_PREVIEW_DATA`, which defaults to `_work/data`; point it at an
  existing data directory to reuse its downloads, as CI does.
- **`serve`** starts `md-preview serve` in its own session on a free port,
  with each run logging to its own `_work/serve/serve-N.log`. It saves the
  document in different ways and polls the served page until the change
  shows up.
- **`browser`** copies the built site to `_work/www`, serves it, and for
  each check injects a probe from `probes/` into the page (keeping the
  page's file name, since the nav's current-page logic depends on it). The
  probe writes `key=value` lines into `<pre id="probe">`; headless Chromium
  dumps the DOM and the suite asserts on the values. An empty result is a
  failure, so a broken browser can't make comparisons pass vacuously.
  Set `CHROME` to choose the browser binary.
- **Timing:** everything that waits on a render uses `wait_for` with a
  generous limit, because pandoc can take several seconds to start.

## Adding a test

Add assertions to the suite that owns the area, or a new
`test-NAME.sh` that sources `lib.sh` and ends with `finish`, plus a
target in `Makefile`. Match real elements rather than text that
documentation might also contain, and prefer `wait_for` over fixed sleeps.
