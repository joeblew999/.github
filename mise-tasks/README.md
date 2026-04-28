# mise-tasks

Reusable mise task library for joeblew999 projects.

## Usage

Add to your project's `mise.toml`:

```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.4.0"
]
```

Then run:

```bash
mise install          # install tools (includes cargo:usage-cli for tab-completion)
mise tasks ls         # verify tasks loaded
```

### With utm-dev (cross-platform builds — Windows / Linux VMs)

For Tauri apps or anything that needs Windows 11 / Linux builds on Apple Silicon, include
[utm-dev](https://github.com/joeblew999/utm-dev) alongside:

```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.4.0",
  "git::https://github.com/joeblew999/utm-dev.git//.mise/tasks?ref=v2.1.0",
]
```

utm-dev adds `windows:build`, `linux:build`, `linux:dev`, `mac:dev`, `ios:sim`,
`android:sim`, and more. mise does not chain `git::` includes, so both must be listed.

Once utm-dev is rewritten as a Rust CLI (`cargo:utm-dev`), the `vm:*` tasks below
will be available via this library alone — no second include needed.

## Available Tasks

### Release

| Task | Description |
|------|-------------|
| `release` | Tag and push a new semver release — `mise run release -- v0.4.0` |

### Build / dev / deploy

| Task | Description |
|------|-------------|
| `rust:build` | `cargo build --all-targets` |
| `rust:test` | `cargo test --all-targets` |
| `rust:wasm-pack <crate-dir>` | Compile a Rust crate to WASM via wasm-pack |
| `wrangler:dev` | Local dev (multi-worker) |
| `wrangler:deploy` | Deploy to Cloudflare Workers |
| `wrangler:tail [--env <env>]` | Tail live logs from a deployed Worker (default: production) |
| `wrangler:secret-list [--env <env>]` | List secrets set on a deployed Worker (values hidden) |
| `cf:d1-migrate` | Run D1 migrations |
| `cf:token-check` | Verify `CLOUDFLARE_API_TOKEN` is valid — reads from env or fnox |

### Secrets / fnox

These are dev-only — CI never runs fnox; CI reads secrets from GitHub Actions repo
settings, which `secrets:sync-github` populates from a dev machine.

| Task | Description |
|------|-------------|
| `fnox:init` | Bootstrap fnox with a keychain provider (no age key, no plaintext secrets) |
| `secrets:status` | Show fnox secrets + the current repo's GitHub Actions secrets |
| `secrets:sync-github [--dry-run]` | Push secrets from fnox → GitHub Actions. Requires `FNOX_SYNC_KEYS` in `mise.toml [env]` |
| `secrets:sync-github-dry` | Alias for `secrets:sync-github --dry-run` |
| `secrets:migrate-to-keychain` | Migrate any age-encrypted fnox secrets → OS keychain. Idempotent |

#### Wiring `secrets:sync-github` in a consuming repo

```toml
[task_config]
includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.4.0"]

[env]
FNOX_SYNC_KEYS = "CLOUDFLARE_API_TOKEN,GITHUB_TOKEN,TAURI_SIGNING_PRIVATE_KEY"
```

The shared task auto-detects the current repo via `git remote get-url origin`,
so the same task body works for all consumers including forks.

### vm: namespace (planned — pending utm-dev Rust CLI)

Once [utm-dev](https://github.com/joeblew999/utm-dev) is rewritten as a Rust binary,
these tasks will be added here as thin wrappers around `cargo:utm-dev`:

| Task | Description |
|------|-------------|
| `vm:up [--name <vm>]` | Start a VM (imports + bootstraps on first run) |
| `vm:down [--name <vm>]` | Stop a VM |
| `vm:build [--name <vm>]` | Build app in VM (auto-starts if needed) |
| `vm:exec [--name <vm>] <cmd>` | Run a command in a VM via SSH |
| `windows:build` | Build Windows .msi/.exe in VM |
| `linux:build` | Build Linux .deb/.AppImage in VM |
| `linux:dev` | Start Linux desktop VM |

Until then: include utm-dev TypeScript tasks separately (see above).

## Adding a new task

1. Create `mise-tasks/<namespace>/<task-name>` with a shebang + MISE + USAGE headers:
   ```bash
   #!/usr/bin/env bash
   #MISE description="one-line description"
   #USAGE arg "<name>" help="description of the argument"
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
mise run release -- v0.5.0
```

Then in consuming repos: bump `?ref=v0.5.0` and run `mise cache clear`.

## Pinning

Always pin to a tag in production:

```toml
"git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.4.0"
```

Use `ref=main` on local dev only. Bump the tag intentionally when tasks change.

## Cache

```bash
mise cache clear   # force re-fetch after bumping ref
```
