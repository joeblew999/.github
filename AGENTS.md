# Agent Guidelines: joeblew999/.github

This repo is a **shared mise task library** for all `joeblew999` projects, plus GitHub org config.

## ⚠ Read this first if you're picking up the consolidation work

After v0.10.0 (full nushell port, 33 primitives, 9 consumer repos rolled out)
the next architectural move is **a composition layer above the primitives**, not
more primitives. See [`mise-tasks/CONSOLIDATION.md`](./mise-tasks/CONSOLIDATION.md)
for the plan, the per-phase roadmap, and the "don't do" list. Read it before
adding a new task — chances are what you want is composition, not another
primitive.

## Current state (2026-05-02)

- **v0.10.0** — full nushell migration, all 33 mise-tasks are nu (no bash)
- **9 consumer repos** on v0.10.0: nodewarden, auth-service, kv-manager,
  d1-manager, agentic-inbox, saasmail, ifc-lite, mon-house, utm-dev-cli
- **CI proof on every push** (mise-tasks-lint workflow): parse-check on 3 OS
  + fnox-keychain round-trip on Mac+Windows GHA + 12-task real-execution test
  under `shell: nu`. Roughly 30 sec, all green.
- **Rust port** (`joeblew999/secrets-manager`) is the long-term destination
  but not started; nu is the bridge.

## What lives here

| Path | Purpose |
|---|---|
| `mise-tasks/` | Shared mise tasks (33 nu, organized under `<namespace>/`) — consumed via `[task_config].includes` |
| [`mise-tasks/CONSOLIDATION.md`](./mise-tasks/CONSOLIDATION.md) | **Read first** — the plan for the next phase |
| `mise-tasks/_proof/nu-cross-platform.nu` | Cross-platform syntax smoke test (asserted in CI on every push) |
| `mise-tasks/README.md` | Per-namespace task reference (currently inventory-style; planned: user-flow-first refresh) |
| `.github/workflows/mise-tasks-lint.yml` | CI lint matrix on macOS/Linux/Windows |
| `profile/` | GitHub org profile page (github.com/joeblew999) |
| `.claude/` | Claude Code skills and agents |

## Task authoring rules

### 1. Default to nushell, not bash

After v0.10.0 the shared library is nushell. New tasks should follow:

```nu
#!/usr/bin/env nu
#MISE description="one-line description shown in mise tasks ls"
```

The lint workflow accepts both `#!/usr/bin/env bash` and `#!/usr/bin/env nu`
shebangs (the bash one is for legacy / port-on-touch). New code: nu.

When porting bash → nu, common gotchas:
- nu interpolated strings: `$"... ($var) ..."` is variable; `$"... \(literal\) ..."`
  is literal parens. **Don't** write `$"text (literal text)"` — nu reads `(literal`
  as a subexpression and errors `Command not found`.
- nu lists need commas: `["a", "b", "c"]`, not `[a b c]`.
- `sort` doesn't dedupe — use `sort | uniq`.
- `--ide-check 1 <file>` is the parse-check (NOT `--check`).
- `bw config-files` returns the global path; don't pass `--global` to it.
- `nu -c "..."` and `shell = "nu -c"` work in mise.toml inline tasks.
- macOS bash 3.2 doesn't have `declare -A` or `mapfile` — irrelevant for nu, but if
  you ever fall back to bash, design for 3.2 (CI is 5+ on Linux/Win, 3.2 on Mac).

### 2. Always set the executable bit

```bash
chmod +x mise-tasks/<namespace>/<task-name>
```

mise silently skips non-executable file tasks. The CI lint catches this, but
catch it locally first.

### 3. Never use `${#array[@]}` syntax in bash files

mise pre-processes task scripts with the Tera template engine. `{#` is a Tera
comment block opener — it swallows everything up to `#}`. Use alternatives:

```bash
# ✗ breaks
COUNT=${#MY_ARRAY[@]}

# ✓ works
COUNT=$(echo "$MY_ARRAY_VAR" | tr ',' '\n' | wc -l | tr -d ' ')
```

(nu has its own `str length` / `length` — never hits this.)

### 4. Always `unset FNOX_AGE_KEY` at the top of bash secrets tasks

