# mise-tasks consolidation plan

Author note: written 2026-05-02 at the end of a long migration day, so a
future session (or contributor) can pick up where we stopped without
re-deriving context.

## The problem

After today's full nu port + 9-repo rollout, we have **33 granular
mise-tasks** in this shared library. Each is small and well-defined.
Combined, they're a wall:

```
$ mise tasks ls       # in any consumer repo
... 50+ lines of bw:list, bw:diff, cf:provision-d1-r2,
cf:secrets-put-mapped, cf:access-setup, prove:bindings, prove:deployed,
mobile:tauri-android-build, ...
```

Two real consequences:

1. **No clear "what should I run" surface.** A new dev opens the repo
   and faces 50 tasks. Which 3-5 actually matter for their workflow?
   Currently nothing tells them.

2. **Workflow choreography lives in the user's head.** "First run
   cf:token-check, then cf:provision-d1-r2, then cf:access-setup, then
   cf:secrets-put-mapped, then 10-deploy, then prove:all" — six commands
   to "deploy". The user has to memorize the sequence.

This is heading toward a script mess unless we consolidate.

## Goals (what done looks like)

- ~5 user-facing **verbs** per consumer repo (setup, provision, deploy,
  rotate, status — or repo-specific equivalents)
- The 33 granular tasks become **primitives** that the verbs compose
- Primitives are still discoverable for power users, but secondary
- A new dev runs `mise tasks ls`, sees ~5-10 things, knows what each does

## Phases

### Phase 1 — Composition layer (top-level verbs, per-consumer)

Composition can't live in `joeblew999/.github` because each consumer
composes differently:
- `auth-service` uses CF Access + 4 cf:* + secrets:put-cf
- `nodewarden` uses no CF Access, has its own jwt:set
- `kv-manager` / `d1-manager` follow the canonical CF-Access pattern

So composition tasks live in **each consumer's mise.toml** with names
like `1-setup`, `2-provision`, `3-deploy`, `4-verify`, `5-rotate`.
Numeric prefix makes them sort to the top in `mise tasks ls`.

Pattern: each composition task uses `depends = [...]` to chain
primitives. No script duplication.

Example for the canonical CF-Access deployment pattern (auth-service,
kv-manager, d1-manager):

```toml
[tasks."1-setup"]
description = "First-time fresh machine: fnox + bw + tools"
depends = ["fnox:init", "cf:token-check", "bw:bootstrap"]

[tasks."2-provision"]
description = "Cloud resources for this env (D1 + R2 + Access App)"
depends = [
  "cf:provision-d1-r2",
  "cf:provision-queues",
  "cf:access-setup",
  "cf:secrets-put-mapped",
]

[tasks."3-deploy"]
description = "Build + deploy + verify"
depends = ["10-deploy", "4-verify"]

[tasks."4-verify"]
description = "All deployment health checks"
depends = ["prove:deployed", "prove:access-policy", "prove:bindings", "prove:secrets"]

[tasks."5-rotate"]
description = "Rotate a secret end-to-end (bw:set + bw:sync + secrets:sync-github)"
# Likely needs a wrapper script; multi-step with arg passthrough
```

Effort: ~1 hour per repo. Reversible. No breaking changes to existing
primitives.

### Phase 2 — Hide primitives from default listing (optional)

mise tasks support `#MISE hide=true`. Hiding the 33 primitives makes
`mise tasks ls` show only the ~5 verbs. Power users see the full set
via `mise tasks ls --all`.

Risk: discoverability. A consumer who needs a custom flow has to know
the primitive exists. Mitigation: README in mise-tasks documents every
primitive.

Probably skip this phase. The wall is the price of mise's flat namespace
— accept it for now, focus on the composition layer.

### Phase 3 — Namespacing fixes (low-priority)

Real friction points worth eventually fixing:

- **`prove:*`** is overloaded. Today's 4 prove:* are CF-Access-specific
  (probe deployed Worker for CF Access challenge, the 4 CF Access
  secrets, etc.). Repos like nodewarden (no CF Access) collide on these
  names — that's why we created the `nw:*` namespace today as a
  workaround. Cleaner: rename `prove/` → `cf-access/`. Reserves bare
  `prove:` for org-generic deploy probes. Bumps to v0.11.0.

- **`cf:` mixes concerns**: CF Access (`access-setup`,
  `secrets-put-mapped`), CF Storage (`provision-d1-r2`,
  `provision-queues`, `d1-migrate`), CF Identity (`token-check`).
  Could split into `cf-access/`, `cf-storage/`, `cf-identity/`. Big
  breaking change for marginal clarity. Skip unless other reasons accrue.

- **`release` at top-level** without a namespace. Fine while it's one
  task. If more release-related tasks arrive, move into `release/`.

- **`mobile:android-setup` (noun-verb) vs `cf:provision-d1-r2`
  (verb-noun)** — backward English-grammar order. Not worth the churn.

Recommendation: do the `prove:` → `cf-access:` rename when you next
have a reason to bump consumers. Defer the rest.

### Phase 4 — Refresh `mise-tasks/README.md`

Today's README is task-by-task inventory. Better:

