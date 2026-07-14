# Plan — Linux Release Tarball + Installer Fixes

**Branch:** feature/appimage-installer-script_9
**Issue:** #9 (continuation)
**Date:** 2026-07-14

## Goal

Ship the installer as part of the Linux release instead of a separate
download, and fix two rough edges found while wiring that up: the AppImage
search order and the installed binary's filename.

## Approach

- **Move** `install_abyss_x.sh` → `scripts/install_abyss_x.sh`.
- **CI packaging (`build.yml`)** — after building the AppImage, stage it
  (renamed to `AbyssX`, no extension, executable) together with
  `scripts/install_abyss_x.sh` into `abyss-x-linux/`, then tar it as
  `dist/Abyss-X-<version>-linux.tar.gz`. Uploaded and attached to the release
  alongside the existing raw `.AppImage`/`.deb`.
- **Release notes** — `softprops/action-gh-release`'s `body` is prepended to
  `generate_release_notes`'s auto notes (confirmed via the action's own docs),
  so a fixed Linux install note (which file to grab, the three-line install
  command) now ships in every release body.
- **`find_appimage` fixes**:
  - The `dist/` fallback path was `$SCRIPT_DIR/dist`, which broke once the
    script moved into `scripts/` (electron-builder's output dir is the repo
    root's `dist/`, i.e. `$SCRIPT_DIR/../dist`). Fixed.
  - Search was aggregating candidates from all three directories at once
    instead of treating them as ordered fallbacks. Changed to stop at the
    first directory (same-level next to the script → `../dist/` → cwd) that
    has any match, so a real installed release always resolves from the
    tarball's own directory without ever touching `dist/`.
  - Extended the match glob to also catch the extensionless `AbyssX` name
    (not just `*.AppImage`), since the tarball now ships it pre-renamed.
- **Bin filename** — `BIN_FILENAME` changed from `AbyssX.AppImage` to
  `AbyssX`. The existing copy-to-fixed-destination logic in `do_install`
  already performs the "rename" (it always copies to `$bin_dir/$BIN_FILENAME`
  regardless of the source's name), so no new renaming logic was needed —
  only the constant.
- **Docs** — README's Installation section gets the tarball as the
  recommended path, plus a short section pointing at
  `scripts/install_abyss_x.sh`; the script's own header comment documents
  usage and search order.

Verified locally (not through real CI): four `find_appimage` scenarios sourced
from the actual repo-relative paths — tarball layout (extensionless file next
to script), dev layout falling through to `../dist/`, dev layout with two
archs in `dist/` (arch-matching still resolves the host arch), and same-level
+ `dist/` both populated (same-level wins, `dist/` never consulted). Also
dry-ran the CI packaging step's tar/cp/chmod sequence and confirmed the
resulting archive layout (`abyss-x-linux/{install_abyss_x.sh,AbyssX}`, both
executable) matches what the docs describe. Confirmed via `gh release view`
that CI only ever produces one Linux AppImage today, so no multi-arch
tarball-naming scheme was needed.

## Changes

- `scripts/install_abyss_x.sh` (moved from repo root) — fixed `dist/` path,
  ordered-fallback search, extensionless-name matching, `BIN_FILENAME`
  dropped its `.AppImage` suffix, expanded header usage comment
- `.github/workflows/build.yml` — new tarball packaging step in
  `build-linux`, `dist/*.tar.gz` added to the uploaded artifact, release
  step's `body` documents the Linux install flow
- `README.md` — tarball added to the download table, new "installer script
  (recommended)" subsection
- `PROJECT.md` — updated path/description for the moved script
