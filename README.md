# joeblew999/.github

Meta-repository for the `joeblew999` GitHub organisation.

## What lives here

| Path | Purpose |
|---|---|
| `mise-tasks/` | Shared mise task library — consumed by all repos via `[task_config].includes` |
| `profile/` | Org profile page shown at [github.com/joeblew999](https://github.com/joeblew999) |
| `.claude/` | Claude Code skills and agents shared across projects |
| `.github/` | Org-level GitHub config (CODEOWNERS, issue templates, dependabot, welcome workflow) |

## Using the shared task library

Add to any repo's `mise.toml`:

```toml
[task_config]
includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.3.0"]
```

See [mise-tasks/README.md](mise-tasks/README.md) for the full task list and wiring guide.

## Cross-platform local dev (utm-dev)

For repos that target Windows or Linux (Tauri apps, native builds), include [utm-dev](https://github.com/joeblew999/utm-dev) alongside this library. utm-dev manages UTM VMs on Apple Silicon so you can build and test on Windows 11 and Linux without leaving your Mac.

mise does not chain `git::` includes, so both must be listed explicitly:

```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.3.0",
  "git::https://github.com/joeblew999/utm-dev.git//.mise/tasks?ref=v2.1.0",
]
```

This gives you all CI/CD tasks (`wrangler:*`, `secrets:*`, `rust:*`, `cf:*`) plus all platform tasks (`windows:build`, `linux:build`, `linux:dev`, `mac:dev`, `ios:sim`, `android:sim`, etc.).
