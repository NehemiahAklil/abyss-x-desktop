# Plan — Automate Issue Closing And Release Tagging On PR Merge

**Branch:** chore/release-and-issue-automation_3
**Issue:** #3
**Date:** 2026-07-09

## Goal

Remove two manual steps from the release process: someone previously had to
push/move a `v*` tag by hand to trigger `build.yml`, and issues never closed
automatically when their PR merged.

## Approach

Picked two workflows from `~/Projects/mmcy/MMCY-Agent-Skills/skills/git-workflow/assets/github/workflows/`
(already partly vendored in this repo as `.claude/skills/devflow/assets/github/`)
and adapted them to this repo's shape:

- **`manage-issues.yml`** — installed unmodified. It has no branch filter, so
  it works regardless of default branch name. On a merged PR it scans commit
  messages for `#<issue>` references and closes each issue whose checkboxes
  are all ticked and which has no other open PR referencing it.
- **`release.yml`** from mmcy assumes a release-drafter + manual "Publish"
  label model (drafts release notes progressively, publishes a draft when a
  merged PR carries "Publish"). That doesn't fit this repo: `build.yml`
  already builds real installers and creates the final GitHub Release itself,
  triggered only by an actual `v*` tag push. Instead of adopting that model,
  wrote a new **`release-on-merge.yml`**:
  - Triggers on `pull_request: closed` into `master`.
  - Gate (per discussion): only proceeds if the merged PR carries a
    release-worthy label — `Feature`, `Bug`, `Hot Fix`, `Enhancement`, or
    `Security`. `Task`/`Dev Task`/docs/chore merges are skipped, so trivial
    PRs don't trigger a full 3-platform build.
  - Version bump resolved from labels using the same mapping as
    `release-drafter.yml`'s `version-resolver`: `Major` → major;
    `Feature`/`Enhancement`/`Dev Task`/`Dev Process Optimization` → minor;
    everything else in the release-worthy set → patch.
  - Bumps `package.json` (`npm version <bump> --no-git-tag-version`), commits,
    tags `v<version>`, and pushes both to `master`. The tag push is a real
    `git push`, which fires `build.yml`'s existing `on: push: tags: 'v*'`
    trigger automatically — no explicit "run the build workflow" step needed.
  - Deliberately does **not** add `[skip ci]` to the release commit: the tag
    that triggers `build.yml` points at that same commit, and GitHub's
    skip-ci detection applies per-commit regardless of ref type — a
    `[skip ci]` marker would have silently suppressed the very build the tag
    push is meant to trigger.

Created the label set both workflows depend on (`Major`, `Feature`, `Bug`,
`Hot Fix`, `Enhancement`, `Dev Task`, `Task`, `Security`) via `gh label
create --force`, matching `devflow`'s `repo-setup.md`. The repo's pre-existing
default GitHub labels (lowercase `bug`, `enhancement`, etc.) are left as-is,
unused going forward.

## Changes

- `.github/workflows/manage-issues.yml` — new, copied unmodified from the
  devflow/mmcy asset.
- `.github/workflows/release-on-merge.yml` — new, repo-specific version-bump
  + tag + push automation.
- GitHub labels — added `Major`, `Feature`, `Bug`, `Hot Fix`, `Enhancement`,
  `Dev Task`, `Task`, `Security`.

## Verification

- Both workflow YAML files parse cleanly (`yaml.safe_load`).
- Dry-ran the bump-resolution shell logic locally against every label
  combination in the mapping (`Major`+`Feature` → major, `Feature`/
  `Enhancement` → minor, `Bug`/`Hot Fix`/`Security`/`Task` → patch) — all
  correct.
- End-to-end verification (a real PR merge triggering the tag push and
  `build.yml`) can only happen once this PR itself is merged with a
  release-worthy label — left as a follow-up check, not blocking.
