---
name: github-meta-repo-expert
description: Expert on the joeblew999/.github shared mise-task library. Use when adding, editing, or debugging mise tasks; releasing new versions; wiring consuming repos; or understanding the secrets/fnox model.
---

# .github repo — shared mise task library

Current release: **v0.4.0**

## Structure

```
mise-tasks/           shared mise tasks — consumed via [task_config].includes
  release             tag + push a semver release
  fnox/init           bootstrap fnox keychain provider
  secrets/            sync-github, sync-github-dry, status, migrate-to-keychain
  cf/                 d1-migrate, token-check
  rust/               build, test, wasm-pack
  wrangler/           dev, deploy, tail, secret-list
.github/
  workflows/
    mise-tasks-lint.yml   3-platform CI (ubuntu + macos + windows)
    welcome.yml
  CODEOWNERS
  dependabot.yml
  issue-templates/
.claude/
  agents/             this file
mise.toml             dogfoods the library; pins all tools including cargo:usage-cli@3
AGENTS.md             authoring rules for humans and AI
CLAUDE.md             points to AGENTS.md
README.md             usage guide + utm-dev combination pattern
```

## Consuming repos wire in the shared tasks

```toml
[task_config]
includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.4.0"]

[env]
FNOX_SYNC_KEYS = "CLOUDFLARE_API_TOKEN,CLOUDFLARE_ACCOUNT_ID,..."
```

For repos also needing cross-platform VM builds (Tauri — Windows/Linux via utm-dev):
```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.4.0",
  "git::https://github.com/joeblew999/utm-dev.git//.mise/tasks?ref=v2.1.0",
]
```

mise does NOT chain `git::` includes — both must be listed explicitly.

## Task authoring rules

### Executable bit required
```bash
chmod +x mise-tasks/<namespace>/<task-name>
```
CI catches missing executable bits but catch it locally first.

### Shebang + MISE header required
```bash
#!/usr/bin/env bash
#MISE description="one-line description"
set -euo pipefail
```

### #USAGE annotations for args and flags
Use jdx/usage annotations for tab-completion and --help. Variables are set by mise:
```bash
#USAGE arg "<crate-dir>" help="path to the crate to compile"
#USAGE flag "--env <env>" help="Cloudflare environment" env="ENV" default="production"
CRATE="${usage_crate_dir:-${1:-""}}"
ENV="${usage_env:-${ENV:-production}}"
```
Always fall back to `$1` / `$ENV` so scripts work without usage-cli installed.

### Never use `${#array[@]}` or `${#string}`
Mise pre-processes scripts with Tera. `{#` opens a Tera comment block — it silently
swallows everything until `#}`. Use alternatives:
```bash
# ✗ breaks silently
COUNT=${#MY_ARRAY[@]}
# ✓ works
COUNT=$(echo "$KEYS" | tr ',' '\n' | wc -l | tr -d ' ')
```

### Always `unset FNOX_AGE_KEY` in secrets tasks
Claude Code leaks `FNOX_AGE_KEY=undefined` into IDE shells (bug: anthropics/claude-code#53833).
```bash
unset FNOX_AGE_KEY
```

### Use `git remote get-url origin` to detect the current repo
`gh repo view` follows the parent on forks. Always parse the git remote:
```bash
ORIGIN_URL=$(git remote get-url origin 2>/dev/null || true)
REPO=$(printf '%s' "$ORIGIN_URL" | sed -E 's|.*[:/]([^/]+)/([^/.]+)(\.git)?$|\1/\2|')
```

## Adding a new shared task

1. Create `mise-tasks/<namespace>/<task-name>`
2. Add shebang + `#MISE description=` + `#USAGE` annotations
3. `chmod +x mise-tasks/<namespace>/<task-name>`
4. Test: `mise tasks ls` (this repo's `mise.toml` includes `mise-tasks/` directly)
5. Update `mise-tasks/README.md` task table
6. Commit + release: `mise run release -- vX.Y.Z`
7. Tell consuming repos to bump `?ref=vX.Y.Z` and run `mise cache clear`

## Releasing

```bash
mise run release -- v0.5.0
```

The `release` task checks: on main, clean working tree, tag doesn't exist, then tags + pushes.

## utm-dev / vm: namespace (planned)

utm-dev (https://github.com/joeblew999/utm-dev) currently uses TypeScript/Bun tasks and
must be included separately. When utm-dev is rewritten as a Rust CLI (`cargo:utm-dev`):

- `cargo:utm-dev` will be added to `mise.toml [tools]`
- Thin bash wrappers in `mise-tasks/vm/` will delegate to the binary
- All repos will get `vm:up`, `vm:build`, `vm:down`, etc. via the single `.github` include
- Each wrapper uses `#USAGE` for full tab-completion

Until then: include utm-dev separately as shown in the consuming repo wiring above.

## CI

`mise-tasks-lint.yml` runs on push to `mise-tasks/**`, `mise.toml`, or the workflow file itself.
Matrix: ubuntu-latest, macos-latest, windows-latest. All `run` steps use `shell: bash`.
Checks: tasks load (`mise tasks ls`), executable bit, `#MISE description=` header, no `${#` Tera syntax.
