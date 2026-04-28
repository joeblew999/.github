# mise-tasks

Reusable mise task library for joeblew999 projects.

## Usage

Add to your project's `mise.toml`:

```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.2.0"
]
```

Then run:

```bash
mise install          # install tools
mise tasks ls         # verify tasks loaded
```

## Available Tasks

### Build / dev / deploy

| Task | Description |
|------|-------------|
| `rust:build` | `cargo build --all-targets` |
| `rust:test` | `cargo test --all-targets` |
| `rust:wasm-pack` | Compile Truck kernel to WASM via wasm-pack |
| `wrangler:dev` | Local dev (multi-worker) |
| `wrangler:deploy` | Deploy to Cloudflare Workers |
| `cf:d1-migrate` | Run D1 migrations |

### Secrets / fnox

These assume fnox + macOS Keychain (or the equivalent OS keystore on
Linux/Windows). They are dev-only — CI never runs fnox; CI reads
secrets from GitHub Actions repo settings, which `secrets:sync-github`
populates from a dev machine.

| Task | Description |
|------|-------------|
| `fnox:init` | Bootstrap a fresh dev's `~/.config/fnox/config.toml` with a keychain provider (no age key, no plaintext secrets in config) |
| `secrets:status` | Show fnox secrets + the current repo's GitHub Actions secrets |
| `secrets:sync-github` | Push secrets from fnox → current repo's GitHub Actions secrets. Requires `FNOX_SYNC_KEYS=A,B,C` in the consuming repo's `mise.toml [env]` |
| `secrets:sync-github-dry` | Dry-run of `secrets:sync-github` (shows plan, changes nothing) |
| `secrets:migrate-to-keychain` | One-shot migration: move any `provider = "age"` entries in the global fnox config to the keychain provider. Idempotent; safe to re-run |

#### Wiring `secrets:sync-github` in a consuming repo

```toml
# repo's mise.toml
[task_config]
includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.2.0"]

[env]
FNOX_SYNC_KEYS = "CLOUDFLARE_API_TOKEN,GITHUB_TOKEN,TAURI_SIGNING_PRIVATE_KEY"
```

The shared task auto-detects the current repo via `gh repo view --json nameWithOwner`,
so the same task body works for all consumers.

## Adding a new task

1. Create `mise-tasks/<namespace>/<task-name>` with a shebang + MISE description header:
   ```bash
   #!/usr/bin/env bash
   #MISE description="one-line description"
   set -euo pipefail
   ```
2. `chmod +x mise-tasks/<namespace>/<task-name>` — mise silently skips non-executable files
3. Test: `mise tasks ls` from this repo (the root `mise.toml` includes `mise-tasks/` directly)
4. Update the task table above
5. Release: `mise run release -- vX.Y.Z`

### Gotcha: no `${#array[@]}` in task scripts

mise pre-processes scripts with the Tera template engine. `{#` opens a Tera comment block,
swallowing everything until `#}`. Use `wc -l` or `IFS=',' read -ra ARR` instead.

## Releasing

```bash
mise run release -- v0.3.0
```

Then in consuming repos: bump `?ref=v0.3.0` and run `mise cache clear`.

## Pinning

Always pin to a tag in production:

```toml
"git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.2.0"
```

Use `ref=main` on local dev only. Bump the tag intentionally when tasks change.

## Cache

```bash
mise cache clear   # force re-fetch after bumping ref
```