Claude Code leaks `FNOX_AGE_KEY=undefined` into IDE shells (bug:
anthropics/claude-code#53833). fnox prioritises the inline env var over the
key file, so `undefined` breaks it. Unset defensively:

```bash
unset FNOX_AGE_KEY
```

(nu doesn't inherit this issue automatically — but `hide-env FNOX_AGE_KEY` is
the equivalent if needed.)

### 5. Use `git remote get-url origin` to detect the current repo

`gh repo view --json nameWithOwner` follows the parent on forks (returns
`louistrue/ifc-lite` instead of `joeblew999/ifc-lite`). Always parse the
git remote instead.

bash:
```bash
ORIGIN_URL=$(git remote get-url origin 2>/dev/null || true)
REPO=$(printf '%s' "$ORIGIN_URL" | sed -E 's|.*[:/]([^/]+)/([^/]+?)(\.git)?$|\1/\2|')
```

nu:
```nu
let origin_url = (try { ^git remote get-url origin | str trim } catch { "" })
let parsed = ($origin_url | parse --regex '.*[:/](?<owner>[^/]+)/(?<name>[^/]+?)(?:\.git)?$')
```

Note `[^/]+?` (allows dots) — repos like `joeblew999/.github` start with a
dot. The previous regex used `[^/.]+?` and broke on those.

## Adding a new shared task

1. Read [`mise-tasks/CONSOLIDATION.md`](./mise-tasks/CONSOLIDATION.md) — is this a
   primitive that belongs here, or composition that belongs in a consumer repo?
2. If it's a primitive: create `mise-tasks/<namespace>/<task-name>`
3. Add the shebang + MISE description header (nu):
   ```nu
   #!/usr/bin/env nu
   #MISE description="one-line description"
   ```
4. `chmod +x mise-tasks/<namespace>/<task-name>`
5. Local parse-check: `mise exec -- nu --ide-check 1 mise-tasks/<namespace>/<task-name>`
6. Local smoke run with empty env: `mise exec -- nu mise-tasks/<namespace>/<task-name>`
   — should hit a friendly error path, not crash with parse/runtime errors
7. Commit, push to `main`, then release: `mise run release -- vX.Y.Z`
8. Update `mise-tasks/README.md`
9. Tell consuming repos to bump `?ref=vX.Y.Z`

## Release workflow

```bash
mise run release -- v0.10.0
```

Then in each consuming repo that wants the new tasks:
```toml
[task_config]
includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.10.0"]

[tools]
"github:nushell/nushell" = "0.112"   # required by v0.10.0+ (every shared task is nu)
"github:jdx/fnox"        = "1.23"
```
```bash
mise cache clear
mise tasks ls   # verify
```

## Consuming repo wiring (copy-paste, current at v0.10.0)

**CI/CD only** (Cloudflare Workers, secrets, Rust/WASM):
```toml
[task_config]
includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.10.0"]

[tools]
"github:nushell/nushell" = "0.112"
"github:jdx/fnox"        = "1.23"
"aqua:cli/cli"           = "2"
"aqua:jqlang/jq"         = "1"

[env]
FNOX_SYNC_KEYS = "CLOUDFLARE_API_TOKEN,CLOUDFLARE_ACCOUNT_ID,..."
```

**Repo using bw:* (Bitwarden ↔ NodeWarden hybrid):** also add
```toml
"npm:@bitwarden/cli" = "latest"
```

**CI/CD + cross-platform local builds** (Tauri apps — adds Windows 11 / Linux VMs):
```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.10.0",
  "git::https://github.com/joeblew999/utm-dev.git//.mise/tasks?ref=v2.1.0",
]
```

Each repo pins its own ref and bumps deliberately — no forced upgrades.

mise does **not** chain `git::` includes, so both libraries must be listed
explicitly.

## Secrets model

- `fnox` is the canonical local secret store, backed by macOS Keychain
  (Mac), Credential Manager (Windows), or secret-service (Linux desktop)
- `bw` (Bitwarden CLI) is the cloud-side via self-hosted NodeWarden — see
  the `bw:*` task family for the keychain ↔ NodeWarden hybrid sync
- `FNOX_SYNC_KEYS` in each consuming repo lists which fnox keys get pushed
  to GitHub Actions secrets
- CI never runs fnox — it reads from GitHub Actions secrets that
  `secrets:sync-github` populates
- `mise run fnox:init` is idempotent — safe to run on any machine

## CI: mise-tasks-lint.yml

Runs on every push to `mise-tasks/`, `mise.toml`, or the workflow file
itself. Matrix: `[ubuntu-latest, macos-latest, windows-latest]`.

Steps:
1. `mise install` — provisions every pinned tool
2. `mise tasks ls` — verifies tasks load
3. Verify executable bit + valid shebang + `#MISE description=` header
   (skipped for `_proof/`)
4. Check for `${#` Tera-breaking syntax in non-nu files
5. Run `_proof/nu-cross-platform.nu` (asserts exact output)
6. fnox keychain round-trip on Mac+Windows (skipped on Linux — no
   gnome-keyring on Ubuntu GHA)
7. Parse-check every nu file via `nu --ide-check 1`
8. **Negative-path execution test under `shell: nu`** — runs 12 tasks with
   empty env, asserts each hits its first guard with the expected friendly
   message. Catches runtime nu bugs that parse-check misses.

If you change anything in `mise-tasks/`, expect this to run. ~30 seconds.

## Stop reading this file. Read CONSOLIDATION.md.

This file documents *how things are*. The next move documented in
[`mise-tasks/CONSOLIDATION.md`](./mise-tasks/CONSOLIDATION.md) is *what to do
next*. If you're a fresh agent picking up work, that's the higher-priority read.
