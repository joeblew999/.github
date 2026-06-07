# joeblew999/.github

Meta-repository for the `joeblew999` GitHub organisation.

## What lives here

| Path | Purpose |
|---|---|
| `tasks/` | **Shared TOML-task library** — consumed via `[task_config].includes` of individual files. Tasks pin no tool versions; ubiquitous tools come from your global mise config. |
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
  "git::https://github.com/joeblew999/.github.git//tasks/ci.toml?ref=v0.25.0",
  "git::https://github.com/joeblew999/.github.git//tasks/secrets.toml?ref=v0.25.0",
  "git::https://github.com/joeblew999/.github.git//tasks/cf.toml?ref=v0.25.0",
  # ...whichever namespaces you need
]
```

Tasks pin no tool versions. Ubiquitous tools (nushell, fnox, gh, jq, git-cliff, …) live in your **global** mise config — run `mise run mise:global-sync --write` from `.github` to set the canonical set; your repo `[tools]` declares only repo-specific tools.

Available namespaces: `bw`, `cf`, `ci`, `cliff`, `env`, `fnox`, `mise`, `mobile`, `prove`, `rust`, `secrets`, `wrangler`. See [tasks/](tasks/) for the source.

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
  "git::https://github.com/joeblew999/.github.git//tasks/ci.toml?ref=v0.25.0",
  "git::https://github.com/joeblew999/utm-dev.git//.mise/tasks?ref=v2.1.0",
]
```
