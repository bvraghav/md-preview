# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.1] - 2026-09-26

### Added

- `md-preview` script with subcommands `serve` (default), `build`, `fetch`,
  `doctor`, `help` and `version`.
- Live preview with pandoc + entr + browser-sync. Binds to `localhost` by
  default, keeps the scroll position across reloads, and shows an error
  page when pandoc fails.
- Robust file watching: survives editors that save via rename, and
  re-renders saves made while entr restarts.
- KaTeX math: `$…$`, `$$…$$`, `\(…\)`, `\[…\]`, fenced `math` blocks,
  bare LaTeX environments, `\newcommand` macros, `mhchem`, copy-tex.
- Mermaid diagrams from fenced `mermaid` blocks, themed to match the
  system's light or dark mode.
- YAML frontmatter shown as a collapsible table (nested maps and lists
  supported) above the pandoc title block.
- `md-preview fetch`: pinned KaTeX 0.18.9 and mermaid 12.0.0 for offline
  use, falling back to the jsDelivr CDN.
- Finds a browser-sync installed under nvm when nvm isn't loaded.
- GitHub-like stylesheet with light and dark themes, alerts, task lists,
  footnotes, and print styles.
- `build --embed` for single-file, self-contained HTML.
- Emacs package `md-preview.el` with `md-preview-mode`.
- `Makefile` with `install`, `link`, `uninstall`, `check`, `clean`.
- `test-sample.md` covering every supported feature.

[Unreleased]: https://github.com/bvraghav/md-preview/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/bvraghav/md-preview/releases/tag/v0.0.1
