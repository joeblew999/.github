# Agent Guidelines: joeblew999/.github

This repo is a **shared mise task library** for all `joeblew999` projects, plus GitHub org config.

## ⚠ Read this first

Two architectural directions, in order of priority:

1. **TOML-task migration (v0.16.x — in flight).** New tasks (and ports of
   existing ones) go in `tasks/<ns>.toml` with per-task `tools = { ... }`,
   not in `mise-tasks/<ns>/<name>` as file-tasks. Per-task tools auto-install
   when the task runs and stay scoped — consumers no longer have to pin
   gh/jq/ruby/cocoapods/java/etc. just because a shared task uses them.
   See "TOML-task vs file-task" section below.

2. **Composition layer (CONSOLIDATION.md).** Top-level verbs that chain
   primitives via `depends = [...]`. Lives in *each consumer's* mise.toml,
   not here. See [`mise-tasks/CONSOLIDATION.md`](./mise-tasks/CONSOLIDATION.md)
   for the plan. Orthogonal to (1) — both can advance.

Before adding a new task, ask: should this be a TOML-task with per-task
tools (almost always yes for new shared tasks), or a file-task (only if
the body is too large to comfortably inline as a TOML string)?

## Current state (2026-05-07)

- **v0.16.2** — TOML-task pattern shipped + first three namespaces ported.
  - `tasks/ci.toml` — `ci:parse-check`, `ci:watch`, `ci:clean` (per-task: nu, fnox, gh)
  - `tasks/cf.toml` — `cf:token-check` (per-task: nu, fnox)
  - `tasks/secrets.toml` — `secrets:sync-github` (per-task: nu, fnox, gh)
  - `tasks/mobile.toml` — 8 mobile:* tasks (per-task: nu + java/ruby/cocoapods/cargo:tauri-cli)
- **Legacy v0.10.0 file-tasks** in `mise-tasks/` still ship and work. Removal
  blocked on full consumer migration to TOML-task includes.
- **gsv** is on v0.16.0 and was the migration test bed. CI green on 3 OS
  including Windows (after fixing a separate 1-deps glob bug + skipping
  test-gateway on Windows due to upstream Cloudflare workerd instability).
- **Other 7 consumer repos** still pin `?ref=v0.10.0` — pending mechanical
  migration to v0.16.x TOML-task includes.
- **Two CI canaries** on every push:
  - `tasks-toml-proof.yml` — TOML-task mechanism + each shipped `tasks/*.toml`,
    on linux+macos+windows (~25s)
  - `mise-tasks-lint.yml` — parse-check + fnox keychain + negative-path
    execution for legacy file-tasks, same 3 OS (~30s)
- **`monorepo-root-proof.yml`** — kept as documentation of an alternative
  we evaluated and rejected; lets us re-examine if mise drops the
  experimental flag from `experimental_monorepo_root`.
- **Rust port** (`joeblew999/secrets-manager`) is the long-term destination
  but not started; nu is the bridge.

## What lives here

| Path | Purpose |
|---|---|
| `tasks/<ns>.toml` | **New (v0.16+)** — TOML-task definitions with per-task `tools = { ... }`. Consumed remotely via `task_config.includes = ["git::....toml?ref=v0.16.x"]`. **Preferred for new tasks.** |
| `mise-tasks/<ns>/<name>` | Legacy nu file-tasks (~33 of them). Consumed via `task_config.includes` pointed at the directory. Still work; will be retired as namespaces are ported to `tasks/*.toml`. |
| [`mise-tasks/CONSOLIDATION.md`](./mise-tasks/CONSOLIDATION.md) | Plan for the *composition layer* (consumer-side, orthogonal to TOML-task work) |
| `mise-tasks/_proof/nu-cross-platform.nu` | Cross-platform nu syntax smoke test |
| `mise-tasks/README.md` | Per-namespace task reference |
| `.github/workflows/tasks-toml-proof.yml` | **CI canary for TOML-tasks** — discovery + per-task tool install + scoping + real-file validation per shipped `tasks/*.toml`. 3 OS. |
| `.github/workflows/mise-tasks-lint.yml` | CI lint matrix for legacy file-tasks. 3 OS. |
| `.github/workflows/monorepo-root-proof.yml` | Reference: the experimental alternative we evaluated & rejected. Kept as documentation. |
| `.github/workflows/reusable-mise-ci.yml` / `reusable-mise-upgrade.yml` | Reusable workflows consumers `uses:` |
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

