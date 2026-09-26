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

After the `vX.Y.Z` tag is pushed (see [CONTRIBUTING.md](../../CONTRIBUTING.md)):

1. In `PKGBUILD`, set `pkgver=X.Y.Z` and `pkgrel=1`. If md-preview's pinned
   KaTeX or mermaid versions changed, update `_katex` and `_mermaid` too.
2. Fill in the checksums, now that GitHub serves the tag's tarball:
   ```sh
   cd packaging/aur
   updpkgsums
   makepkg --printsrcinfo > .SRCINFO
   ```
3. Test: `make -C tests aur`, and, with devtools installed, a clean-chroot
   build: `pkgctl build` (or `extra-x86_64-build`) in `packaging/aur`.
4. Commit the updated `PKGBUILD` and `.SRCINFO` here.
5. Publish to the AUR:
   ```sh
   git clone ssh://aur@aur.archlinux.org/md-preview.git ~/aur/md-preview   # once
   cp packaging/aur/PKGBUILD packaging/aur/.SRCINFO ~/aur/md-preview/
   cd ~/aur/md-preview
   git add PKGBUILD .SRCINFO
   git commit -m "md-preview X.Y.Z"
   git push
   ```
   The first push creates the package; it needs an AUR account with your
   SSH key.

For packaging-only fixes, bump `pkgrel` instead of `pkgver`.
