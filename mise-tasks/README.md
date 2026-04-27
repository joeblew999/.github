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

## Pinning

Always pin to a tag in production:

```toml
"git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.1.0"
```

Use `ref=main` on local dev only. Bump the tag intentionally when tasks change.

## Cache

```bash
mise cache clear   # force re-fetch after bumping ref
```

Set `MISE_TASK_REMOTE_NO_CACHE=true` to always fetch latest (slow, CI use only).
