# Manifest

Every file in the repository and what it does.

## Top level

| File            | Purpose |
|-----------------|---------|
| `README.md`     | What md-preview does, a quick start, everyday use |
| `INSTALL.md`    | Installation from source: requirements, `make install`, fetch, doctor, Emacs, upgrading, uninstalling |
| `REFERENCE.md`  | Complete reference: CLI, environment, dialect, math, diagrams, template, filter, Emacs API |
| `MANIFEST.md`   | This file |
| `CHANGELOG.md`  | Release history (Keep a Changelog format) |
| `VERSION`       | Current version, read by the script at runtime (`0.0.3`) |
| `LICENSE`       | MIT license |
| `CONTRIBUTING.md` | Working on md-preview, and the release checklist |
| `TODO.md`       | Roadmap: the intent and the agreed plan for upcoming releases |
| `Makefile`      | `install`, `link`, `uninstall`, `test`, `check`, `clean` |
| `.gitignore`    | Ignores rendered HTML, check artefacts, the site build and test scratch space |

## Program

| File                               | Purpose |
|------------------------------------|---------|
| `bin/md-preview`                   | The command (bash). Subcommands `serve`, `build`, `fetch`, `doctor`. Drives pandoc, entr and browser-sync |
| `share/md-preview/template.html`   | Pandoc HTML5 template: title block, frontmatter slot, KaTeX (+ mhchem, copy-tex), mermaid loader, scroll keeper |
| `share/md-preview/filter.lua`      | Pandoc Lua filter: `mermaid` and `math` fences, frontmatter table, fallback page title, when to show the TOC |
| `share/md-preview/style.css`       | GitHub-like light/dark stylesheet |
| `share/md-preview/md-preview.js`   | Page enhancements: heading anchors, copy buttons, TOC state and current-section highlight |
| `emacs/md-preview.el`              | Emacs package: `md-preview-mode` and commands |
| `man/md-preview.1.md`              | Man page source; `make man` builds `man/md-preview.1` with pandoc |
| `completions/md-preview.bash`      | bash completion: commands, per-command options, Markdown files |
| `completions/_md-preview`          | zsh completion, the same with descriptions |

## Packaging

| File                          | Purpose |
|-------------------------------|---------|
| `packaging/aur/PKGBUILD`      | Arch package: md-preview under `/usr`, with KaTeX, mermaid, the docs, man page, completion and Emacs package |
| `packaging/aur/.SRCINFO`      | Generated from the PKGBUILD (`makepkg --printsrcinfo`), required by the AUR |
| `packaging/aur/README.md`     | What the package contains, how to test it, how to publish a new version |

## Website

The project site, built by md-preview itself and deployed to GitHub Pages.

| File                            | Purpose |
|---------------------------------|---------|
| `site/Makefile`                 | Builds `site/_site/`: README → `index.html`, test-sample → `demo.html`, CHANGELOG, LICENSE, MANIFEST, REFERENCE, TODO, INSTALL, CONTRIBUTING → lower-case `.html`, test-sample source → `demo-source.html`; copies md-preview's assets (stylesheet, KaTeX, mermaid) and `test-assets/` for the demo. `make serve` previews locally |
| `site/links.lua`                | Pandoc filter: rewrites links between repo files to site pages, and other relative links to GitHub |
| `site/nav.html.in`              | Navigation bar (`@REPO_URL@` substituted) with a "More" dropdown for secondary pages; marks the current page |
| `site/site.css`                 | Site-only styles (nav, "View source" link, footer), layered on `style.css` |
| `site/source-page.sh`           | Wraps a file verbatim in a fence nothing inside can close; builds the demo's View source page |
| `site/roundtrip.py`             | Extracts the code from a rendered source page and checks it matches the original byte for byte |
| `.github/workflows/site.yml`    | GitHub Actions: build the site, run the regression suites, deploy to Pages on push to `main` (PRs build and test only); on a `vX.Y.Z` tag push, also the release checks, and no deploy |

## Test material

| File                     | Purpose |
|--------------------------|---------|
| `test-sample.md`         | Covers every feature: frontmatter, every math syntax, 10 mermaid diagrams, pandoc Markdown blocks, and edge cases for View source. Sections carry **Expect:** notes |
| `test-assets/badge.svg`  | Image referenced by the sample, to check relative image links; published with the demo (`site/_site/test-assets/`) |

## Tests

Regression suites; see the Testing section of the README.

| File                     | Purpose |
|--------------------------|---------|
| `tests/README.md`        | How to run the suites, what each covers, bugs they found, how the harness works |
| `tests/Makefile`         | Runs the suites: `release`, `build`, `completions`, `site`, `serve`, `browser`, `emacs`, `aur`; `ci` is the set GitHub Actions runs |
| `tests/lib.sh`           | Assertion helpers (`check`, `refute`, `eq`, `ge`, `wait_for`, `skip`, …) shared by the suites |
| `tests/test-build.sh`    | Rendering, output modes, option precedence, CLI, `assets`, install, View Source round trip |
| `tests/test-site.sh`     | Website: pages, link rewriting, per-page features, HTTP |
| `tests/test-serve.sh`    | Live preview end to end, including saves, errors, reloads and cleanup |
| `tests/test-browser.sh`  | Headless Chromium runner: injects a probe into a page and checks what it reports |
| `tests/probes/*.js`      | Browser probes: `render` (math, diagrams, enhancements), `toc`, `dropdown`, `source` (line numbers) |
| `tests/test-release.sh`  | Version strings and CHANGELOG agree with `VERSION`; with `TAG`, the tag too |
| `tests/test-completions.sh` | bash completion (direct), zsh completion (in a real interactive zsh), the man page |
| `tests/zcomp.zsh`        | Harness: drives an interactive zsh through `zsh/zpty` and prints what Tab offers |
| `tests/test-aur.sh`      | Builds the AUR package from `HEAD`, checks its contents, runs md-preview from it with nothing fetched |
| `tests/test-emacs.sh`    | Emacs package: byte-compile, and `md-preview-mode` in batch Emacs |

## Not in the repository

| Path                                          | Created by |
|-----------------------------------------------|------------|
| `~/.local/share/md-preview/vendor/`           | `md-preview fetch` (KaTeX, mermaid) |
| `$XDG_RUNTIME_DIR/md-preview.XXXXXX/`         | `md-preview serve`, removed on exit |
| `test-sample.html`                            | `make check` |
| `man/md-preview.1`                            | `make man`, `make install` |
| `site/_site/`, `site/_build/`                 | `make -C site` |
| `tests/_work/`                                | `make -C tests` |