## Adding a new shared task — checklist (no drift)

This repo is the org's shared system. Every new task MUST be:

1. **Right place.** Read [`mise-tasks/CONSOLIDATION.md`](./mise-tasks/CONSOLIDATION.md) — primitive (here) vs composition (consumer repo)?
2. **Right path.** `mise-tasks/<namespace>/<task-name>` (subdirs become `namespace:` prefixes — e.g. `cf/token-check` → `cf:token-check`).
3. **Right header.**
   ```nu
   #!/usr/bin/env nu
   #MISE description="one-line description"
   ```
4. **Executable.** `chmod +x mise-tasks/<namespace>/<task-name>` (mise silently skips non-executables).
5. **Parse-clean.** `mise run ci:parse-check` — fails if any nu file has a syntax error.
6. **Negative-path execution test.** If the task fails gracefully on missing prereq (no token, no env var, etc.), **add it to the `cases` array in [`.github/workflows/mise-tasks-lint.yml`](./.github/workflows/mise-tasks-lint.yml)**. This proves the friendly error path holds on every OS. Tasks with no missing-prereq failure mode (idempotent ones like `mise:upgrade`, `release` with arg) can skip this.
7. **README.md updated.** Add a row in the right namespace section of [`mise-tasks/README.md`](./mise-tasks/README.md). If it's a new namespace, add a section.
8. **Commit, push to `main`, then `mise run release -- vX.Y.Z`.**
9. **Bump `?ref=vX.Y.Z`** in consumer repos when they pull the new task.

## "Keep this repo clean" — invariants that must always hold

This repo is the SSOT for every joeblew999 project's tooling. Drift here breaks every consumer.

- **Every task file has shebang + `#MISE description=`.** Verified by `mise-tasks-lint.yml` on every push.
- **Every task is parse-clean on linux/macos/windows.** `mise run ci:parse-check` (locally) + the workflow assertion.
- **Every task that fails on missing prereqs has a negative-path test entry.** Catches runtime nu bugs that parse-check misses.
- **README.md lists every namespace.** When you add a new namespace (rare), add a section. When you add a task to an existing namespace, add a row.
- **Reusable workflows** (`reusable-mise-ci.yml`, `reusable-mise-upgrade.yml`) ride the same tag stream as the task library — every release tag (currently `v0.19.1`) ships the workflow files alongside `tasks/` and `mise-tasks/`. Consumers reference by tag (`@vX.Y.Z`). Don't break the input contract without a major bump; safe to bump the `@vX.Y.Z` pin in lockstep with the `[task_config].includes` `?ref=`.
- **`?ref=` example version in README.md** stays current with the latest tag.
- **The local `mise tasks ls` count** matches expectations (currently ~50). A surprise drop = mise auto-discovery missed something (probably a missing `chmod +x`).
- **No `${#array[@]}` in bash files** (Tera template engine eats `{#…#}` blocks). Flagged by the lint workflow; nu files are immune.

## Reusable workflows (added v0.15.0)

`.github/workflows/reusable-mise-ci.yml` and `.github/workflows/reusable-mise-upgrade.yml` are GH Actions reusable workflows that any joeblew999 repo can invoke via `uses:`. They share the same tag stream as the task library — bump the `@vX.Y.Z` pin in lockstep with `[task_config].includes` `?ref=` (currently `v0.19.1`):

```yaml
# in <repo>/.github/workflows/ci.yml
jobs:
  ci:
    uses: joeblew999/.github/.github/workflows/reusable-mise-ci.yml@v0.19.1
    with:
      task: check         # the mise task to run
      cargo-lock-path: cli/Cargo.lock   # for sccache cache key
```

The reusable workflow runs **one** mise task; that task's `depends` graph fans out the work. Every active consumer ships a `[tasks.check]` aggregator that depends on `ci:parse-check` + `ci:check-toml-tasks` + `ci:check-workflow-nu` (plus repo-specific build/test) — pair it with this workflow for a one-line CI definition.

