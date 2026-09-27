# Contributing

## Working on md-preview

```sh
make link                  # ~/.local/bin/md-preview -> ./bin/md-preview
make test                  # all regression suites; see tests/README.md
make -C tests build        # one suite
make -C site serve         # the website at http://localhost:8000
```

Add a CHANGELOG entry under `[Unreleased]` for anything a user would
notice, including fixes to the tests if they change what CI reports.

## Conventions

- **Branches:** work for a release goes on `release-X.Y.Z`, merged into
  `main` through a pull request. Pushing a branch runs no CI; opening the
  pull request does (see [What CI runs](#what-ci-runs)).
- **TODO.md** is the roadmap, in this order: `## Intent` (the requests as
  the maintainer wrote them, verbatim and numbered; later additions get
  the next number), `## Priorities` (a table of what's left, by release),
  one `## P1`, `## P2`, … section per open item with the agreed plan,
  `## Versioning`, and `# DONE`, newest release first, where each finished
  item moves with a "Shipped in X.Y.Z" note.
- **tests/README.md** documents the suites: when checks are added or
  removed, update its per-suite counts and total, and add a bug the tests
  found to its list.
- **MANIFEST.md** lists every file; add a row for each new one.
- **Workflows:** lint with [actionlint](https://github.com/rhysd/actionlint),
  which also runs [shellcheck](https://github.com/koalaman/shellcheck) on
  the `run:` scripts when it's on `PATH`. Neither is packaged here; both
  ship single static binaries on their GitHub release pages. The container
  steps of `aur.yml` can't run locally without Docker or Podman; its dry
  run (Actions → aur → Run workflow) tests them.
- **`Assisted-by:`** in the header of `emacs/md-preview.el` is MELPA's
  [attribution for AI-generated code](https://github.com/melpa/melpa/blob/master/CONTRIBUTING.org#attribution-for-ai-generated-code).
  Keep it; if another assistant or model contributes code, add it there.

## What CI runs

| Event | Workflow, jobs | What for |
|---|---|---|
| pull request | `site`: build | the tests, on the PR merged into `main` |
| push to `main` | `site`: build, deploy | the tests again, then the website |
| push of a `vX.Y.Z` tag | `site`: build | the tests and the release checks with `TAG` |
| release published | `aur`: gate, build | waits for the tag's run; builds the Arch package, attaches it to the release, publishes to the AUR if `AUR_SSH_PRIVATE_KEY` is set, commits its checksums to `main` |
| by hand | `site` or `aur` | `aur` by hand is a dry run unless "publish" is ticked |

When a suite fails only on CI, the run's `test-logs` artifact has the
suites' logs.

## Releasing

Versions follow the plan in [TODO.md](TODO.md#versioning): Semantic
Versioning, at 0.x until the interface settles. `VERSION` is the source of
truth, and the release suite (`make -C tests release`) checks that every
other copy agrees.

1. **Bump:** `make bump V=X.Y.Z` (today's date; `DATE=YYYY-MM-DD` for
   another). It renames `[Unreleased]` to `[X.Y.Z] - DATE` under a new
   empty `[Unreleased]`, updates the compare links, and sets the version in
   `VERSION`, the `;; Version:` header of `emacs/md-preview.el`, the first
   line of `REFERENCE.md`, the `doctor` example in `INSTALL.md`, the
   `VERSION` row in `MANIFEST.md`, and the AUR `PKGBUILD` and `.SRCINFO`.
2. **Review** `git diff`, and write the release's summary line under its
   CHANGELOG heading if it needs one.
3. **Check locally:** `make test`. The release suite must pass. Try the
   Emacs package too (`md-preview-mode`, `md-preview-folder`).
4. **Commit on `release-X.Y.Z`, push it, and open a pull request** into
   `main`. Merge it once CI is green (the merge button is fine), and wait
   for the `site` run on `main` to go green too.
5. **Tag the merged commit and push the tag:**
   ```sh
   git checkout main && git pull
   git tag -a vX.Y.Z -m "md-preview X.Y.Z"
   git push upstream vX.Y.Z
   ```
   The tag push runs the tests again on that commit, plus the release
   checks with the tag, so a mismatched version or tag shows up red.
6. **Publish the GitHub release** for the tag, with the CHANGELOG section
   as its notes, ending with
   `**Full changelog:** https://github.com/bvraghav/md-preview/compare/vPREV...vX.Y.Z`.
7. **Packages update themselves.** Publishing the release starts the `aur`
   workflow, which waits for the tag's CI run, then builds and publishes the
   AUR package and commits its checksums back to `main` (see
   [packaging/aur/README.md](packaging/aur/README.md)); pull before your
   next commit. MELPA picks up `main` by itself, and MELPA Stable picks up
   the tag.

Never move a published tag. If a release turns out wrong, fix it on `main`
and release a new PATCH version.
