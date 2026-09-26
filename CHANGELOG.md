# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.3] - 2026-09-26

### Added

- Automatic table of contents from pandoc's `--toc`: a sidebar on screens
  1400px and wider, a collapsible box below the title otherwise. Shown when
  a page has 3+ headings; `md-preview-toc: true|false` in the frontmatter or
  `MD_PREVIEW_TOC` overrides. Highlights the section being read and
  remembers whether it's open.
- `#` anchor links on headings, and Copy buttons on code blocks.
- `share/md-preview/md-preview.js`: one script for these page enhancements,
  loaded by every page (`serve`, `build`, `--embed`, `--assets`).
- Demo "View source" page (`demo-source.html`): `test-sample.md` rendered
  verbatim by md-preview, and checked byte for byte against the original by
  `make check` and CI (`site/source-page.sh`, `site/roundtrip.py`).
- `tests/`: regression suites (`build`, `site`, `serve`, `browser`, `emacs`)
  with a Makefile, covering every check made during development; `make
  test` runs them, and GitHub Actions runs all but `emacs`.
- `test-sample.md`: edge cases for the source view (nested fences, tabs,
  entities, trailing spaces, mixed scripts).
- `TODO.md` roadmap, published on the site as `todo.html`.
- Site navigation: a "More" dropdown (Manifest, License, TODO). It's a
  `<details>` element, so it works without JavaScript; with JavaScript it
  closes on outside click, Escape or focus leaving, opens towards the side
  with room, and highlights "More" when the current page is inside it.

### Fixed

- `serve` could miss a save: entr, by default, drops events that arrive
  while the render it started is still running, and a render takes
  seconds. entr now runs with `-a`, so such a save triggers another render.
  Found by the new `serve` suite (1 save lost in 8 cycles before; none in
  24 after).
- Line numbers (`.numberLines`) were hidden: the stylesheet zeroed the
  margin pandoc draws them in.
- pandoc's syntax-highlighting CSS now loads before md-preview's stylesheet,
  so md-preview's styles override it rather than the other way round.

## [0.0.2] - 2026-09-26

### Added

- Project website built by md-preview itself (`site/`), deployed to GitHub
  Pages by a GitHub Actions workflow (`.github/workflows/site.yml`).
  README becomes the homepage, `test-sample.md` the live demo, and
  CHANGELOG, LICENSE, MANIFEST and REFERENCE get lower-case pages.
- `build --assets PREFIX`: link the stylesheet, KaTeX and mermaid relative
  to `PREFIX/`, for publishing on a web host.
- `md-preview assets DIR`: copy the stylesheet and fetched KaTeX/mermaid into
  the layout that `--assets` pages expect.

### Fixed

- README stated pandoc ≥ 3.1; the default `alerts` extension needs
  pandoc ≥ 3.9 in pandoc Markdown.

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

[Unreleased]: https://github.com/bvraghav/md-preview/compare/v0.0.3...HEAD
[0.0.3]: https://github.com/bvraghav/md-preview/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/bvraghav/md-preview/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/bvraghav/md-preview/releases/tag/v0.0.1
