# MELPA recipe

[`md-preview`](md-preview) is the recipe for
[MELPA](https://github.com/melpa/melpa). It builds the package from
`emacs/md-preview.el` only. MELPA builds snapshots from `main`; MELPA Stable
builds from `vX.Y.Z` tags.

## Before submitting

The `emacs` test suite (`make -C tests emacs`) already covers MELPA's
checks: byte-compilation with warnings as errors, `checkdoc`,
`package-lint`, and the package headers.

## Status

Not yet on MELPA. The first recipe PR,
[melpa/melpa#10251](https://github.com/melpa/melpa/pull/10251), was closed
on 2026-09-27: MELPA only takes packages whose repository has been public
for at least a month, and this one was created on 2026-09-26. Their note
asks for a **new** pull request (not a reopened one) once that's true, so
from **2026-10-27**. The steps for then are
[issue #4](https://github.com/bvraghav/md-preview/issues/4).

For that PR, be ready to say how md-preview differs from the existing
Markdown previewers (markdown-mode's `markdown-live-preview-mode`,
`markdown-preview-mode`, `grip-mode`, `impatient-mode`), since MELPA
declines packages that duplicate existing ones: YAML frontmatter, KaTeX
and mermaid rendered offline, and whole-folder previews with a file tree
and working links, served live or built as a static site.

Review comments are answered with changes on `main`, which MELPA builds
from.

## Submitting (once)

1. Fork <https://github.com/melpa/melpa> and clone the fork.
2. Copy the recipe: `cp packaging/melpa/md-preview <melpa>/recipes/`.
3. Build it the way MELPA will, from GitHub's `main` (not your checkout):
   ```sh
   make recipes/md-preview              # -> packages/md-preview-*.tar
   make sandbox INSTALL=md-preview      # installs it into ./sandbox/elpa
   ```
   `make sandbox` runs Emacs in batch mode: it installs the package and
   exits. To try it, start an Emacs that uses only the sandbox:
   ```sh
   emacs --init-directory=sandbox --no-site-file     # Emacs 29 or later
   ```
   `--init-directory` skips your own init and packages, and
   `--no-site-file` keeps an md-preview installed system-wide (the Arch
   package) from standing in for MELPA's build. `M-x locate-library RET
   md-preview` should name a file under `sandbox/elpa/`. The `md-preview`
   command must still be on `PATH`.
4. Open a pull request against `melpa/melpa` titled
   `Add recipe for md-preview`, filling in its template (see its
   [CONTRIBUTING](https://github.com/melpa/melpa/blob/master/CONTRIBUTING.org)).
   Mention that the package drives an external command, installed
   separately (on Arch, the package attached to each release; elsewhere,
   from source), and tick the AI-assistance box: the `Assisted-by:` header
   is in `emacs/md-preview.el`.

After it's merged, nothing more is needed per release: MELPA picks up new
commits and MELPA Stable picks up new tags.
