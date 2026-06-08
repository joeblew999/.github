# joeblew999/.github

Shared mise task library + agent config, consumed by every joeblew999 repo.
Each `tasks/<ns>.toml` is a namespace of nushell tasks; a repo includes the ones
it wants, **pinned by tag** (`?ref=vX.Y.Z`).

## ⚠️ Refactor DEEPLY — this repo is version-protected

**You cannot break any consumer by refactoring here.** Every repo pins a tag
(`?ref=vX.Y.Z`); old tags are immutable, so existing consumers keep working no
matter what `main` does. A consumer only sees your changes when it *chooses* to
bump its `?ref=`.

So when you see duplication, mis-named tasks, layers-on-layers, or a task in the
wrong namespace: **fix it properly, now.** Rename, merge, delete, move across
files — whatever it takes. Do NOT leave cruft "for later" or do a surface patch.
Then `mise run release:github -- vX.Y.Z` and the new shape ships as a new tag.
Breaking changes are fine — note them in the commit and bump appropriately.

Being timid here is the bug. The version pin is the safety net; use it.

## NAMESPACE = TOOL

Each namespace maps to exactly one tool. A task NEVER lives in another tool's
namespace. High-level orchestration that composes several tools gets its OWN
namespace (e.g. `release:`), it is not jammed into one of them.

| Namespace | Tool / role |
|---|---|
| `mise:*` | mise itself (`global`, `sweep`, `upgrade`) |
| `cliff:*` | git-cliff **changelog queries only** (`unreleased`, `show`, `repo`) |
| `release:*` | release orchestration (git-cliff + git + gh): `release:github`, `release:pack` |
| `docker:*` | docker (`login`, `image`, `settings`) |
| `ci:*` | CI guards (`check-toml-tasks`, `check-global`, `audit-lib-refs`, …) |
| `rust:* cf:* wrangler:* bw:* secrets:* fnox:* prove:* mobile:* env:*` | their named tool/domain |

If a task's name implies one tool but it drives others, it's mis-named — move it.
(`cliff:release` was wrong: it did git+gh+cliff → it's now `release:github`.)

## How tools work

A repo's `[tools]` lists only what's unique to it. Shared tools live in:

| Tool kind | Lives in | Examples |
|---|---|---|
| Runtime-free binary | the **global** config — `mise run mise:global` | nushell, fnox, gh, jq, usage, git-cliff |
| Needs node/ruby/rust | the **task** that uses it (per-task `tools`) | wrangler, bitwarden, java, wasm-pack |

Rust is special: it is **owned by rustup + per-repo `rust-toolchain.toml`, never
mise** (mise exports `RUSTUP_TOOLCHAIN`, which overrides the toolchain file).
`ci:check-global` enforces this — no `rust`/`RUSTUP_TOOLCHAIN` in any mise config.

## Key tasks

| Task | Does |
|---|---|
| `mise:global` | install the global toolset (CI runs the same task) |
| `mise:sweep` | prune orphaned tool installs |
| `release:github -- vX.Y.Z [assets...]` | git-cliff CHANGELOG → commit → tag → push → GitHub release → upload+verify assets |
| `release:pack [-- --dir DIR]` | tar.gz each subdir of a staging dir (goreleaser-style names) |
| `cliff:unreleased` / `cliff:show` / `cliff:repo <owner/repo>` | changelog queries |
| `docker:login` / `docker:image -- vX.Y.Z` | ghcr auth + multi-arch build+push+verify |
| `ci:check-toml-tasks` / `ci:check-global` / `ci:audit-lib-refs` | guards (run locally + CI) |

## Working here

1. Edit `tasks/<ns>.toml` — nushell body, no pins for global tools.
2. `mise run ci:check-toml-tasks` (CI runs the same task) — RUN the task, don't
   just parse it (parse-clean ≠ runtime-correct; e.g. `ls path-with-glob` needs `glob`).
3. `mise run release:github -- vX.Y.Z`.

## Consuming (.github wiring — add to the repo's mise.toml)

```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//tasks/mise.toml?ref=<tag>",
  "git::https://github.com/joeblew999/.github.git//tasks/<ns>.toml?ref=<tag>",
]
[tools]    # repo-specific only — globals come from `mise run mise:global`
```

CI: `uses: joeblew999/.github/.github/workflows/reusable-mise-ci.yml@<tag>` with
`{ task: ci }` (or `build`). Everything CI runs is a mise task, so it runs locally first.

## How we stamp out to repos (the flows)

Everything is distributed **by reference and versioned** — nothing copies files
into repos. There are several distinct mechanisms; know which is which:

| What | Mechanism | Versioned by | Scope |
|---|---|---|---|
| **mise tasks** | `[task_config].includes = ["git::…/tasks/<ns>.toml?ref=vX"]` in the repo's `mise.toml` | `?ref=` | per repo |
| **CI** | `.github/workflows/*.yml` → `uses: …/reusable-mise-ci.yml@vX` | `@ref` | per repo |
| **global tools** | `mise run mise:global` | (floats to latest) | per machine |
| **claude skills** | Claude Code plugin **marketplace** (`claude plugin marketplace add` + install) — like the `cc-skills` `mise`/`itp` plugins | plugin version | per machine/user |

To bump what a repo gets: change its `?ref=`/`@ref` (mise tasks, CI) or update
the installed plugin (skills). Old refs/versions keep working — that's the safety
net (see the deep-refactor note above).

A repo's AGENTS.md is repo-specific (describes that project). This file is the
single source of truth for the SHARED conventions every repo's agents inherit.

## Nushell

- `$"($var)"` interpolates; `$"\(lit\)"` is literal parens.
- `glob` to expand a path pattern (`ls` does NOT glob a string path).
- Lists need commas; `sort | uniq` to dedupe; parse-check is `nu --ide-check 1 <f>`.
- Detect repo via `git remote get-url origin`.

## Secrets

`fnox` = local keychain store (`fnox set -p keychain`); `bw:*` syncs it to
self-hosted NodeWarden; CI reads GH Actions secrets, never runs fnox.
