# Contributing to Abyss X

Thanks for taking the time to contribute!

## Reporting bugs

Open an issue at https://github.com/NehemiahAklil/nothing-x-desktop/issues and include:

- OS and version (e.g. Ubuntu 24.04, Windows 11)
- App version (shown in the title bar or Help → About)
- Your device model (e.g. CMF Buds Pro 2)
- Steps to reproduce
- What you expected vs. what happened
- Any errors from the DevTools console (`Ctrl+Shift+I`)

## Development setup

```bash
git clone https://github.com/NehemiahAklil/nothing-x-desktop.git
cd nothing-x-desktop
pnpm install
pnpm approve-builds electron
pnpm start
```

Open DevTools with `Ctrl+Shift+I` to inspect the renderer. Main-process logs appear in the terminal.

## Project structure

```
index.js      — Electron main process: app:// protocol, Web Serial wiring
preload.js    — Renderer bridge: Bluetooth device picker UI, eel stub
res/          — The ear (web) frontend (upstream: radiance-project/ear-web)
build/        — Icons for packaging (generated; do not hand-edit)
```

## Updating the bundled ear (web) frontend

The `res/` directory is a verbatim copy of https://github.com/radiance-project/ear-web/tree/main/res.
To update it, copy the upstream `res/` folder over this one. Do not modify files inside `res/` in this repo — upstream changes should flow from the ear-web repo.

If you need to patch renderer behaviour (e.g. Electron-specific fixes), do it in `preload.js` so the `res/` copy stays clean.

## Submitting a pull request

1. Fork the repo and create a branch off `master`.
2. Keep changes focused — one fix or feature per PR.
3. Test on your local machine with `pnpm start`.
4. Open the PR and describe what changed and why.

## Code style

- Main process: plain CommonJS, no transpilation.
- Preload: CommonJS with `ipcRenderer` — keep it minimal.
- No bundler, no TypeScript — keep the build simple.
