# Plan — Release-on-merge tag push doesn't trigger build.yml

**Branch:** fix/release-workflow-dispatch-trigger_5
**Issue:** #5
**Date:** 2026-07-09

## Goal

`release-on-merge.yml` (from #4) bumped the version, tagged `v0.1.1`, and
pushed it — but `build.yml` never ran, so no release was created and no
artifacts were attached, even though `build.yml` listens on `push: tags: 'v*'`.

## Approach

Root cause: GitHub Actions has a built-in anti-recursion guard — pushes made
using the default `GITHUB_TOKEN` (as `release-on-merge.yml`'s checkout/push
steps do) don't trigger other workflow runs. `workflow_dispatch` and
`repository_dispatch` are explicit, documented exceptions to that rule.
Verified this both ways: `gh run list` showed zero `Build & Release` runs for
the `v0.1.1` tag, and manually running
`gh workflow run build.yml --ref v0.1.1 -f draft=false` immediately started
one (and produced a correct release with all 7 platform assets attached).

Fix: after the tag push, `release-on-merge.yml` now explicitly dispatches
`build.yml` via `gh workflow run` instead of relying on the tag-push cascade.
`-f draft=false` is required because `workflow_dispatch`'s `draft` input
defaults to `true` — without it, the dispatched run would leave the release
as an unpublished draft.

## Changes

- `.github/workflows/release-on-merge.yml` — added `actions: write`
  permission and a "Trigger release build" step calling
  `gh workflow run build.yml --ref v<version> -f draft=false` after the tag
  push.

## Verification

- YAML parses cleanly.
- The dispatch mechanism itself was already proven manually for `v0.1.1`
  (this PR's fix reproduces exactly that command from within CI). Full
  automated end-to-end verification happens on this PR's own merge, if
  labeled release-worthy.
