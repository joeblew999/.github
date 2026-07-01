# joeblew999/.github

Shared **mise task library** + Claude plugin marketplace + GitHub org config for
the whole fleet. Every capability is a **mise task**, shared **by reference**
(`?ref=` / `@ref`, never copied into repos), and **runs the same locally as in CI**.

History: [CHANGELOG.md](./CHANGELOG.md) (git-cliff generated) · canonical consumer:
[.github-example](https://github.com/joeblew999/.github-example).

This one file is the source of truth — for humans and for agents (Claude Code,
Cursor, Copilot, …). [AGENTS.md](./AGENTS.md) / [CLAUDE.md](./CLAUDE.md) are thin
pointers here.

---

## Contents

- [Platform systems — the map](#platform-systems--the-map)
- [1. Use it in a repo](#1-use-it-in-a-repo)
- [2. CI — one task, local *and* remote](#2-ci--one-task-local-and-remote)
- [3. What's inside — two layers](#3-whats-inside--two-layers)
- [4. Authoring conventions](#4-authoring-conventions)
- [5. Developing this repo](#5-developing-this-repo)
- [6. Upgrading (migration)](#6-upgrading-migration)

---

## Platform systems — the map

The shared, reusable systems across the fleet, and the **one repo to start in** for
each. Projects *consume* these; each system's building blocks live in their own
repos (linked from the system's home README, not duplicated).

> **The convention:** a shared system gets a **home / front-door repo** (overview +
> how to use it + deploy). Its components stay in their own repos. So "how does this
> fit together?" always has one address — here, then the system's home.

| System | Home repo | What it is |
|---|---|---|
| **Auth** | **[`cf-connectrpc-middleware`](https://github.com/joeblew999/cf-connectrpc-middleware)** | Rauthy (OIDC IdP — AuthN) + Cedar (policy AuthZ) + Cloudflare email. The `connectrpc-oidc` + `connectrpc-cedar` crates, the Kumo client kit, the examples, `mise run stack:local` to run it all locally, and `docs/NEW-PROJECT.md` to add auth to a project. |
| **Deploy** | **[`vm-uncloud`](https://github.com/joeblew999/vm-uncloud)** | The single home for Hetzner deployments via uncloud — recipes (Rauthy, Moltis, WordPress, Windows VMs…), one cost ledger. |
| **Tooling** | **[`.github`](https://github.com/joeblew999/.github)** (this repo) | Shared mise task library (by-reference, same locally + CI) + Claude plugin marketplace + org config. |

*Add a row when a new reusable system gets a home repo. Product repos that merely
consume the platform don't belong here — they live on their own.*

---

## 1. Use it in a repo

Add the task files you want to `mise.toml`, then run four commands:

```sh
# mise.toml — pin ?ref= to the latest tag:
# [task_config]
# includes = [
#   "git::https://github.com/joeblew999/.github.git//tasks/mise.toml?ref=<tag>",
#   "git::https://github.com/joeblew999/.github.git//tasks/ci.toml?ref=<tag>",
# ]
mise trust                       # load the config + includes
mise run mise:global:bootstrap   # seed the machine toolset (nu, gh, …) — once per machine
mise run mise:repo:bootstrap     # write .github/workflows/ (the CI stub)
mise run ci                      # verify
```

> **Reference [`.github-example`](https://github.com/joeblew999/.github-example).**
> It's the canonical consumer — every `.github` change is validated against it
> (locally *and* on the matrix) before release, so its wiring is always current. But
> it's the **full feature showcase** (Rust + docker + binary/image publishing), there
> to keep every capability CI-tested — **not a starter template to copy wholesale.**
> A real repo takes only the subset it needs: the bare minimum is two includes
> (`mise.toml` + `ci.toml`) and `[tasks.ci].depends`. Add a `tool-*` include / `[env]`
> knob only for a feature you actually want.

**A consumer adopts, in this order:**

1. **Skills + conventions** — `claude plugin marketplace add joeblew999/.github`,
   install `fleet` (or read this file).
2. **`CLAUDE.md`** in the repo root, pointing agents here.
3. **mise tasks** — `mise.toml` `[task_config].includes` the namespaces you need,
   pinned `?ref=vX`.
4. **global tools** — `mise run mise:global:bootstrap` (once per machine).
5. **Rust?** — pin in `rust-toolchain.toml` (rustup), **never** mise.
6. **CI** — `mise run mise:repo:bootstrap` writes `.github/workflows/mise.yml` (a stub
   calling `reusable-mise-ci.yml@vX`). The scheduled `reusable-mise-upgrade` PR then
   bumps tool versions (`mise:upgrade`) **and** the `?ref=`/`@ref` pins
   (`ci:audit-lib-refs --write`) in one PR.

A consumer adds ONLY its own repo-specific tasks/tools; everything shared comes from
above.

---

## 2. CI — one task, local *and* remote

This is the core design. Your repo's CI is a **single mise task — `mise run ci`** —
and it runs in **two places, identically**:

| how you run it | where | OS coverage |
|---|---|---|
| **`mise run ci`** | your machine | **your OS** — instant, while you work |
| **`git push`** | GitHub Actions | the **full matrix** (ubuntu + macOS + windows) |

The workflow that `mise:repo:bootstrap` wrote (`.github/workflows/mise.yml`) does
nothing but run that same `mise run ci`. So **local is one cell of remote**:

> green locally ⇒ green for *that* OS in CI. Push, and the matrix runs the identical
> task on the other OSes. **Always run it locally first** — pushing untested is the
> only thing that breaks CI.

**The main lever: `[tasks.ci].depends`.** The shared `ci` runs the library's guards;
add a *local* `ci` that `depends` on your own tasks and mise **merges** them, so
`mise run ci` runs the guards *and* your work — locally and on the matrix. **That
list IS your CI** — add a task to build/check it, remove it to stop:

```toml
[tasks.ci]
depends = ["test", "rust:test", "docker:build"]   # ← edit this list = change CI
```

Want a Rust toolchain compiled or a container built? Add `tool-rust` / `tool-docker`
to `includes`, then `rust:test` / `docker:build` to `depends`. The
[`.github-example`](https://github.com/joeblew999/.github-example) does exactly this.

**Zero config = a sensible default.** Set nothing and `mise run ci` runs just the
guards (`ci:check-global` + `ci:check-nu`) — on your OS locally, on all three OSes on
push. Identical, green out of the box. Nothing compiles or builds until *you* add it.

**All CI data is in `mise.toml`** — one file. You never hand-edit the generated
workflow, and **re-bootstrap preserves your settings** (bootstrap *reads* `[env]` and
projects it into the workflow; it never *writes* `mise.toml`). Every knob has an
obvious default-if-unset:

| to control… | set in `mise.toml`… | default if unset | applies |
|---|---|---|---|
| **what runs** | `[tasks.ci].depends` | the two guards only | immediately |
| docker **local vs remote** | `[env] DOCKER_BUILD` | `auto` — wherever a linux daemon exists | immediately |
| **which OSes CI runs** | `[env] CI_OS_MATRIX` | all 3 (ubuntu + macOS + windows) | re-bootstrap |
| CI task · Rust build cache | `[env] CI_TASK · CI_SCCACHE` | `ci` · `true` (Swatinem/rust-cache: `~/.cargo` + `target/`; `CI_SCCACHE` name kept for compat) | re-bootstrap |
| **publish binaries on tag** | `[env] CI_RELEASE` | off | re-bootstrap |
| **which OSes publish** | `[env] CI_RELEASE_OS_MATRIX` | ubuntu + macOS (no windows) | re-bootstrap |
| **publish a runnable GHCR image** | `[env] CI_DOCKER_IMAGE` | off | re-bootstrap |
| **which Dockerfile** (build + publish) | `[env] CI_DOCKERFILE · CI_DOCKER_CONTEXT · CI_DOCKER_PLATFORMS` | `Dockerfile` · `.` · `linux/amd64` | immediately |
| build-task for publish | `[env] CI_BUILD_TASK` | `dist` | re-bootstrap |

The `CI_*` ones need a re-bootstrap because GitHub reads the matrix from the workflow
*before* mise starts — so bootstrap projects them there. You still only edit
`mise.toml`. (Flags like `--os-matrix` / `--release-os-matrix` work for a one-off.)
The two OS knobs are independent: **CI** verifies on all 3 OSes by default, but
**publish** defaults to ubuntu + macOS — set `CI_RELEASE_OS_MATRIX` to add windows.

> **Verify vs publish.** `ci` *verifies* on every push (cheap, no secrets) — and the
> matrix compiles a native binary per OS. *Publishing* downloadable binaries/images
> is a **separate opt-in** — `mise run mise:repo:bootstrap --release` — which runs on
> a git **tag**, not every push, with its own os-matrix.

**Rust build cache.** The reusable CI caches `~/.cargo/{registry,git}` + `target/`
via [`Swatinem/rust-cache`](https://github.com/Swatinem/rust-cache), keyed on
`Cargo.lock` + rustc + task. First run on a key is cold (populates); subsequent runs
restore it. On by default (`CI_SCCACHE`, name kept for backward compat); set false
for non-Rust repos.

---

## 3. What's inside — two layers

`tasks/` splits into a **tool layer** (`tool-*.toml` — pure primitives that drive
only their own tool, no `fnox`) and an **orchestration layer** (plain `*.toml` —
compose tool tasks and own the `fnox`→`$env` bridge). The filename tells you which.

*The tables below are **generated** from each task file's `# role:` header by
`mise run docs:gen`, and CI fails if they drift — so they can't go stale.*

<!-- gen:tasks -->

### Tool layer — `tool-*.toml` (pure primitives — drive only their own tool)

| file | role |
|---|---|
| `tool-cf` | Cloudflare CLI — `wrangler` + `curl` (HTTP) |
| `tool-cliff` | Changelog queries — `git-cliff` |
| `tool-docker` | Docker / ghcr — `docker` |
| `tool-fnox` | Secrets CLI — `fnox` |
| `tool-gh` | GitHub CLI — `gh` |
| `tool-rust` | Rust toolchain — `cargo` / `wasm-pack` |
| `tool-wrangler` | Wrangler CLI — `wrangler` |

### Orchestration layer — plain `*.toml` (compose tool tasks)

| namespace | role |
|---|---|
| `cfapp` | Cloudflare Worker lifecycle — provision → access → verify |
| `ci` | verify code — parse + global-config guards + dogfood |
| `mobile` | build mobile apps — tauri + Android/iOS |
| `release` | ship — changelog → tag → GitHub release |
| `secrets-bw` | manage secrets — Bitwarden/NodeWarden bridge (`secrets:bw-*`) |
| `secrets` | manage secrets — keychain ↔ fnox ↔ GitHub |

Runner: **`mise`** — machine + repo bootstrap, sweep, upgrade.

<!-- /gen:tasks -->

**The one rule:** plumbing (`git`/`curl`/`tar`) is fine anywhere. A *tool* file that
drives another tool's binary or reaches into `fnox` is mis-placed — push that up to
an orchestration file. Secrets flow **down**: orchestration reads `fnox`, sets
`$env`, then `mise run`s the pure primitive (the child inherits the env). A task
whose name implies one tool but drives others is mis-named — move it (`cliff:release`
→ `release:github`; `ci:watch` → `gh:run-watch`).

---

## 4. Authoring conventions

Read this before touching a task, workflow, skill, or release.

### Cross-platform or it's broken

Every repo here must work on **macOS, Linux AND Windows**. Therefore:

- **All task logic is nushell** (`#!/usr/bin/env nu`) — never bash/sh/PowerShell,
  never a `.sh` file. No bash-isms, no hardcoded `/Users`, `/home`, `/opt` paths;
  derive from env + install state.
- A task that is a **single plain command** mise runs in the default shell (e.g.
  `mise:global:bootstrap` = `mise use -g …`) is fine — it's not shell-specific.
- The **bootstrap before nu exists** is bare `mise` commands ONLY. nu is installed by
  `mise run mise:global:bootstrap`, so the bootstrap can't itself be nu — mise is the
  one cross-platform tool guaranteed present.

If you reach for a shell script, you've already broken the rule. Write a nu task.

### Distribution — by reference + versioned, never copy

Nothing copies files into repos. If you find yourself writing code to
clone/copy/"stamp" `.github` content into a repo, **STOP — you are reinventing.**

| What | Mechanism | Versioned by | Scope |
|---|---|---|---|
| **mise tasks** | `[task_config].includes = ["git::…/tasks/<ns>.toml?ref=vX"]` in the repo's `mise.toml` | `?ref=` | per repo |
| **CI** | `.github/workflows/*.yml` → `uses: …/reusable-mise-ci.yml@vX` (runs `mise run <task>`) | `@ref` | per repo |
| **global tools** | `mise run mise:global:bootstrap` | latest | per machine |
| **claude skills** | this repo IS a Claude plugin **marketplace** — `claude plugin marketplace add joeblew999/.github` + install `fleet` | plugin version | per machine |

A repo "upgrades" by bumping `?ref=`/`@ref` or its plugin. Before building anything
fleet-wide: search the fleet for the existing mechanism (grep `tasks/`, check
`known_marketplaces.json`).

### Namespace = tool (+ an orchestration tier)

| Namespace | Layer / role |
|---|---|
| `cf gh docker cliff rust wrangler fnox` | **tool** primitives (in `tool-*.toml`) — own domain tool + plumbing only |
| `ci:*` | **orchestration** — verify code: `check-nu`/`check-global`/`audit-lib-refs` + dogfood |
| `secrets:*` | **orchestration** — keychain ↔ fnox ↔ gh ↔ bitwarden (`secrets-bw.toml` = `secrets:bw-*`) |
| `cfapp:*` | **orchestration** — Cloudflare Worker lifecycle: `provision-*` + `access-*` + `verify-*` |
| `release:*` | **orchestration** — ship: `release:github`, `release:pack` |
| `mobile:*` | **orchestration** — mobile build/setup (tauri + android + ios) |
| `mise:*` | **runner** — `global:bootstrap`, `repo:bootstrap[-delete]`, `sweep`, `upgrade` |

### Tools

A repo's `[tools]` lists only what's unique to it. Runtime-free binaries (nushell,
fnox, gh, jq, usage, git-cliff) live in the **global** config
(`mise:global:bootstrap`); tools needing node/ruby live **per-task**. **Rust = rustup
+ per-repo `rust-toolchain.toml`, NEVER mise** (mise exports `RUSTUP_TOOLCHAIN`, which
overrides the file); `ci:check-global` enforces this.

### Secrets

`fnox` = local keychain (`fnox set -p keychain`); `secrets:bw-*` syncs to NodeWarden;
CI reads GitHub Actions secrets and **never** runs fnox.

### Nushell tips

`$"($var)"` interpolates, `$"\(lit\)"` is literal parens; `glob` (not `ls`) expands a
path pattern; lists need commas; detect the repo via `git remote get-url origin`.

---

## 5. Developing this repo

Version pins protect consumers (an old `?ref=` is immutable), so **refactor deeply** —
rename, merge, move, delete. Being timid is the bug; the version pin is the safety net.

### Order of operations — ALWAYS this order

1. **EDIT** here — a task in `tasks/<ns>.toml`, the `fleet` skill, or a workflow.
2. **VALIDATE in BOTH local and CI** — a change must pass both before you ship it. The
   loop, mirroring §2's local-first rule:

   ```
   edit → mise run ci                 # locally FIRST — the same task CI runs
        → git push                    # .github main (rolling, untagged — NO tag yet)
   # then validate as a real consumer, in .github-example (consumes .github@main):
        → purge mise's include cache  # ?ref=main / @main is cached
        → mise run mise:repo:bootstrap-delete && mise run mise:repo:bootstrap
        → mise run ci                 # local green, THEN
        → git push                    # triggers the OS matrix
   ```

   The example's CI fetches `joeblew999/.github@main` on the runner, so every change
   must be **pushed** before CI can see it — the local-path-include trick only speeds
   the local loop, it never substitutes for the push. `.github` also **dogfoods**
   itself: its own CI *runs* the credential-free tasks across the matrix (not just
   parses them), so cross-OS bugs surface here, not in consumers. Local can pass while
   CI fails (a tool global on your box but absent on a runner) — check both.
3. **RELEASE** only once it works: `mise run release:github -- vX.Y.Z` (changelog →
   tag → GitHub release). **Run the task, don't just parse it** — parse-clean ≠
   runtime-correct (`ls <glob>` fails, use `glob`; `{{…}}` in a body is Tera).
4. **CONSUMERS ADOPT** by bumping `?ref=` / `@ref` / plugin version.

### Tags are APPEND-ONLY

The refactor-deeply safety net only holds if tags never move. **NEVER delete or
re-point a published tag.** A consumer may be pinned to *any* tag; deleting it 404s
their includes and kills their CI (this already happened — deleting `v0.42.0` broke a
live consumer). A bad release is **superseded by a higher version, never deleted** —
even if red, even if mis-numbered, leave it. And **only tag AFTER the OS matrix is
green** (local green is one cell, not the whole matrix).

### Key tasks

`mise:global:bootstrap`, `release:github -- vX.Y.Z [assets]`, `release:pack [-- --dir
D]`, `docker:image -- vX.Y.Z`, `cliff:unreleased`, `ci:check-global`, `ci:check-nu`,
`docs:gen` (regenerates the §3 tables).

---

## 6. Upgrading (migration)

Old `?ref=` tags are **immutable** — your repo keeps working until you bump.
Per-version detail is in [CHANGELOG.md](./CHANGELOG.md) (git-cliff generated, never
hand-edited). This section lists only the **breaking** versions that renamed
files/tasks; everything else is additive.

**To adopt a newer version (additive bump):**

1. Pick the newest tag from
   [Releases](https://github.com/joeblew999/.github/releases).
2. Bump every `?ref=` in `mise.toml` `[task_config].includes` to it.
3. `mise run mise:repo:bootstrap` → `mise run ci` locally → green → push → confirm the
   matrix is green.

Re-running the bootstrap is always safe + idempotent — it brings the repo to exactly
the current canonical shape. If your jump **crosses a breaking version below**, do
that version's rename steps first.

### BREAKING → v0.40.0 (two-layer restructure)

`tasks/` split into **pure `tool-*` primitives** + **5 orchestration namespaces**
(`ci · secrets · cfapp · release · mobile`). Files and task namespaces were renamed.

**1. Bump every `?ref=`** to the newest tag (anything `≥ v0.40.0` has this layout).

**2. Rename the include filenames you use:**

| old | new |
|---|---|
| `tasks/cf.toml` | `tasks/tool-cf.toml` |
| `tasks/gh.toml` | `tasks/tool-gh.toml` |
| `tasks/docker.toml` | `tasks/tool-docker.toml` |
| `tasks/cliff.toml` | `tasks/tool-cliff.toml` |
| `tasks/rust.toml` | `tasks/tool-rust.toml` |
| `tasks/wrangler.toml` | `tasks/tool-wrangler.toml` |
| `tasks/fnox.toml` | `tasks/tool-fnox.toml` |
| `tasks/bw.toml` | `tasks/secrets-bw.toml` |
| `tasks/provision.toml` **+** `tasks/prove.toml` | `tasks/cfapp.toml` |
| `tasks/env.toml` | **removed** — delete the include |

(`ci.toml`, `mise.toml`, `release.toml`, `secrets.toml`, `mobile.toml` keep their names.)

**3. Rename any task you invoke** (grep the whole repo — `mise.toml`, shell, CI yml, docs):

| old | new |
|---|---|
| `mise:global` | `mise:global:bootstrap` |
| `ci:watch` / `ci:clean` | `gh:run-watch` / `gh:run-clean` |
| `ci:check-toml-tasks` / `ci:check-workflow-nu` / `ci:parse-check` | `ci:check-nu` |
| `bw:<x>` | `secrets:bw-<x>` |
| `cf:provision-*` / `provision:*` | `cfapp:provision-*` |
| `cf:access-*` / `cf:service-token-*` / `provision:access-*` | `cfapp:access-*` / `cfapp:service-token-*` |
| `cf:secrets-put-mapped` | `cfapp:provision-secrets` |
| `prove:bindings`/`secrets`/`deployed`/`access-policy` | `cfapp:verify-bindings`/`-secrets`/`-deployed`/`-access-policy` |

(The `cf:*` primitives — `d1-create`/`r2-create`/`queue-create`/`secret-put`/`token-check`
— are now pure wrangler/curl and read the CF token from `$env`; you drive them via
`cfapp:*`, which provides the token from fnox.)

**4. Re-bootstrap + verify:** `mise run mise:repo:bootstrap`, then `mise run ci`
**locally**, then push and confirm the matrix is green. Don't skip the local run.
