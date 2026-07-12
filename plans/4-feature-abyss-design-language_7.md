# Abyss X Design Language Pass — Nothing X-Inspired UI Redesign

- **Issue:** #7
- **Branch:** `feature/abyss-design-language_7`
- **Type:** Enhancement (UI/UX only — zero functional change)

## Context

The bundled `ear-web` frontend still looked like the upstream web prototype:
mixed inline styles, generic buttons, an invisible EQ curve, and fixed 800×710
device pages clipped inside a 480×820 window. This pass gives the app a
desktop-grade visual identity inspired by the Nothing X mobile app's design
language — dot-matrix display type, monochrome surfaces, a single signal-red
accent, pill controls — rebranded as **Abyss X Desktop**.

## Design system

Original CSS (`res/abyss.css`), using fonts already bundled in `res/fonts`:

| Token | Value | Role |
|---|---|---|
| Canvas | `#0C0C0D` + faint 24px dot grid | window background |
| Surface | `#1B1D1F` | cards — **kept** because `transitions.js` writes it inline |
| Inset | `#0E0F10` | segmented pill tracks |
| Text / Muted | `#F5F5F2` / `#9FA3A8` | copy / labels |
| Accent | `#D71921` | EQ curve, ring buttons, switches-on, hovers |
| Display | AbyssDot (ndot_55) | product names, wordmark |
| Label | AbyssMono (lettera mono) | uppercase letter-spaced eyebrows |
| Body | AbyssSans (Space Grotesk) | everything else |

Key hook: card headers already carried the undefined class `.text-md` — it now
defines the uppercase mono eyebrow style across all pages and popups.

## Changes

- `res/abyss.css` — **new** design-system stylesheet (tokens, fonts with
  correct `.otf` paths — upstream's `NothingNormal` face pointed at a
  nonexistent `.ttf` — cards, buttons, switches, battery bars, popups,
  scrollbars, focus states).
- `res/index.html` — welcome screen redesigned (Ndot wordmark + red dot,
  mono-caps DESKTOP sublabel, outline→red-fill Connect pill, FAQ as flat
  cards with +/− markers); same IDs/handlers/script logic.
- `res/MainControl_*.html` (10 files) — linked `abyss.css`, removed inline
  body background, swapped font aliases (`NothingNormal2`→`AbyssSans`,
  `Ndot-55`→`AbyssDot`), retitled to "Abyss X Desktop".
- `res/js/eq_one|two|sticks|cleffa|corsola|donphan|espeon.js` — chart
  visuals only: signal-red curve (`#D71921`, width 2, tension 0.4), red
  gradient fill; identical data/presets/handlers.
- `preload.js` — Web Serial port-picker overlay restyled to the system.
- `index.js` — window 840×790 (pages no longer clipped), background
  `#0C0C0D`.

## Constraints honored

- No functional change: every element ID, onclick handler, and JS-toggled
  inline style is untouched; the white-active/dark-inactive scheme JS writes
  inline is embraced by the design rather than fought.
- Device product names ("Nothing Ear (a)" …) and the legal disclaimer keep
  their factual references; only app self-branding says "Abyss X Desktop".
- `res/` is no longer byte-identical with upstream `ear-web` — it now
  carries the Abyss X design layer (PROJECT.md updated accordingly).
