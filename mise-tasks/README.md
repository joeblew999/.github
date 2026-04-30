# mise-tasks

Reusable mise task library for joeblew999 projects.

## Usage

Add to your project's `mise.toml`:

```toml
[tools]
"cargo:utm-dev" = { git = "https://github.com/joeblew999/utm-dev-cli.git" }

[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.7.0"
]
```

Then run:

```bash
mise install          # install tools (includes cargo:usage-cli + cargo:utm-dev)
mise tasks ls         # verify tasks loaded — vm:up, vm:down, vm:exec, vm:ls, vm:build
```

`cargo:utm-dev` will be pinned to a semver once published to crates.io.
Until then the git source is used; add a commit SHA after `?rev=` to pin exactly.

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

### Cloudflare ops-tool deploy lifecycle

For forks of admin/ops Workers (e.g. [d1-manager](https://github.com/joeblew999/d1-manager), [kv-manager](https://github.com/joeblew999/kv-manager)) — these tasks together replace ~250 lines of inline mise.toml per fork.

| Task | Description | Required in `config/<env>.env` |
|------|-------------|---|
| `env:resolve` | (hidden) Returns path to `config/<env>.env`. Default env is `production`; switch via `MISE_ENV=staging` or `-- --env staging` | (none — used internally by every task below) |
| `wrangler:gen` | `envsubst < wrangler.toml.template > wrangler.toml`. Reads per-fork values via `env:resolve`. | (variables referenced by your `wrangler.toml.template`) |
| `cf:provision-d1-r2` | Idempotent: create the metadata D1 + backup R2 bucket. Writes `METADATA_DB_ID` back into the env file. Applies `worker/schema.sql` if present. | `METADATA_DB_NAME`, `BACKUP_BUCKET_NAME` |
| `cf:access-setup` | Idempotent: ensure the GitHub IdP UUID is known (from fnox cache or any existing app), find or create the Access App for `${WORKER_NAME}.${CF_SUBDOMAIN}.workers.dev`, ensure an allow-by-email policy for `${OPERATOR_EMAIL}`, write `CF_ACCESS_TEAM_DOMAIN` and the per-app AUD to fnox. | `WORKER_NAME`, `CF_SUBDOMAIN`, `APP_POLICY_AUD_FNOX_KEY` (e.g. `D1_MANAGER_POLICY_AUD`); `OPERATOR_EMAIL` optional but recommended |
| `cf:secrets-put-mapped` | Push 4 fnox keys to Worker secret store, mapping canonical fnox names → expected Worker env names: `CLOUDFLARE_ACCOUNT_ID → ACCOUNT_ID`, `CLOUDFLARE_API_TOKEN → API_KEY`, `CF_ACCESS_TEAM_DOMAIN → TEAM_DOMAIN`, `${APP_POLICY_AUD_FNOX_KEY} → POLICY_AUD` | `APP_POLICY_AUD_FNOX_KEY` |

### Verification (`prove:*`)

Drop these into a fork's `prove:all` to verify a deploy is healthy.

| Task | Description |
|------|-------------|
| `prove:deployed` | curl the deployed URL, expect 302 to CF Access challenge URL with the AUD stored in `fnox:${APP_POLICY_AUD_FNOX_KEY}` |
| `prove:access-policy` | CF API: confirm the Access App for the Worker's URL has at least one allow policy. Without one, login 403s after OAuth. |
| `prove:bindings` | `wrangler deploy --dry-run` and list resolved bindings. Catches drift between `wrangler.toml.template` and the resources actually provisioned. |
| `prove:secrets` | `wrangler secret list` and assert all four standard secrets are present (`ACCOUNT_ID`, `API_KEY`, `TEAM_DOMAIN`, `POLICY_AUD`). For forks with different secret names, write your own. |

#### Wiring `prove:all` in a consuming fork

```toml
[task_config]
includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.7.0"]

[tasks."prove:all"]
description = "Run every prove:* check in order. Fails fast on first miss."
depends     = ["prove:deployed", "prove:access-policy", "prove:bindings", "prove:secrets"]
run         = "echo '✓ all checks passed.'"
```

#### Operator-shared fnox keys

These four keys live in fnox once per operator (machine), reused across every fork that consumes the deploy lifecycle above:

| fnox key | Set by | Notes |
|---|---|---|
| `CLOUDFLARE_API_TOKEN` | operator (one-time, from CF dashboard) | Needs scopes: `Workers Scripts/D1/R2/KV: Edit`, `Account Settings: Read`, `Access: Apps and Policies: Edit`, `Access: Organizations: Read` |
| `CLOUDFLARE_ACCOUNT_ID` | operator (one-time) | |
| `CF_ACCESS_TEAM_DOMAIN` | `cf:access-setup` (auto) | `https://<team>.cloudflareaccess.com` |
| `CF_ACCESS_GITHUB_IDP_ID` | `cf:access-setup` (auto, on first run) | UUID of the GitHub OAuth IdP. Must exist once per CF Zero Trust account before this task runs. |

App-specific (one per fork): `D1_MANAGER_POLICY_AUD`, `KV_MANAGER_POLICY_AUD`, etc. — whatever name the fork puts in `APP_POLICY_AUD_FNOX_KEY`. Set automatically by `cf:access-setup`.

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
includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.7.0"]

[env]
FNOX_SYNC_KEYS = "CLOUDFLARE_API_TOKEN,GITHUB_TOKEN,TAURI_SIGNING_PRIVATE_KEY"
```

The shared task auto-detects the current repo via `git remote get-url origin`,
so the same task body works for all consumers including forks.

### vm: namespace

Thin wrappers around `cargo:utm-dev` — the [utm-dev-cli](https://github.com/joeblew999/utm-dev-cli)
Rust binary. Handles UTM VM lifecycle for cross-platform Tauri builds on Apple Silicon.

| Task | Description |
|------|-------------|
| `vm:up <name>` | Start VM (downloads box + bootstraps on first run, just starts otherwise) |
| `vm:down <name>` | Stop a VM |
| `vm:exec <name> <cmd>` | Run a command in a VM via SSH (exit code mirrors remote) |
| `vm:ls` | List all VM profiles and their saved state |
| `vm:build <name> [--release]` | Build the project inside the VM (auto-starts if needed) |

Profiles: `windows-build`, `windows-test`, `linux-build`, `linux-test`, `linux-dev`

**First run for a profile:** downloads the `.box` from `$UTM_BOX_BASE/{name}.box`, extracts
the `.utm` bundle, imports via AppleScript, configures port-forwards, starts, and runs
the Linux bootstrap (apt deps + mise + Rust). Subsequent runs just start the VM.

State is stored per-project in `.mise/state/vm-{name}.json`.

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
mise run release -- v0.X.Y
```

This validates: on `main`, clean tree, semver tag format, tag doesn't already exist. Then tags + pushes.

Bump the **minor** when adding tasks that consumers will want. Bump **patch** for fixes that don't change behaviour. Bump **major** if you rename a task or change required inputs (i.e. break consumers).

Consuming repos: bump `?ref=vX.Y.Z` in their `mise.toml`, then run `mise cache clear`.

## Conventions

1. **One file per task.** Filename uses dashes within names; directory name becomes the namespace. e.g. `mise-tasks/cf/access-setup` → task `cf:access-setup`.
2. **Required inputs declared at top.** Use `: "${VAR:?explanation}"` — fails fast with a clear message rather than silently producing wrong output. The task description should also list them.
3. **Idempotent where it matters.** Tasks that mutate cloud state (cf:provision-d1-r2, cf:access-setup) must be safe to re-run. Read-modify-write tasks (cf:secrets-put-mapped) overwrite — that's by design.
4. **Bash strict mode.** Every task starts with `set -euo pipefail`.
5. **No `${#array[@]}`** — see Gotcha above.
6. **Temp files for big API responses** — see Gotcha below.

### Gotcha: bash variables corrupt JSON with raw `\r`

Some Cloudflare API responses (Access apps with TLS-mTLS certs) embed raw `\r` characters in JSON string values. The JSON spec is permissive about this but jq is strict, and bash variable round-tripping (`out=$(curl ...); echo "$out" | jq ...`) further mangles the bytes. Symptom: `jq: parse error: Invalid string: control characters from U+0000 through U+001F must be escaped`.

Fix: write API responses to a temp file, read with `jq -r '...' "$file"`. See `cf:access-setup` for the pattern.

## Pinning

Always pin to a tag in production:

```toml
"git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.7.0"
```

Use `ref=main` on local dev only. Bump the tag intentionally when tasks change.

## Cache

```bash
mise cache clear   # force re-fetch after bumping ref
```