1. **Top section: user flows** — "I want to deploy a fresh CF Worker"
   walks through `1-setup` → `2-provision` → `3-deploy`. Each step
   names the task + what it does + what comes next.
2. **Reference section: per-namespace task list** — what each primitive
   does, when to call it directly.
3. **Anti-pattern section: don't do this** — e.g. "don't compose 5
   primitives manually if a verb already does it."

Effort: 1-2 hours. Worth doing once the composition layer is in place.

### Phase 5 — Rust port to `joeblew999/secrets-manager`

The 33 nu scripts replaced 33 bash scripts today. Eventually they
should be replaced by **subcommands of a single Rust binary** in the
already-created (empty) `joeblew999/secrets-manager` repo.

Shape:
```
secrets-manager bw list
secrets-manager bw set GITHUB_TOKEN
secrets-manager cf provision d1-r2
secrets-manager deploy           # high-level verb, composes
secrets-manager verify
```

mise tasks shrink to 1-line aliases:
```toml
[tasks."bw:list"]
run = "secrets-manager bw list"
```

Why the binary wins:
- Single source of truth (no nu vs bash split per task)
- Type-safe arg parsing via clap
- Built-in `--help` tree
- Native cross-platform (no nu version pinning needed)
- Tests + benchmarks in Rust ecosystem
- The MCP server endpoint that the empty repo's description promises
  becomes natural: a Rust binary can also serve MCP tool calls

Cost: weeks of work. Not "next session". But the architecture is the
endgame; today's nu scripts are the stepping stone.

## Per-repo follow-ups (pick up tomorrow or whenever)

| Repo | Next move |
|---|---|
| `nodewarden` | Add `1-setup`, `3-deploy` composition tasks (already has nw:all for verify) |
| `auth-service` | Inline 1108 lines of bespoke bash → port-on-touch + add `1-setup` etc. composition |
| `kv-manager` / `d1-manager` | Add canonical CF-Access composition tasks (template for others) |
| `agentic-inbox` / `saasmail` | Same pattern |
| `ifc-lite` / `mon-house` | Different — Tauri + content. Compose around their actual workflows |
| `utm-dev-cli` | Generalize beyond Tauri — see below |
| `joeblew999/.github` | Rename `prove/` → `cf-access/` for v0.11.0 |

### utm-dev-cli generalization (not just Tauri)

Today `utm-dev windows build` / `linux build` assume a Tauri project (output: `.msi`, `.deb`, `.AppImage`). For plain Rust binaries (future `secrets-manager`), the high-level commands don't apply. The VM primitives (`vm up/push/exec/pull`) DO work for any project, but it's verbose.

**~1 day of Rust work** in `utm-dev-cli`:
1. In `src/windows.rs` / `src/linux.rs` `build` commands: detect `src-tauri/` or `tauri.conf.json`
2. If Tauri: keep current behavior (`cargo tauri build`, bundle outputs)
3. If plain cargo: run `cargo build --release --target <triple>` and copy
   `target/<triple>/release/<binary-name>` back to host
4. VM lifecycle code stays the same — only the build-step branch changes

After this lands, building `secrets-manager` for Windows from Mac is one command:
```bash
utm-dev windows build --release
```

This is the right shape because the eventual Rust port to `joeblew999/secrets-manager` (Phase 5) needs cross-platform binaries — and utm-dev-cli is already the org's cross-platform build orchestrator. Generalizing it benefits both Tauri apps and pure CLI tools.

Until that lands, the recipe for any Rust crate is:
```bash
utm-dev vm up --name windows-build
utm-dev vm push --name windows-build --from . --to /Users/vagrant/myproject
utm-dev vm exec --name windows-build -- "cd myproject && mise run rust:build -- --release --target x86_64-pc-windows-msvc"
utm-dev vm pull --name windows-build --from "C:\\Users\\vagrant\\myproject\\target\\x86_64-pc-windows-msvc\\release\\myapp.exe" --to ./dist/
```

## Why STOP NOW vs keep going

Today's 14-hour push achieved horizontal coverage:
- NodeWarden deployed
- Full nu migration of all 33 mise-tasks
- 9 consumer repos rolled out to v0.10.0
- CI proves it on macOS+Linux+Windows
- fnox keychain proven on Windows GHA

The remaining work is **vertical consolidation** — fewer, higher-level,
better-organized verbs. That requires fresh eyes. Continuing under
fatigue would create more granularity, not less, and lock in
half-thought-through naming.

The 33 tasks are well-tested primitives. They'll be there tomorrow.

## Concrete next-session opening

When picking this up:

1. Read this doc.
2. Read `project_consolidation_plan.md` in Claude memory.
3. Pick ONE consumer repo (recommend `kv-manager` — clean canonical
   CF-Access pattern, no bespoke bash, simplest test bed).
4. Add `1-setup` / `2-provision` / `3-deploy` / `4-verify` composition
   tasks via `depends`.
5. Live-test on Mac.
6. Document the pattern.
7. Then propagate to other CF-Access-pattern repos (auth-service,
   d1-manager, agentic-inbox, saasmail).
8. nodewarden / mon-house / utm-dev-cli get their own bespoke
   compositions (their workflows differ).

Don't start with the Rust port. The composition layer is the lower-cost
high-value win. Rust comes after.
