# Manifest

Every file in the repository and what it does.

## Top level

| File            | Purpose |
|-----------------|---------|
| `README.md`     | Usage summary and detailed setup instructions |
| `REFERENCE.md`  | Complete reference: CLI, environment, dialect, math, diagrams, template, filter, Emacs API |
| `MANIFEST.md`   | This file |
| `CHANGELOG.md`  | Release history (Keep a Changelog format) |
| `VERSION`       | Current version, read by the script at runtime (`0.0.2`) |
| `LICENSE`       | MIT license |
| `TODO.md`       | Roadmap: the intent and the agreed plan for upcoming releases |
| `Makefile`      | `install`, `link`, `uninstall`, `check`, `clean` |
| `.gitignore`    | Ignores rendered HTML, check artefacts and the site build |

## Program

| File                               | Purpose |
|------------------------------------|---------|
| `bin/md-preview`                   | The command (bash). Subcommands `serve`, `build`, `fetch`, `doctor`. Drives pandoc, entr and browser-sync |
| `share/md-preview/template.html`   | Pandoc HTML5 template: title block, frontmatter slot, KaTeX (+ mhchem, copy-tex), mermaid loader, scroll keeper |
| `share/md-preview/filter.lua`      | Pandoc Lua filter: `mermaid` and `math` fences, frontmatter table, fallback page title |
| `share/md-preview/style.css`       | GitHub-like light/dark stylesheet |
| `emacs/md-preview.el`              | Emacs package: `md-preview-mode` and commands |

## Website

The project site, built by md-preview itself and deployed to GitHub Pages.

| File                            | Purpose |
|---------------------------------|---------|
| `site/Makefile`                 | Builds `site/_site/`: README → `index.html`, test-sample → `demo.html`, CHANGELOG, LICENSE, MANIFEST, REFERENCE, TODO → lower-case `.html`; copies md-preview's assets (stylesheet, KaTeX, mermaid) and `test-assets/` for the demo. `make serve` previews locally |
| `site/links.lua`                | Pandoc filter: rewrites links between repo files to site pages, and other relative links to GitHub |
| `site/nav.html.in`              | Navigation bar (`@REPO_URL@` substituted) with a "More" dropdown for secondary pages; marks the current page |
| `site/site.css`                 | Site-only styles (nav, footer), layered on `style.css` |
| `.github/workflows/site.yml`    | GitHub Actions: `make check`, build the site, deploy to Pages on push to `main` (PRs build only) |

## Test material

| File                     | Purpose |
|--------------------------|---------|
| `test-sample.md`         | Covers every feature: frontmatter, every math syntax, 10 mermaid diagrams, pandoc Markdown blocks. Sections carry **Expect:** notes |
| `test-assets/badge.svg`  | Image referenced by the sample, to check relative image links; published with the demo (`site/_site/test-assets/`) |

## Not in the repository

| Path                                          | Created by |
|-----------------------------------------------|------------|
| `~/.local/share/md-preview/vendor/`           | `md-preview fetch` (KaTeX, mermaid) |
| `$XDG_RUNTIME_DIR/md-preview.XXXXXX/`         | `md-preview serve`, removed on exit |
| `test-sample.html`                            | `make check` |
| `site/_site/`, `site/_build/`                 | `make -C site` |
