# AUR package

`PKGBUILD` and `.SRCINFO` for <https://aur.archlinux.org/packages/md-preview>.
The package installs md-preview under `/usr`, together with:

- KaTeX and mermaid (`/usr/share/md-preview/vendor`), downloaded as package
  sources, so md-preview works offline without `md-preview fetch`;
- the documentation website (`/usr/share/doc/md-preview/html`), built
  during `build()` without network access, for `md-preview docs`;
- the man page, bash and zsh completion, and the Emacs package in
  `/usr/share/emacs/site-lisp`.

`check()` runs `make check`, including the View Source round trip.

## Testing

```sh
make -C tests aur
```

builds the package from a tarball of `HEAD` (so it works before the tag
exists), checks its contents, unpacks it and runs md-preview from it with
nothing fetched, and checks that `.SRCINFO` matches the `PKGBUILD`.

## Releasing a new version

`make bump V=X.Y.Z` sets `pkgver` and `pkgrel=1` along with every other copy
of the version (see [CONTRIBUTING.md](../../CONTRIBUTING.md)). The rest is
automatic: when the GitHub release for `vX.Y.Z` is published, the
[`aur` workflow](../../.github/workflows/aur.yml)

1. waits for the tag's own CI run (tests and release checks) to pass;
2. in an Arch Linux container, runs `update.sh X.Y.Z`: the KaTeX and mermaid
   versions that tag pins, and every checksum, now that GitHub serves the
   tag's tarball; then regenerates `.SRCINFO`;
3. builds and checks the package with `makepkg` as a non-root user, and runs
   `namcap`;
4. pushes `PKGBUILD` and `.SRCINFO` to
   `ssh://aur@aur.archlinux.org/md-preview.git` (the first push creates the
   package);
5. commits them back to `packaging/aur/` on `main`.

Pre-releases are built but not published. Each run uploads the package,
`PKGBUILD` and `.SRCINFO` as an artifact.

### Dry run

Actions → aur → Run workflow, with a tag (default: the latest release) and
"publish" unticked: steps 1–3 only. Use it to try the pipeline, or to check
an older tag. Ticking "publish" also does steps 4–5, e.g. for a release
published before this workflow existed.

### One-time setup

1. An account on <https://aur.archlinux.org>.
2. A key pair just for this:
   ```sh
   ssh-keygen -t ed25519 -N '' -C 'md-preview AUR (GitHub Actions)' -f aur_md-preview
   ```
   Add `aur_md-preview.pub` to the AUR account (My Account → SSH Public Key).
3. Add the private key, `aur_md-preview`, as the repository secret
   `AUR_SSH_PRIVATE_KEY` (Settings → Secrets and variables → Actions), then
   delete both files.

### By hand

If the workflow can't run, the same steps from `packaging/aur`:

```sh
./update.sh X.Y.Z                 # needs the tag on GitHub
makepkg -f && namcap PKGBUILD md-preview-*.pkg.tar.*
git clone ssh://aur@aur.archlinux.org/md-preview.git ~/aur/md-preview   # once
cp PKGBUILD .SRCINFO ~/aur/md-preview/
cd ~/aur/md-preview && git add PKGBUILD .SRCINFO && git commit -m "md-preview X.Y.Z" && git push
```

and commit the updated `PKGBUILD` and `.SRCINFO` here.

For packaging-only fixes, bump `pkgrel` by hand instead of `pkgver`, and
publish by hand; the workflow always sets `pkgrel=1`.
