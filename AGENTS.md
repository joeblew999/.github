# joeblew999/.github

Shared mise task library + Claude plugin marketplace + agent conventions for the
whole joeblew999 fleet.

## Keep .github-example repo matching 

**Docs SSOT.** The root [README.md](./README.md) is the single source for how this
repo is used + how the reusable system works. Whenever you change a bootstrap
command, task, or the reusable flow, update README to match **exactly** what
`.github-example` runs, and keep every command idempotent. Don't duplicate it
elsewhere — `.github/workflows/README.md` and the `reusable-*.yml` headers just
point here.

## Testing Example works

The example's CI fetches joeblew999/.github@main on the runner, so every .github change must be pushed before CI can see it. The local-path-include trick only accelerates the local loop; it never substitutes for the push when you want CI (or the remote-pinned example) to validate.

## Cross-platform or it's broken (READ FIRST)

Every repo here must work on **macOS, Linux AND Windows**. Therefore:

- **All task logic is nushell** (`#!/usr/bin/env nu`) — never bash/sh/PowerShell,
  never a `.sh` file. No bash-isms, no hardcoded `/Users`, `/home`, `/opt` paths;
  derive from env + install state.
- A task that is a **single plain command** mise runs in the default shell (e.g.
  `mise:global` = `mise use -g …`) is fine — it's not shell-specific.
- The **bootstrap before nu exists** is bare `mise` commands ONLY. nu is installed
  by `mise run mise:global`, so the bootstrap can't be written in nu either — mise
  is the one cross-platform tool guaranteed present. (See README "New repo".)

If you reach for a shell script, you've already broken the rule. Write a nu task.

## Order of operations — ALWAYS this order (READ FIRST)

