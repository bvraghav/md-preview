# Notes for AI assistants

Read by Claude Code at the start of a session here; useful to any
assistant or new contributor. The project's own documentation comes
first: [CONTRIBUTING.md](CONTRIBUTING.md) (conventions, what CI runs,
the release checklist), [tests/README.md](tests/README.md) and
[MANIFEST.md](MANIFEST.md). This file adds only what those don't say:
how the maintainer likes to work, and where things stand.

## Working with the maintainer

- **Commit at each milestone, push only when asked.** The maintainer
  pushes branches, opens and merges pull requests (with GitHub's merge
  button), tags, and publishes releases.
- **Never tag, or call a release ready to tag, before the maintainer has
  tried it in Emacs** and said to go ahead.
- **When a release branch is ready, write the pull request's title and
  description**, ready to paste, with absolute links (relative links to
  the CHANGELOG didn't work in PR descriptions).
- **No AI attribution in commits or pull requests:** no
  `Co-Authored-By:` trailers, no "Generated with" lines. The one
  exception is the `Assisted-by:` header in `emacs/md-preview.el`, which
  MELPA asks for (see CONTRIBUTING.md).
- **Keep the docs in step with every change:** CHANGELOG `[Unreleased]`,
  MANIFEST rows for new files, tests/README counts, and TODO.md's
  structure (the Intent section is the maintainer's words, verbatim).

## Environment

- The git remote is named **`upstream`**, not `origin`.
- The maintainer's machine has no `gh`, Docker or Podman, actionlint or
  shellcheck. Read GitHub state through the public REST API
  (`curl https://api.github.com/repos/bvraghav/md-preview/...`). Get
  actionlint and shellcheck as static binaries from their GitHub
  releases when linting workflows. `aur.yml`'s container steps can only
  be tested by its dry run on GitHub.
- CI runs on Ubuntu with older tools than Arch: entr 5.5 there, 5.8
  locally. Timing races have shown up only on CI; the `serve` suite
  prints diagnostics and CI uploads the test logs when it fails.
- Node and browser-sync come from nvm; pandoc is Arch's `pandoc-cli`,
  which takes about 1.6 s to start. CI pins pandoc in `site.yml`
  (`PANDOC_VERSION`); keep it at the version Arch ships, since Arch's
  pandoc is what the package's `check()` meets. pandoc 3.11 once broke a
  release that way (a new deprecation warning).

## Where things stand

- **Releases:** see the CHANGELOG. Work for the next release goes on a
  `release-X.Y.Z` branch.
- **AUR:** not published, because new AUR account registration is
  closed. Each release still carries the package (PKGBUILD and
  `.pkg.tar.zst`, attached by the `aur` workflow, which skips only the
  AUR push). Steps for when registration reopens:
  [issue #5](https://github.com/bvraghav/md-preview/issues/5).
- **MELPA:** the first recipe PR (melpa/melpa#10251) was closed because
  the repository must be public for a month. Resubmit as a new PR from
  2026-10-27: [issue #4](https://github.com/bvraghav/md-preview/issues/4).
  Be ready to say how md-preview differs from `markdown-live-preview-mode`,
  `markdown-preview-mode`, `grip-mode` and `impatient-mode`.
- **Roadmap:** [TODO.md](TODO.md).
