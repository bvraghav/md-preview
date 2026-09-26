# Manifest

Every file in the repository and what it does.

## Top level

| File            | Purpose |
|-----------------|---------|
| `README.md`     | Usage summary and detailed setup instructions |
| `REFERENCE.md`  | Complete reference: CLI, environment, dialect, math, diagrams, template, filter, Emacs API |
| `MANIFEST.md`   | This file |
| `CHANGELOG.md`  | Release history (Keep a Changelog format) |
| `VERSION`       | Current version, read by the script at runtime (`0.0.1`) |
| `LICENSE`       | MIT license |
| `Makefile`      | `install`, `link`, `uninstall`, `check`, `clean` |
| `.gitignore`    | Ignores rendered HTML and check artefacts |

## Program

| File                               | Purpose |
|------------------------------------|---------|
| `bin/md-preview`                   | The command (bash). Subcommands `serve`, `build`, `fetch`, `doctor`. Drives pandoc, entr and browser-sync |
| `share/md-preview/template.html`   | Pandoc HTML5 template: title block, frontmatter slot, KaTeX (+ mhchem, copy-tex), mermaid loader, scroll keeper |
| `share/md-preview/filter.lua`      | Pandoc Lua filter: `mermaid` and `math` fences, frontmatter table, fallback page title |
| `share/md-preview/style.css`       | GitHub-like light/dark stylesheet |
| `emacs/md-preview.el`              | Emacs package: `md-preview-mode` and commands |

## Test material

| File                     | Purpose |
|--------------------------|---------|
| `test-sample.md`         | Covers every feature: frontmatter, every math syntax, 10 mermaid diagrams, pandoc Markdown blocks. Sections carry **Expect:** notes |
| `test-assets/badge.svg`  | Image referenced by the sample, to check relative image links |

## Not in the repository

| Path                                          | Created by |
|-----------------------------------------------|------------|
| `~/.local/share/md-preview/vendor/`           | `md-preview fetch` (KaTeX, mermaid) |
| `$XDG_RUNTIME_DIR/md-preview.XXXXXX/`         | `md-preview serve`, removed on exit |
| `test-sample.html`                            | `make check` |
