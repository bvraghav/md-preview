# Regression tests

Five suites with a Makefile. From the repository root:

```sh
make test                   # all suites (same as: make -C tests)
make -C tests build         # one suite
make -k -C tests            # keep going after a failing suite
make -C tests ci            # build site browser serve: what CI runs
make -C tests clean         # remove _work/
```

At 0.0.3 all five pass: **182 checks in about 4 minutes**.

| Suite | Checks | Covers | Needs |
|---|---|---|---|
| `build` | 58 | rendering `test-sample.md`, output modes (`--assets`, `--embed`, `-o -`), frontmatter and TOC precedence, `gfm`, untitled pages, CLI errors, `assets`, `make install`, the View Source round trip | pandoc, python3 |
| `site` | 55 | the website: page set, link rewriting, frontmatter and TOC per page, footer, every page and asset over HTTP | pandoc, python3 |
| `serve` | 27 | live preview: served assets, localhost-only binding, in-place, rename-style, rapid and mid-render saves, three error→fix cycles, browser reloads, cleanup on SIGTERM, the nvm fallback | entr, browser-sync |
| `browser` | 35 | the site in headless Chromium: KaTeX and mermaid actually render, images, anchors, copy buttons, TOC layout, highlight and toggle, the navbar dropdown, line numbers | chromium or Chrome |
| `emacs` | 7 | the Emacs package byte-compiles cleanly; `md-preview-mode` starts, reports its URL and stops cleanly | emacs |

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
- **Mistakes in the tests themselves**, each caught and fixed while
  writing them:
  - `pgrep -f` inside `bash -c` matched that shell's own command line
  - `-- ARGS` placed before `-o` sent the output option to pandoc
  - a check for `class="mdp-frontmatter"` matched REFERENCE.md, which
    documents that markup; checks now match the element (`<details class=…`)
  - an error-page check looked for "pandoc failed", which `test-sample.md`
    itself contains; it now matches the page's `<h1>pandoc failed (exit`

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
