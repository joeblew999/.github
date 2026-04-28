# Agent Guidelines: joeblew999/.github

This repo is a **shared mise task library** for all `joeblew999` projects, plus GitHub org config.

## What lives here

| Path | Purpose |
|---|---|
| `mise-tasks/` | Shared mise tasks — consumed by repos via `[task_config].includes` |
| `.github/` | Org-level GitHub config (CODEOWNERS, issue templates, dependabot, workflows) |
| `profile/` | GitHub org profile page (github.com/joeblew999) |
| `.claude/` | Claude Code skills and agents |

## Task authoring rules

### 1. Always set the executable bit
```bash
chmod +x mise-tasks/<namespace>/<task-name>
```
mise silently skips non-executable file tasks. The CI lint catches this, but catch it locally first.

### 2. Never use `${#array[@]}` syntax
mise pre-processes task scripts with the Tera template engine. `{#` is a Tera comment block opener — it will swallow everything up to `#}`. Use alternatives:
```bash
# ✗ breaks
COUNT=${#MY_ARRAY[@]}

# ✓ works
COUNT=$(echo "$MY_ARRAY_VAR" | tr ',' '\n' | wc -l | tr -d ' ')
# or iterate with: IFS=',' read -ra ARR <<< "$VAR"
```

### 3. Always `unset FNOX_AGE_KEY` at the top of secrets tasks
Claude Code leaks `FNOX_AGE_KEY=undefined` into IDE shells (bug: anthropics/claude-code#53833).
fnox prioritises the inline env var over the key file, so `undefined` breaks it. Unset defensively:
```bash
unset FNOX_AGE_KEY
```

### 4. Use `git remote get-url origin` to detect the current repo
`gh repo view --json nameWithOwner` follows the parent on forks (returns `louistrue/ifc-lite`
instead of `joeblew999/ifc-lite`). Always parse the git remote instead:
```bash
ORIGIN_URL=$(git remote get-url origin 2>/dev/null || true)
REPO=$(printf '%s' "$ORIGIN_URL" | sed -E 's|.*[:/]([^/]+)/([^/.]+)(\.git)?$|\1/\2|')
```

## Adding a new shared task

1. Create the file: `mise-tasks/<namespace>/<task-name>`
2. Add the shebang + MISE description header:
   ```bash
   #!/usr/bin/env bash
   #MISE description="one-line description shown in mise tasks ls"
   set -euo pipefail
   ```
3. `chmod +x mise-tasks/<namespace>/<task-name>`
4. Test locally: `mise tasks ls` (this repo's `mise.toml` includes `mise-tasks/` directly)
5. Commit, push, then release: `mise run release -- vX.Y.Z`
6. Update `mise-tasks/README.md` task table
7. Tell consuming repos to bump `?ref=vX.Y.Z` and run `mise cache clear`

## Release workflow

```bash
mise run release -- v0.3.0
```

Then in each consuming repo that wants the new tasks:
```toml
includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.3.0"]
```
```bash
mise cache clear
mise tasks ls   # verify
```

## Consuming repo wiring (copy-paste)

**CI/CD only** (Cloudflare Workers, secrets, Rust/WASM):
```toml
[task_config]
includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.3.0"]

[env]
FNOX_SYNC_KEYS = "CLOUDFLARE_API_TOKEN,CLOUDFLARE_ACCOUNT_ID,..."
```

**CI/CD + cross-platform local builds** (Tauri apps — adds Windows 11 / Linux VMs via utm-dev):
```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.3.0",
  "git::https://github.com/joeblew999/utm-dev.git//.mise/tasks?ref=v2.1.0",
]

[env]
FNOX_SYNC_KEYS = "CLOUDFLARE_API_TOKEN,CLOUDFLARE_ACCOUNT_ID,TAURI_SIGNING_PRIVATE_KEY"
```

Each repo pins its own ref and bumps deliberately — no forced upgrades.

mise does **not** chain `git::` includes, so both libraries must be listed explicitly. utm-dev tasks
are TypeScript/Bun; `.github` tasks are bash — they coexist cleanly under separate namespaces.

## Secrets model

- `fnox` is the canonical secret store, backed by macOS Keychain (no age key file)
- `FNOX_SYNC_KEYS` in each consuming repo lists which fnox keys get pushed to GitHub Actions
- CI never runs fnox — it reads from GitHub Actions secrets that `secrets:sync-github` populates
- `mise run fnox:init` is idempotent — safe to run on any machine, sets up keychain provider

## CI

`mise-tasks-lint.yml` runs on every push to `mise-tasks/` or `mise.toml`:
- `mise tasks ls` — verifies all tasks load without error
- Checks every task file has the executable bit set
