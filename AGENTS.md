# Agent Guidelines: joeblew999/.github

A **shared mise task library** for all `joeblew999` projects, plus GitHub org
config. Consumers pull task namespaces by tag via `[task_config].includes`.

## ⚠ Read this first — the model (v0.20+)

- **Tasks are TOML** under `tasks/<ns>.toml`, one file per namespace. Each task's
  `run = '''#!/usr/bin/env nu …'''` body is nushell. (The old file-task tree under
  `mise-tasks/` was removed in v0.25.0 — everything is TOML now.)
- **The GLOBAL mise config (`~/.config/mise/config.toml`) is the source of truth
  for the common toolset** — lightweight CLIs every task fronts: nushell, fnox,
  gh, jq, usage, git-cliff, wrangler, `@bitwarden/cli`. Repos' `[tools]` declare
  only repo-specific tools; tasks pin NOTHING for these. This kills drift.
- **Exception — heavy/niche toolchains stay per-task** in the namespace that
  fronts them: `mobile:*` (java/ruby/cocoapods/tauri-cli) and `rust:*`
  (wasm-pack). They install only when those tasks run — NOT in the universal
  global set (e.g. cocoapods is a fragile gem that must not break every task).
- **CI parity:** the `reusable-mise-ci.yml` workflow seeds the runner's global
  config the same way (`mise:global-sync --write` from `.github` at `lib-ref`),
  so consumer CI inherits the common tools exactly like a local machine.
- **Common tools float to `latest`** (v0.24.0). The lib carries no version strings
  except two deliberate toolchain pins: `java` (temurin-17, Android NDK) and
  `ruby` (3.3, CocoaPods). NEVER per-task-pin a ubiquitous tool — it installs
  duplicate backends/versions and breaks the mise GUI.
- **Canonical specs = registry short-names** (`fnox`, `gh`, `jq`, `usage`,
  `git-cliff`, `wrangler`). `nushell` has no short-name → `github:nushell/nushell`.
  Forks keep their backend (`github:joeblew999/http-nu`, …).

## What lives here

| Path | Purpose |
|---|---|
| `tasks/<ns>.toml` | TOML-task definitions. Namespaces: `bw cf ci cliff env fnox mise mobile prove rust secrets wrangler`. Consumed via `git::….toml?ref=vX.Y.Z`. |
| `mise.toml` | Self-includes every `tasks/*.toml` (so CI lints the lib against itself) + the canonical `[tools]`. |
| `.github/workflows/tasks-toml-proof.yml` | CI canary — discovery + scoping + real-file validation per `tasks/*.toml`. 3 OS (ubuntu/macos/windows). |
| `.github/workflows/reusable-mise-ci.yml` / `reusable-mise-upgrade.yml` | Reusable workflows consumers `uses:`. |
| `profile/`, `.claude/` | Org profile page; Claude Code skills/agents. |

## Key shared tasks

- `mise:global-sync [--write]` — align the global config to a repo's `[tools]`
  (report-only by default). Run from `.github` to set the canonical global set.
- `mise:sweep` — prune orphaned tool installs across repos (auto-reinstall, safe).
- `mise:upgrade` — `mise upgrade --bump --local` (never touches global).
- `mise:release -- vX.Y.Z` — tag + push a release of THIS lib (local; no CI/goreleaser).
- `cliff:*` — git-cliff changelog/release intel; `cliff:repo <owner/repo>` shows
  any upstream's unreleased delta (defaults to latest semver tag).
- `ci:*` — `parse-check`, `check-toml-tasks`, `check-workflow-nu`, `audit-lib-refs`.
- `cf:* / bw:* / secrets:* / prove:* / fnox:* / wrangler:* / rust:* / mobile:*` — domain tasks.

## Nushell authoring gotchas

- Interpolation: `$"… ($var) …"` is a variable; `$"… \(literal\) …"` is literal
  parens. **Don't** write `$"text (literal)"` — nu reads `(literal` as a subexpr.
- Lists need commas: `["a", "b"]` not `[a b]`. `sort` doesn't dedupe → `sort | uniq`.
- Parse-check is `nu --ide-check 1 <file>` (NOT `--check`). Quote namespaced keys:
  `["bw:list"]`, not `[bw:list]`.
- Repo detection: `git remote get-url origin` (not `gh repo view` — follows forks).
  Regex `[^/]+?` (allows the dot in `joeblew999/.github`).
- `unset FNOX_AGE_KEY` defensively in any task touching fnox (Claude Code leaks
  `FNOX_AGE_KEY=undefined` into IDE shells).

## Adding / changing a task

1. Edit the right `tasks/<ns>.toml`; body is `run = '''#!/usr/bin/env nu … '''`.
2. **No version pins for ubiquitous tools** — they come from global. Only declare
   genuinely task-specific tools (`wrangler`, `@bitwarden/cli`, `java`, …).
3. `mise run ci:check-toml-tasks` (+ `ci:parse-check`, `ci:check-workflow-nu`) must pass.
4. Update `CHANGELOG.md`, commit to `main`, then `mise run mise:release -- vX.Y.Z`.
5. Consumers bump `?ref=vX.Y.Z` deliberately (no forced upgrades).

## Invariants (keep this repo clean)

- Every task body parse-clean on linux/macos/windows (`tasks-toml-proof.yml`).
- Reusable workflows ride the same tag stream as the tasks — bump `@vX.Y.Z` in
  lockstep with `[task_config].includes` `?ref=`.
- `?ref=` example versions in README/AGENTS stay current with the latest tag.

## Consuming-repo wiring

```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//tasks/cliff.toml?ref=v0.27.0",
  "git::https://github.com/joeblew999/.github.git//tasks/ci.toml?ref=v0.27.0",
  # one URL per namespace file — mise does NOT chain git:: includes.
]

[tools]
# ONLY repo-specific tools. Ubiquitous ones (nushell, fnox, gh, …) come from the
# global config — run `mise run mise:global-sync --write` from .github to set it.
opentofu = "1.12.1"
```

Reusable CI (one-line consumer CI):
```yaml
jobs:
  ci:
    uses: joeblew999/.github/.github/workflows/reusable-mise-ci.yml@v0.27.0
    with: { task: check, lib-ref: v0.27.0 }   # lib-ref seeds the global toolset on the runner
```

## Secrets model

- `fnox` = canonical local store (macOS Keychain / Windows Cred Manager / Linux
  secret-service). `fnox set` ALWAYS with `-p keychain`.
- `bw` (Bitwarden CLI, self-hosted NodeWarden) = cloud side; `bw:*` does the
  keychain ↔ NodeWarden sync. `FNOX_SYNC_KEYS` lists which keys push to GH Actions
  secrets (`secrets:sync-github`). CI never runs fnox — it reads GH Actions secrets.
