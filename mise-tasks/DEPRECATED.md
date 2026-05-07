# mise-tasks/ — DEPRECATED in favour of tasks/*.toml (v0.16+)

This directory holds the **legacy file-task implementations** of every
shared task in the joeblew999 mise library. As of v0.16.0 every task
here has a TOML-task counterpart in [`../tasks/`](../tasks/).

## Why both still exist

- **Backwards compatibility** for consumers pinned at `?ref=v0.10.0–v0.15.x`.
  Those revs predate `tasks/*.toml`; mise-tasks/ is the only thing they
  reference.
- **`release`** is intentionally not ported — it's a maintainer-only task
  for tagging this repo's releases (`mise run release -- vX.Y.Z`); not
  consumed by other repos.
- **`_proof/nu-cross-platform.nu`** is referenced by the legacy
  `mise-tasks-lint.yml` workflow as a cross-OS smoke test.

## What you should do

- **New consumers**: use `tasks/*.toml` includes. See [tasks/ci.toml](../tasks/ci.toml)
  for the canonical wiring example. Per-task tools propagate; consumers
  no longer pin gh/jq/wrangler globally.
- **Existing consumers still on the directory include** (`?ref=v0.10.0`
  pointing at `mise-tasks/`): migrate at your convenience. The directory
  pin keeps working; nothing's been deleted. See AGENTS.md for the
  migration recipe.
- **Authoring new tasks**: write them as TOML-tasks in `tasks/<ns>.toml`
  using the `extends = "<ns>:_base"` pattern. Don't add new file-tasks
  to this dir.

## Eventual removal

This directory will be deleted in a future major version (>=v1.0) once
every joeblew999 consumer has been verified on v0.16+ TOML-task includes.
Drift is tracked by `mise run ci:audit-lib-refs`.

## What's covered by the new system

| Legacy file-task path | TOML-task equivalent |
|---|---|
| `mise-tasks/bw/*` | `tasks/bw.toml` (extends `bw:_base`) |
| `mise-tasks/cf/*` | `tasks/cf.toml` (extends `cf:_base`) |
| `mise-tasks/ci/*` | `tasks/ci.toml` (extends `ci:_base`) |
| `mise-tasks/env/resolve` | `tasks/env.toml` |
| `mise-tasks/fnox/init` | `tasks/fnox.toml` |
| `mise-tasks/mise/upgrade` | `tasks/mise.toml` |
| `mise-tasks/mobile/*` | `tasks/mobile.toml` (extends `mobile:_base`) |
| `mise-tasks/prove/*` | `tasks/prove.toml` (extends `prove:_base`) |
| `mise-tasks/rust/*` | `tasks/rust.toml` (extends `rust:_base`) |
| `mise-tasks/secrets/*` | `tasks/secrets.toml` (extends `secrets:_base`) |
| `mise-tasks/wrangler/*` | `tasks/wrangler.toml` (extends `wrangler:_base`) |
| `mise-tasks/release` | (kept here — maintainer-only) |
| `mise-tasks/_proof/` | (kept here — workflow proof fixture) |

Use `mise run ci:check-toml-tasks` (v0.17.5+) to lint every inline
`run = '<TQ>...<TQ>'` body in `tasks/*.toml`.

Use `mise run ci:audit-lib-refs` (v0.19.1+) to detect any `?ref=v...`
URL drift across all your tracked mise.toml files.
