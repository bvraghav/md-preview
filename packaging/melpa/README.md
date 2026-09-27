# MELPA recipe

[`md-preview`](md-preview) is the recipe for
[MELPA](https://github.com/melpa/melpa). It builds the package from
`emacs/md-preview.el` only. MELPA builds snapshots from `main`; MELPA Stable
builds from `vX.Y.Z` tags.

## Before submitting

The `emacs` test suite (`make -C tests emacs`) already covers MELPA's
checks: byte-compilation with warnings as errors, `checkdoc`,
`package-lint`, and the package headers.

## Submitting (once)

1. Fork <https://github.com/melpa/melpa> and clone the fork.
2. Copy the recipe: `cp packaging/melpa/md-preview <melpa>/recipes/`.
3. Build it locally in the MELPA checkout:
   ```sh
   make recipes/md-preview
   ```
   then install the result to check it: `M-x package-install-file` on
   `packages/md-preview-*.el`.
4. Open a pull request against `melpa/melpa`, following its
   [CONTRIBUTING](https://github.com/melpa/melpa/blob/master/CONTRIBUTING.org)
   template. Mention that the package drives an external command,
   installed separately (on Arch, the package built from `packaging/aur`;
   elsewhere, from source).

After it's merged, nothing more is needed per release: MELPA picks up new
commits and MELPA Stable picks up new tags.
