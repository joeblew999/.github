# joeblew999/.github

Shared mise task library + agent conventions for the whole joeblew999 fleet.
Each `tasks/<ns>.toml` is a namespace of nushell tasks a repo includes, pinned.

## 1. The flows — how this reaches a repo (READ FIRST)

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

## 2. Refactor DEEPLY — this repo is version-protected

You **cannot break a consumer** by changing `main` — they pin tags. So fix cruft
**now**: rename, merge, delete, move across files, break things. Then
`mise run release:github -- vX.Y.Z`. Never leave it "for later" or surface-patch.
Being timid is the bug; the version pin is the safety net.

## 3. NAMESPACE = TOOL

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

## 4. Tools

A repo's `[tools]` lists only what's unique to it. Runtime-free binaries
(nushell, fnox, gh, jq, usage, git-cliff) live in the **global** config
(`mise:global`); tools needing node/ruby/rust are pinned **per-task**.
**Rust = rustup + per-repo `rust-toolchain.toml`, NEVER mise** (mise exports
`RUSTUP_TOOLCHAIN` which overrides the file); `ci:check-global` enforces this.

## 5. Working in THIS repo

1. Edit `tasks/<ns>.toml` — nushell, no pins for global tools.
2. **RUN the task, don't just parse it** — parse-clean ≠ runtime-correct (e.g.
   `ls <string-with-glob>` fails; use `glob`; `{{…}}` in a task body is Tera, not
   a literal). `mise run ci:check-toml-tasks` parses; you still must *run* changed tasks.
3. `mise run release:github -- vX.Y.Z`.

Key tasks: `mise:global`, `release:github -- vX.Y.Z [assets]`, `release:pack
[-- --dir D]`, `docker:image -- vX.Y.Z`, `cliff:unreleased`, `ci:check-global`.

## 6. Nushell

`$"($var)"` interpolates, `$"\(lit\)"` literal parens; `glob` (not `ls`) expands a
path pattern; lists need commas; detect repo via `git remote get-url origin`.

## 7. Secrets

`fnox` = local keychain (`fnox set -p keychain`); `bw:*` syncs to NodeWarden; CI
reads GH Actions secrets, never runs fnox.

---
Every consumer repo should carry a `CLAUDE.md` that points an agent here before it
touches mise/CI/release/skills — so it works with the flows above, not against them.
