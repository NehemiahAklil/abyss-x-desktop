# Abyss X [unofficial]

<p align="center">
  <img src="res/icons/256x256.png" width="120" alt="Abyss X logo" />
</p>

<p align="center">
  <a href="https://github.com/NehemiahAklil/nothing-x-desktop/releases/latest">
    <img src="https://img.shields.io/github/v/release/NehemiahAklil/nothing-x-desktop?label=Download&style=flat-square" alt="Latest Release" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-GPL--3.0-blue?style=flat-square" alt="License: GPL-3.0" />
  </a>
  <a href="https://github.com/NehemiahAklil/nothing-x-desktop/issues">
    <img src="https://img.shields.io/github/issues/NehemiahAklil/nothing-x-desktop?style=flat-square" alt="Issues" />
  </a>
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20Windows%20%7C%20macOS-lightgrey?style=flat-square" alt="Platforms" />
</p>

<p align="center">
  An unofficial desktop app for <strong>Nothing &amp; CMF earbuds</strong>.<br />
  Electron wrapper around <a href="https://github.com/radiance-project/ear-web">ear (web)</a> — no browser required.
</p>

---

## Supported devices

| Device | Status |
|---|---|
| Nothing ear (1) | Supported |
| Nothing ear (stick) | Supported |
| Nothing ear (2) | Supported |
| Nothing Ear | Supported |
| Nothing Ear (a) | Supported |
| Nothing Ear (open) | Supported |
| CMF Buds | Supported |
| CMF Buds Pro | Supported |
| CMF Buds Pro 2 | Supported |

## Features

- Battery percentage (buds + case)
- Equalizer — custom EQ and Advanced EQ for compatible devices
- ANC settings (Off / Active / Transparency / Personalized ANC)
- Bass Enhance
- In-Ear Detection, Low Latency Mode, Ear Tip Fit Test
- Gestures
- Find My Earbuds
- Case Battery Status LED (ear (1) only)
- Firmware version display

---

## Installation

### Download a release (recommended)

1. Go to the [Releases page](https://github.com/NehemiahAklil/nothing-x-desktop/releases/latest).
2. Download the file for your platform:

| Platform | File |
|---|---|
| Linux (x64) | `Abyss-X-*-linux-x64.AppImage` |
| Linux (arm64) | `Abyss-X-*-linux-arm64.AppImage` |
| Linux (Debian/Ubuntu) | `Abyss-X-*-amd64.deb` |
| Windows (x64) | `Abyss-X-*-win-x64.exe` |
| macOS (Intel) | `Abyss-X-*-mac-x64.dmg` |
| macOS (Apple Silicon) | `Abyss-X-*-mac-arm64.dmg` |

#### Linux — AppImage
```bash
chmod +x Abyss-X-*.AppImage
./Abyss-X-*.AppImage
```

#### Linux — .deb
```bash
sudo dpkg -i Abyss-X-*-amd64.deb
```

---

## Build from source

### Prerequisites

- [Node.js](https://nodejs.org/) 18+
- [pnpm](https://pnpm.io/) (`npm install -g pnpm`)
- A Chromium-based Electron build environment

```bash
git clone https://github.com/NehemiahAklil/nothing-x-desktop.git
cd nothing-x-desktop
pnpm install
pnpm approve-builds electron electron-builder electron-winstaller
```

### Run (development)

```bash
pnpm start
```

### Build distributables

```bash
# Current platform
pnpm build

# Specific platforms
pnpm build:linux
pnpm build:win
pnpm build:mac

# All platforms (requires cross-compilation tools)
pnpm build:all
```

Output goes to `dist/`.

---

## Usage

1. **Pair your earbuds** in your OS Bluetooth settings first (the app uses the system's Bluetooth stack).
2. Launch Abyss X.
3. Click **Connect** — a picker lists your paired Bluetooth serial devices.
4. Select your earbuds. The app connects and opens the control panel for your device.

### Linux — Bluetooth permissions

On Linux, Web Serial access to Bluetooth SPP ports may require your user to be in the `dialout` group:

```bash
sudo usermod -aG dialout $USER
# Log out and back in for this to take effect.
```

If you see "No paired earbuds found", make sure your buds are paired (not just connected) and appear in `bluetoothctl paired-devices`.

---

## Contributing

Bug reports and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## Credits

- [RapidZapper](https://github.com/radiance-project) — protocol reverse engineering and backend
- [Bendix](https://www.mrbrickstar.de/) — frontend design (ear (web))
- [DerrenGoneDigital](https://twitter.com/DerrenDigital) — logo
- [Radiance Project / ear-web](https://github.com/radiance-project/ear-web) — web frontend bundled in this app
- [Nehemiah Aklil](https://github.com/NehemiahAklil) — Electron wrapper

---

## Legal

This application is published under the [GNU General Public License v3.0](LICENSE).

Nothing Technology Limited or any of its affiliates is a valid licensee and may use this application for any purpose, including commercial purposes, without compensation to the developers.

This app is not affiliated with, sponsored by, or endorsed by Nothing Technology Limited. All product names, logos, and trademarks are property of their respective owners.
