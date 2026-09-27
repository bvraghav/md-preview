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
| `VERSION`       | Current version, read by the script at runtime (`0.2.0`) |
| `LICENSE`       | MIT license |
| `CONTRIBUTING.md` | Working on md-preview, and the release checklist |
| `TODO.md`       | Roadmap: the intent and the agreed plan for upcoming releases |
| `Makefile`      | `install`, `link`, `uninstall`, `bump`, `test`, `check`, `clean` |
| `tools/bump.sh` | `make bump V=X.Y.Z`: every copy of the version, the CHANGELOG section and links, the AUR PKGBUILD |
| `.gitignore`    | Ignores rendered HTML, check artefacts, the site build and test scratch space |

## Program

| File                               | Purpose |
|------------------------------------|---------|
| `bin/md-preview`                   | The command (bash). Subcommands `serve`, `build`, `fetch`, `doctor`. Drives pandoc, entr and browser-sync |
| `share/md-preview/template.html`   | Pandoc HTML5 template: title block, frontmatter slot, KaTeX (+ mhchem, copy-tex), mermaid loader, scroll keeper |
| `share/md-preview/filter.lua`      | Pandoc Lua filter: `mermaid` and `math` fences, frontmatter table, fallback page title, when to show the TOC |
| `share/md-preview/style.css`       | GitHub-like light/dark stylesheet |
| `share/md-preview/md-preview.js`   | Page enhancements: heading anchors, copy buttons, TOC state and current-section highlight |
| `emacs/md-preview.el`              | Emacs package: `md-preview-mode` and commands (MELPA-ready) |
| `emacs/INSTALL.md`                 | Emacs setup: MELPA, AUR, straight/Elpaca, options, PATH problems, testing an unreleased version |
| `man/md-preview.1.md`              | Man page source; `make man` builds `man/md-preview.1` with pandoc |
| `completions/md-preview.bash`      | bash completion: commands, per-command options, Markdown files |
| `completions/_md-preview`          | zsh completion, the same with descriptions |

## Packaging

| File                          | Purpose |
|-------------------------------|---------|
| `packaging/aur/PKGBUILD`      | Arch package: md-preview under `/usr`, with KaTeX, mermaid, the docs, man page, completion and Emacs package |
| `packaging/aur/.SRCINFO`      | Generated from the PKGBUILD (`makepkg --printsrcinfo`), required by the AUR |
| `packaging/aur/update.sh`     | Updates the PKGBUILD and .SRCINFO for a released tag: pkgver, pinned KaTeX/mermaid, checksums (run by the `aur` workflow) |
| `packaging/aur/README.md`     | What the package contains, how to test it, how new versions are published |
| `packaging/melpa/md-preview`  | MELPA recipe |
| `packaging/melpa/README.md`   | How to submit the recipe to MELPA |

## Website

The project site, built by md-preview itself and deployed to GitHub Pages.

| File                            | Purpose |
|---------------------------------|---------|
| `site/Makefile`                 | Builds `site/_site/`: README → `index.html`, test-sample → `demo.html`, CHANGELOG, LICENSE, MANIFEST, REFERENCE, TODO, INSTALL, CONTRIBUTING → lower-case `.html`, emacs/INSTALL → `emacs.html`, test-sample source → `demo-source.html`; copies md-preview's assets (stylesheet, KaTeX, mermaid) and `test-assets/` for the demo. `make serve` previews locally |
| `site/pages.yaml`               | The site's pages: source file, page name, title, TOC and extras; read by the Makefile and `links.lua` |
| `site/links.lua`                | Site filter (runs before md-preview's): maps links between repo files to pages (others to GitHub), sets titles, adds footers and the "View source" link |
| `site/nav.html.in`              | Navigation bar (`@REPO_URL@` substituted) with a "More" dropdown for secondary pages; marks the current page |
| `site/site.css`                 | Site-only styles (nav, "View source" link, footer), layered on `style.css` |
| `site/source-page.sh`           | Wraps a file verbatim in a fence nothing inside can close; builds the demo's View source page |
| `site/roundtrip.py`             | Extracts the code from a rendered source page and checks it matches the original byte for byte |
| `.github/workflows/site.yml`    | GitHub Actions: build the site, run the regression suites, deploy to Pages on push to `main` (PRs build and test only); on a `vX.Y.Z` tag push, also the release checks, and no deploy |
| `.github/workflows/aur.yml`     | GitHub Actions: when a release is published and its tag passed CI, update, build and check the AUR package in an Arch container, push it to the AUR, and commit the checksums back to `main`; by hand, a dry run |

## Test material

| File                     | Purpose |
|--------------------------|---------|
| `tests/folder-sample/`   | A folder for folder mode: README → index, a folder with `index.md`, one without (a listing), a name with a space, nested pages, links of every kind, an image, and a hidden folder and `node_modules` to skip. Also published as the folder demo |
| `test-sample.md`         | Covers every feature: frontmatter, every math syntax, 10 mermaid diagrams, pandoc Markdown blocks, and edge cases for View source. Sections carry **Expect:** notes |
| `test-assets/badge.svg`  | Image referenced by the sample, to check relative image links; published with the demo (`site/_site/test-assets/`) |

## Tests

Regression suites; see the Testing section of the README.

| File                     | Purpose |
|--------------------------|---------|
| `tests/README.md`        | How to run the suites, what each covers, bugs they found, how the harness works |
| `tests/Makefile`         | Runs the suites: `release`, `build`, `folder`, `completions`, `site`, `serve`, `browser`, `emacs`, `aur`; `ci` is the set GitHub Actions runs |
| `tests/anchors.py`       | Checks that every `#anchor` link in a built site lands on an element with that id |
| `tests/lib.sh`           | Assertion helpers (`check`, `refute`, `eq`, `ge`, `wait_for`, `skip`, …) shared by the suites |
| `tests/test-build.sh`    | Rendering, output modes, option precedence, CLI, `assets`, install, View Source round trip |
| `tests/test-site.sh`     | Website: pages, link rewriting, per-page features, HTTP |
| `tests/test-serve.sh`    | Live preview end to end, including saves, errors, reloads and cleanup |
| `tests/test-browser.sh`  | Headless Chromium runner: injects a probe into a page and checks what it reports |
| `tests/probes/*.js`      | Browser probes: `render` (math, diagrams, enhancements), `toc`, `dropdown`, `source` (line numbers) |
| `tests/test-release.sh`  | Version strings and CHANGELOG agree with `VERSION`; `make bump` leaves a tree that still agrees; with `TAG`, the tag too |
| `tests/test-folder.sh`   | Folder mode: pages, index and listing pages, link rewriting, assets by depth, the file tree, titles, incremental rebuilds, failures, options |
| `tests/test-completions.sh` | bash completion (direct), zsh completion (in a real interactive zsh), the man page |
| `tests/zcomp.zsh`        | Harness: drives an interactive zsh through `zsh/zpty` and prints what Tab offers |
| `tests/test-aur.sh`      | `update.sh` against the released tag; builds the AUR package from `HEAD`, checks its contents, runs md-preview from it with nothing fetched |
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
