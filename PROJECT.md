# Project Map

> **Navigation rule:** When a prompt targets a specific area, go directly to the
> mapped path. Do not scan unrelated directories or read files outside the
> relevant path unless the task explicitly requires cross-cutting changes.

## Tech Stack

- Electron 37 (main process: `index.js`, preload: `preload.js`)
- Bundled web frontend in `res/` (upstream `ear-web`, kept byte-identical
  except for the Electron integration points)
- electron-builder for packaging (Linux AppImage/deb, Windows NSIS, macOS
  dmg/zip), published via GitHub Actions (`.github/workflows/build.yml`)

## Project Structure

| Path | Purpose |
|---|---|
| `index.js` | Electron main process — custom `app://` protocol serving `res/`, Web Serial port picker wiring, window creation, security policy (permissions, navigation, window-open guards) |
| `preload.js` | Preload script — renders the serial port picker overlay, exposes a legacy `eel` stub via `contextBridge` for `res/js/control.js` |
| `res/` | Bundled `ear-web` frontend (HTML/JS/CSS/assets), served over `app://` |
| `build/` | electron-builder icons and resources |
| `.github/workflows/build.yml` | CI: builds Linux/Windows/macOS installers and publishes a GitHub Release on `v*` tags |
| `.github/workflows/manage-issues.yml` | CI: closes issues referenced in a merged PR's commits once all their checkboxes are ticked |
| `.github/workflows/release-on-merge.yml` | CI: on a merge to `master` carrying a release-worthy label (`Feature`/`Bug`/`Hot Fix`/`Enhancement`/`Security`), bumps `package.json`'s version, tags, and pushes — the tag push triggers `build.yml` |

## Notes

- `res/` is kept byte-identical with upstream `ear-web` where possible; Electron-specific glue lives in `index.js`/`preload.js`, not in `res/`.
- `contextIsolation` and `sandbox` are enabled on the `BrowserWindow`; anything the page needs from Node/Electron must be exposed explicitly via `contextBridge` in `preload.js` (Proxy objects are not supported by `contextBridge`).
- Web Serial permission checks are restricted to the app's own `app://` origin and the `serial` permission only.
- Version bumps are driven by PR labels, not by manual `npm version`/tagging — see `release-on-merge.yml`'s label mapping (mirrors `release-drafter.yml`'s `version-resolver` convention from the `devflow` skill, even though this repo doesn't use release-drafter itself).