When changing inputs in these workflows, treat them as a public API:
- **Adding** an input with a default = backward-compat = patch/minor bump.
- **Removing** or **renaming** an input = breaking = major bump.
- **Changing default values** = consumers will see behavior change = at minimum a CHANGELOG note.

## TOML-task vs file-task — when to use which

| | TOML-task (`tasks/<ns>.toml`) | File-task (`mise-tasks/<ns>/<name>`) |
|---|---|---|
| Per-task `tools = { ... }` propagates through remote `git::` includes | ✓ | ✗ (discussion #5267 — silently ignored) |
| Body limit | inline `run = '''...'''` (TOML triple-quoted; >300 lines feels cramped) | unlimited (separate file) |
| Args/flags | `def main [--flag]` works inside `run = '''#!/usr/bin/env nu...'''` | same |
| Discovery in consumer | explicit `git::....toml?ref=vX.Y.Z` URL per file | one URL for the whole `mise-tasks/` directory |
| Renovate-bumpable | yes (URL pin) | yes (URL pin) |
| Right answer for | new tasks; existing tasks getting per-task tools | only when body is too long to inline |

**Default to TOML-task.** File-tasks are legacy; we're porting them as we touch them.

When porting a file-task → TOML-task:
1. Take the existing nu script body verbatim, drop into `run = '''...'''`
2. Add the `#!/usr/bin/env nu` shebang as the first line of the run body
3. Declare per-task tools the script needs: `tools = { "github:nushell/nushell" = "0.112", ... }`
4. Quote namespaced keys: `["bw:list"]`, not `[bw:list]`
5. Add a step in `tasks-toml-proof.yml` to verify discovery + (cheap) negative path
6. Leave the legacy file-task in `mise-tasks/` until all consumers migrate

## Release workflow

```bash
mise run release -- v0.16.x
```

Tag pushed → consumer repos can opt in by bumping their `?ref=` URLs.

Cache invalidation if a consumer pulled the OLD ref already:
```bash
rm -rf ~/Library/Caches/mise/remote-git-tasks-cache/*   # macOS
mise tasks ls
```

## Consuming repo wiring

### Modern (v0.16.x — TOML-task includes, recommended)

```toml
[task_config]
includes = [
  "mise-tasks",  # local file-tasks (auto-discovered)
  "git::https://github.com/joeblew999/.github.git//tasks/ci.toml?ref=v0.16.2",
  "git::https://github.com/joeblew999/.github.git//tasks/cf.toml?ref=v0.16.2",
  "git::https://github.com/joeblew999/.github.git//tasks/secrets.toml?ref=v0.16.2",
  # add tasks/mobile.toml if the consumer needs mobile:* tasks
]

[tools]
# Pin only what the consumer's OWN tasks use. Tools needed by shared
# tasks (gh, jq, ruby, cocoapods, java, tauri-cli, etc.) come along
# automatically with each task's `tools = { ... }`.
"github:nushell/nushell" = "0.112"
"github:jdx/fnox"        = "1.24"   # if consumer's local tasks call ^fnox

[env]
FNOX_SYNC_KEYS = "CLOUDFLARE_API_TOKEN,CLOUDFLARE_ACCOUNT_ID,..."
```

### Legacy (v0.10.0–v0.15.x — directory include, file-tasks)

```toml
[task_config]
includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.10.0"]

[tools]
"github:nushell/nushell" = "0.112"
"github:jdx/fnox"        = "1.23"
"aqua:cli/cli"           = "2"      # gh — needed because file-tasks don't propagate per-task tools
"aqua:jqlang/jq"         = "1"      # same

[env]
FNOX_SYNC_KEYS = "..."
```

Both forms can coexist in the same consumer (e.g. mix v0.10.0 directory
include for not-yet-ported namespaces with v0.16.x TOML-task includes
for ci/cf/secrets/mobile).

mise does **not** chain `git::` includes, so each library must be listed
explicitly.

Each repo pins its own ref and bumps deliberately — no forced upgrades.

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
