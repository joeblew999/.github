# joeblew999/.github

Shared mise task library + Claude plugin marketplace + agent conventions for the
whole joeblew999 fleet.

## Order of operations — ALWAYS this order (READ FIRST)

1. **EDIT** here — a task in `tasks/<ns>.toml`, the `fleet` skill, or a workflow.
2. **VALIDATE** in the sandbox
   [`.github-example`](https://github.com/joeblew999/.github-example): it includes
   this repo by *local, unversioned path*, so `mise run <task>` there tests the
   edit instantly. Loop 1↔2 — **no release while iterating.**
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

## Refactor DEEPLY — this repo is version-protected

You **cannot break a consumer** by changing `main` — they pin tags. So fix cruft
**now**: rename, merge, delete, move across files, break things. Then
`mise run release:github -- vX.Y.Z`. Never leave it "for later" or surface-patch.
Being timid is the bug; the version pin is the safety net.

## NAMESPACE = TOOL

Each namespace = exactly one tool; a task NEVER lives in another tool's namespace.
Orchestration that composes tools gets its OWN namespace (e.g. `release:`).

| Namespace | Tool / role |
|---|---|
| `mise:*` | mise (`global`, `sweep`, `upgrade`) |
| `cliff:*` | git-cliff — **changelog queries only** (`unreleased`/`show`/`repo`) |
| `release:*` | release orchestration (cliff+git+gh): `release:github`, `release:pack` |
| `docker:*` | docker (`login`/`image`/`settings`) |
| `ci:*` | guards (`check-toml-tasks`/`check-global`/`audit-lib-refs`) |
| `rust:* cf:* wrangler:* bw:* secrets:* fnox:* prove:* mobile:* env:*` | their tool/domain |

Name implies one tool but drives others? Mis-named — move it. (`cliff:release`
was wrong → it's `release:github`.)

## Tools

A repo's `[tools]` lists only what's unique to it. Runtime-free binaries
(nushell, fnox, gh, jq, usage, git-cliff) live in the **global** config
(`mise:global`); tools needing node/ruby/rust are pinned **per-task**.
**Rust = rustup + per-repo `rust-toolchain.toml`, NEVER mise** (mise exports
`RUSTUP_TOOLCHAIN` which overrides the file); `ci:check-global` enforces this.

## Working in THIS repo

1. Edit `tasks/<ns>.toml` — nushell, no pins for global tools.
2. **RUN the task, don't just parse it** — parse-clean ≠ runtime-correct (e.g.
   `ls <string-with-glob>` fails; use `glob`; `{{…}}` in a task body is Tera, not
   a literal). `mise run ci:check-toml-tasks` parses; you still must *run* changed tasks.
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