1. **EDIT** here — a task in `tasks/<ns>.toml`, the `fleet` skill, or a workflow.
2. **VALIDATE in BOTH local and CI** — a change must pass both before you ship it.
   Push `.github` `main` (unversioned/rolling — no tag yet), then in the sandbox
   [`.github-example`](https://github.com/joeblew999/.github-example) (consumes
   `.github@main`):
   - **local:** `mise run <task>` (clear mise's git-include cache to pull new main).
   - **CI:** its `mise.yaml` runs the shared `reusable-mise-ci.yml@main` → the same
     task on a clean runner. (`.github` also self-validates via `tasks-toml-proof.yml`.)
   Loop — **no release/tag while iterating.** Local can pass while CI fails (a tool
   global on your box but absent on a runner) — so check both.
3. **RELEASE** only once it works: `mise run release:github -- vX.Y.Z`
   (changelog → tag → GitHub release).
4. **CONSUMERS ADOPT** by bumping `?ref=` / `@ref` / plugin version. Old refs are
   immutable → nothing breaks → which is why you refactor here DEEPLY, never surface-patch.

## The flows — what reaches a repo (by reference + versioned; never copy)

Everything is distributed **BY REFERENCE + versioned. Nothing copies files into
repos.** If you find yourself writing code to clone/copy/"stamp" .github content
into a repo, **STOP — you are reinventing.** The mechanism already exists:

| What | Mechanism (already exists) | Versioned by | Scope |
|---|---|---|---|
| **mise tasks** | `[task_config].includes = ["git::…/tasks/<ns>.toml?ref=vX"]` in the repo's `mise.toml` | `?ref=` | per repo |
| **CI** | `.github/workflows/*.yml` → `uses: …/reusable-mise-ci.yml@vX` (runs `mise run <task>`) | `@ref` | per repo |
| **global tools** | `mise run mise:global` | latest | per machine |
| **claude skills** | this repo IS a Claude plugin **marketplace** — `claude plugin marketplace add joeblew999/.github` + install `fleet` | plugin version | per machine |

A repo "upgrades" by bumping `?ref=`/`@ref` or its installed plugin. Old refs are
immutable, so nothing breaks. **Before building anything fleet-wide: search the
fleet for the existing mechanism (grep tasks/, check known_marketplaces.json).**

## How a CONSUMER adopts .github — in this order

The canonical minimal example is
[`.github-example`](https://github.com/joeblew999/.github-example) — copy its shape.

1. **Skills + conventions** — `claude plugin marketplace add joeblew999/.github`, install `fleet` (or read this file).
2. **`CLAUDE.md`** in the repo root, pointing agents at this AGENTS.md.
3. **mise tasks** — `mise.toml` `[task_config].includes` the namespaces you need, pinned `?ref=vX`.
4. **global tools** — `mise run mise:global` (once per machine).
5. **Rust?** — pin in `rust-toolchain.toml` (rustup), never mise.
6. **CI** — **bootstrap:** *Actions → New workflow → "mise CI (joeblew999)"* (the
   org **workflow-template**) — one click writes `.github/workflows/mise.yaml`
   (a stub calling `reusable-mise-ci.yml`). **Update:** the scheduled
   `reusable-mise-upgrade` PR bumps everything in one PR — tool versions
   (`mise:upgrade`) **and** the `?ref=`/`@ref` pins (`ci:audit-lib-refs --write`).

Then `mise run <task>` works locally and CI runs the same task. A consumer adds
ONLY its own repo-specific tasks/tools; everything shared comes from above.

## Refactor DEEPLY — this repo is version-protected

You **cannot break a consumer** by changing `main` — they pin tags. So fix cruft
**now**: rename, merge, delete, move across files, break things. Then
`mise run release:github -- vX.Y.Z`. Never leave it "for later" or surface-patch.
Being timid is the bug; the version pin is the safety net.

## NAMESPACE = TOOL (+ an orchestration tier)

Each namespace is **one tool**; a task never lives in another tool's namespace.
A few namespaces are **orchestration/domain** — they compose several tools, and
say so plainly: `release` (cliff+git+gh), `ci` (guards), `secrets` (fnox+gh),
`prove` (deploy checks), `mobile` (tauri+android+ios).

| Namespace | Tool / role |
|---|---|
| `mise:*` | mise (`global:bootstrap`, `repo:bootstrap[-delete]`, `sweep`, `upgrade`) |
| `gh:*` | gh — GitHub Actions **run** mgmt (`run-watch`, `run-clean`) |
| `cliff:*` | git-cliff — changelog queries (`unreleased`/`show`/`repo`) |
| `docker:*` | docker (`login`/`image`/`settings`) |
| `bw cf fnox rust wrangler env` | each its own tool |
| `release:*` | **orchestration** (cliff+git+gh): `release:github`, `release:pack` |
| `ci:*` | **static guards** (`check-nu`/`check-global`) + ref drift (`audit-lib-refs [--write]`) |
| `provision:*` | **orchestration** — reads config/<env>.env, composes `cf:*` primitives (`d1-r2`, `queues`, `secrets`) |
| `secrets prove mobile` | **orchestration/domain** (compose tools) |

Name implies one tool but drives others? Mis-named — move it. (`cliff:release`
→ `release:github`; `ci:watch`/`ci:clean` → `gh:run-watch`/`gh:run-clean`.)

## Tools

A repo's `[tools]` lists only what's unique to it. Runtime-free binaries
(nushell, fnox, gh, jq, usage, git-cliff) live in the **global** config
(`mise:global:bootstrap`); tools needing node/ruby/rust are pinned **per-task**.
**Rust = rustup + per-repo `rust-toolchain.toml`, NEVER mise** (mise exports
`RUSTUP_TOOLCHAIN` which overrides the file); `ci:check-global` enforces this.

## Working in THIS repo

1. Edit `tasks/<ns>.toml` — nushell, no pins for global tools.
2. **RUN the task, don't just parse it** — parse-clean ≠ runtime-correct (e.g.
   `ls <string-with-glob>` fails; use `glob`; `{{…}}` in a task body is Tera, not
   a literal). `mise run ci:check-nu` parses; you still must *run* changed tasks.
3. `mise run release:github -- vX.Y.Z`.

Key tasks: `mise:global`, `release:github -- vX.Y.Z [assets]`, `release:pack
[-- --dir D]`, `docker:image -- vX.Y.Z`, `cliff:unreleased`, `ci:check-global`.

## Nushell

`$"($var)"` interpolates, `$"\(lit\)"` literal parens; `glob` (not `ls`) expands a
path pattern; lists need commas; detect repo via `git remote get-url origin`.

## Secrets

`fnox` = local keychain (`fnox set -p keychain`); `bw:*` syncs to NodeWarden; CI
reads GH Actions secrets, never runs fnox.

---
Every consumer repo should carry a `CLAUDE.md` that points an agent here before it
touches mise/CI/release/skills — so it works with the flows above, not against them.
