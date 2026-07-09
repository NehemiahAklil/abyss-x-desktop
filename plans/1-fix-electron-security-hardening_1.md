# Plan — Harden Electron Security (Context Isolation, Permissions, Navigation)

**Branch:** fix/electron-security-hardening_1
**Issue:** #1
**Date:** 2026-07-09

## Goal

Bring `index.js`/`preload.js` in line with Electron's official security
checklist: the app was running with `contextIsolation: false`, blanket
permission/device approval, and no navigation or window-open guards.

## Approach

- Enable `contextIsolation: true` and `sandbox: true` on the `BrowserWindow`.
- Since `contextIsolation` blocks the old page-global `eel` stub, replace it
  with `contextBridge.exposeInMainWorld`. `contextBridge` doesn't support
  exposing `Proxy` objects, so the stub was rewritten as a plain object with
  the exact three methods `res/js/control.js` calls (`getDevices`,
  `connectToDevice`, `stopReceivingData`) instead of a generic catch-all Proxy.
- Restrict `setPermissionCheckHandler`/`setDevicePermissionHandler` (and add
  `setPermissionRequestHandler`, which wasn't previously set) to the `serial`
  permission and the app's own `app://` origin only — previously these
  approved every permission/device from any origin.
- Add `setWindowOpenHandler` (deny all popups, open http(s) links externally
  via `shell.openExternal`) and a `will-navigate` guard (block navigation away
  from `app://`, forward http(s) URLs to the OS browser instead).

## Changes

- `index.js` — `contextIsolation: true`, `sandbox: true`, origin-restricted
  permission/device handlers, `setWindowOpenHandler`, `will-navigate` guard.
- `preload.js` — `eel` stub moved from a `window`-global Proxy to
  `contextBridge.exposeInMainWorld`.
- `PROJECT.md` — created (first plan in this repo), documented tech stack and
  directory map.

## Verification

- `node --check index.js` / `node --check preload.js` — pass.
- Launching the app in Electron to confirm the picker overlay still renders
  and `res/js/control.js`'s `eel.*` calls no longer throw was **not**
  possible in this environment (no working Electron binary installed in the
  sandbox). This needs a manual `pnpm start` run on a real machine before
  merge — tracked as an open checkbox on issue #1.
