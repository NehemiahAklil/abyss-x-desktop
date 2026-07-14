# Plan — Linux AppImage Install/Uninstall Script

**Branch:** feature/appimage-installer-script_9
**Issue:** #9
**Date:** 2026-07-13

## Goal

Give users a way to install and uninstall the packaged Linux AppImage without
manually copying files and hand-writing a desktop entry, mirroring what an
`.exe` installer gives Windows users. Also bring Electron and electron-builder
up to their latest patch releases.

## Approach

A single interactive bash script, `install_abyss_x.sh`, with a numbered
terminal menu (no `zenity`/`kdialog` dependency, matching the plain-bash style
of the existing `install_loadcell.sh` in this repo):

- **Locate the AppImage** — search the script's directory, its `dist/`
  subdirectory, and the current directory; auto-pick by host architecture
  (`x86_64`/`aarch64`) when more than one candidate matches, or prompt when
  still ambiguous.
- **Pull metadata from the AppImage itself** — run `--appimage-extract`
  (works without FUSE, unlike mounting or running the AppImage directly) to
  read the embedded `.desktop` entry and icon, instead of shipping/maintaining
  a separate icon asset alongside the script.
- **Icon resolution matching** — the local `hicolor` icon theme's
  `index.theme` only declares icon sizes it actually scans (many systems stop
  at `512x512`, not `1024x1024`); an icon dropped in an undeclared size folder
  is silently invisible regardless of cache state. The script intersects the
  sizes the AppImage ships with the sizes the local theme declares and picks
  the largest match, falling back to `256x256` (near-universal) if nothing
  lines up. Verified against GTK's own `Gtk.IconTheme.lookup_icon` API, not
  just spec-reading.
- **Install scope** — "just me" (`~/.local/{bin,share}`, no privileges) or
  "all users" (`/usr/local/bin`, `/usr/share/...`, via `sudo`), selected
  per-run; `run_priv` only escalates for the system-wide branch.
- **Uninstall** — detects which scope(s) are actually installed and removes
  binary, icon (searched across resolution folders, not a hardcoded one), and
  desktop entry for the chosen scope, then refreshes the icon/desktop caches.

Verified live end-to-end: user-scope install → icon/desktop/binary checks →
launch → uninstall → re-install/overwrite → "nothing installed" idle path,
plus the multi-AppImage disambiguation menu.

## Changes

- `install_abyss_x.sh` (new) — interactive installer/uninstaller for the
  Linux AppImage build
- `package.json` — `electron` `^37.2.5` → `^37.10.3`, `electron-builder`
  `^26.0.12` → `^26.15.3`
- `pnpm-lock.yaml` — regenerated lockfile for the above bump
