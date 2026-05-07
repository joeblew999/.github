# joeblew999/.github

Meta-repository for the `joeblew999` GitHub organisation.

## What lives here

| Path | Purpose |
|---|---|
| `tasks/` | **Shared TOML-task library (v0.16+)** — consumed via `[task_config].includes` of individual files. Per-task tool pins propagate. |
| `mise-tasks/` | Legacy file-task library (v0.10–v0.15.x consumers). [Deprecated](mise-tasks/DEPRECATED.md) — preserved for back-compat, no new tasks. |
| `.github/workflows/` | Reusable workflows: `reusable-mise-ci.yml`, `reusable-mise-upgrade.yml`. Plus self-proof CI (`tasks-toml-proof.yml`). |
| `CHANGELOG.md` | Per-release notes — read before bumping a consumer's `?ref=` pin. |
| `AGENTS.md` | Authoring + release guide. SSOT for Claude/Cursor/Copilot in this repo and the canonical pointer target for branch-local `AGENTS.md` files in consumers. |
| `profile/` | Org profile shown at [github.com/joeblew999](https://github.com/joeblew999). |
| `.claude/` | Claude Code skills shared across projects. |

## Using the shared task library

In any consumer repo's `mise.toml` — include the specific TOML files you want, pinned by tag:

```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//tasks/ci.toml?ref=v0.19.1",
  "git::https://github.com/joeblew999/.github.git//tasks/secrets.toml?ref=v0.19.1",
  "git::https://github.com/joeblew999/.github.git//tasks/cf.toml?ref=v0.19.1",
  # ...whichever namespaces you need
]
```

Per-task tool pins (gh, jq, wrangler, fnox, nu, …) come along for the ride — consumers don't pin them globally.

Available namespaces: `bw`, `cf`, `ci`, `env`, `fnox`, `mise`, `mobile`, `prove`, `rust`, `secrets`, `wrangler`. See [tasks/](tasks/) for the source.

### Lint your own tasks locally

Two shared CI tasks lint nu code embedded in TOML/YAML — same checks, sub-second feedback vs. waiting on Actions:

```bash
mise run ci:check-toml-tasks    # lints every run='''…''' body in tasks/*.toml
mise run ci:check-workflow-nu   # lints every nu block in .github/workflows/*.yml
```

Wire them into a local `[tasks.check]` aggregator — see `AGENTS.md` for the canonical recipe.

### Detect drift across all your repos

```bash
mise run ci:audit-lib-refs   # warns if any tracked mise.toml pins a stale ?ref=
```

## Cross-platform local dev (utm-dev)

For repos targeting Windows or Linux (Tauri apps, native builds), pair this with [utm-dev](https://github.com/joeblew999/utm-dev). It manages UTM VMs on Apple Silicon for cross-OS builds without leaving your Mac.

mise does not chain `git::` includes, so list both explicitly:

```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//tasks/ci.toml?ref=v0.19.1",
  "git::https://github.com/joeblew999/utm-dev.git//.mise/tasks?ref=v2.1.0",
]
```
