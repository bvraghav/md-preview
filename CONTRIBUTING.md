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

## Releasing

Versions follow the plan in [TODO.md](TODO.md#versioning): Semantic
Versioning, at 0.x until the interface settles. `VERSION` is the source of
truth, and the release suite (`make -C tests release`) checks that every
other copy agrees.

1. **Update the CHANGELOG.** Rename `[Unreleased]` to
   `[X.Y.Z] - YYYY-MM-DD`, add a new empty `[Unreleased]` above it, and
   update the links at the bottom:
   ```
   [Unreleased]: https://github.com/bvraghav/md-preview/compare/vX.Y.Z...HEAD
   [X.Y.Z]: https://github.com/bvraghav/md-preview/compare/vPREV...vX.Y.Z
   ```
2. **Bump the version** in `VERSION`, the `;; Version:` header of
   `emacs/md-preview.el`, the first line of `REFERENCE.md`, the `doctor`
   example in `INSTALL.md`, and the `VERSION` row in `MANIFEST.md`.
3. **Check locally:** `make test`. The release suite must pass.
4. **Commit and push `main`,** then wait for the `site` workflow to go
   green.
5. **Tag the tested commit and push the tag:**
   ```sh
   git tag -a vX.Y.Z -m "md-preview X.Y.Z"
   git push upstream vX.Y.Z
   ```
   The tag push runs the tests again on that commit, plus the release
   checks with the tag, so a mismatched version or tag shows up red.
6. **Publish the GitHub release** for the tag, with the CHANGELOG section
   as its notes, ending with
   `**Full changelog:** https://github.com/bvraghav/md-preview/compare/vPREV...vX.Y.Z`.
7. **Update the packages:** the AUR package (see
   [packaging/aur/README.md](packaging/aur/README.md)). MELPA picks up
   `main` by itself, and MELPA Stable picks up the tag.

Never move a published tag. If a release turns out wrong, fix it on `main`
and release a new PATCH version.
