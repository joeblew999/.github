---
name: joeblew999-fleet
description: How to work in any joeblew999 fleet repo — the joeblew999/.github distribution flows (mise task includes, reusable CI that runs local==remote, mise:global:bootstrap, this skills marketplace), the two-layer model (pure tool-* primitives + orchestration), releasing via release:github, and "distribute by reference, never copy/stamp files". Use when touching mise.toml/tasks, CI workflows, releases, rust toolchains, or onboarding a repo to .github.
---

# joeblew999 fleet conventions

Every repo shares tooling + agent conventions from **joeblew999/.github** (whose
root `README.md` is the full SSOT). Work *with* the flows below; never reinvent them.

## Distribution is BY REFERENCE + versioned — never copy/stamp files

If you're about to clone or copy .github content into a repo, **STOP — you are
reinventing.** All four channels already exist:

| What | Wiring (add to the repo) | Versioned by |
|---|---|---|
| **mise tasks** | `mise.toml` → `[task_config].includes = ["git::https://github.com/joeblew999/.github.git//tasks/<ns>.toml?ref=vX"]` | `?ref=` |
| **CI** | `.github/workflows/*.yml` → `uses: joeblew999/.github/.github/workflows/reusable-mise-ci.yml@vX` (runs one `mise run <task>`) | `@ref` |
| **global tools** | `mise run mise:global:bootstrap` | latest |
| **claude skills (this)** | `claude plugin marketplace add joeblew999/.github` + install `fleet` | plugin version |

Onboarding a repo = writing those small wiring lines (by hand / by you, the
agent — there is no copy tool). Upgrading = bump `?ref=`/`@ref`/plugin version.
Old refs are immutable, so nothing breaks — which is why .github should be
refactored DEEPLY, never surface-patched.

## Two layers (the filename shows which)

`tasks/` splits into:
- **`tool-*.toml`** — pure tool **primitives**. Each drives ONLY its own tool
  (+ ubiquitous plumbing `git`/`curl`/`tar`); **no `fnox`, no foreign tool**.
- **plain `*.toml`** — **orchestration** namespaces (`ci secrets cfapp release
  mobile`) that compose tool tasks (`mise run`/`depends`) and own the cross-tool
  work + the `fnox`→`$env` bridge. (Plus `mise` = the runner.)

A tool file that drives another tool's binary or reaches into `fnox` is
mis-placed → push that work UP to an orchestration file. **Secrets flow DOWN:**
orchestration reads `fnox`, sets `$env`, then `mise run`s the pure primitive
(child inherits the env). The README's two-layer tables are *generated* from each
file's `# role:` header (`mise run docs:gen`; CI fails if stale) — so add a
`# role:` line to any new task file.

## CI: one `mise run ci`, local AND remote — main lever is `[tasks.ci].depends`

A repo's CI is one task — `mise run ci` — run identically on **your machine** and
the **GitHub matrix** (ubuntu+macos+windows). Run it **locally first**; green
locally ⇒ green for that OS in CI. The lever is a local `ci` that `depends` on your
tasks (mise merges with the shared guards): that list IS the CI. Each task
self-skips where it can't run; `rust:test` compiles a native binary per matrix OS.

**All tuning lives in `mise.toml`** — you never hand-edit the workflow, and
**re-bootstrap preserves it** (bootstrap reads `[env]`, never writes `mise.toml`):
- **local vs remote** for a heavy task → `[env]` `DOCKER_BUILD = "ci"` (`auto`·`ci`·
  `local`·`never`); the task reads `$env.CI` at runtime. Default `auto`.
- **which OSes** the matrix runs → `[env]` `CI_OS_MATRIX = '[...]'` (also `CI_TASK`,
  `CI_RELEASE`, `CI_BUILD_TASK`). Bootstrap **projects** these into the workflow, so
  apply with a re-bootstrap (GitHub reads the matrix before mise starts). Flags
  (`--os-matrix`, …) still work for a one-off.

`ci` *verifies* every push; *publishing* binaries/images is a separate opt-in
(`mise:repo:bootstrap --release`, on a git **tag**). Copy
[`.github-example`](https://github.com/joeblew999/.github-example).

## Rust toolchain

Owned by **rustup + `rust-toolchain.toml`, never mise** (mise exports
`RUSTUP_TOOLCHAIN`, which overrides the file). `ci:check-global` enforces it.

## Releasing

```sh
mise run release:pack -- --dir <staging>      # if shipping binaries
mise run release:github -- vX.Y.Z [archives]  # changelog + tag + push + release + upload
```

### Fork version scheme: own version line (NO suffix)

A fork releases on its **own clean semver line** — `vX.Y.Z`, no pre-release
suffix (NOT `-jb.N`, NOT `-relay-url.N`). The fork's numbers are **independent**
of upstream's; record the upstream base in the CHANGELOG (and an `UPSTREAM` file),
e.g. *"based on upstream v0.20.0"*.

Why no suffix: a `-suffix` is a semver PRE-RELEASE, which sorts BELOW the bare
version (SemVer §11: `1.0.0-jb.1 < 1.0.0`). That made `latest` / `mise --bump` /
unpinned `gh release download` pick a bare upstream tag over the newer fork build
(it bit us: `mise latest joeblew999/http-nu` returned `0.17.0`, not the installed
`0.16.0-relay-url.3`). A clean own-line version sorts correctly → `latest` works.

Rules:
- **One independent line per fork.** Bump it on every fork release; don't reset
  to mirror upstream's number. (Old `-jb.N` tags are deprecated — supersede on
  the next release; see each fork's CHANGELOG for the cutover.)
- **Never publish a bare upstream-mirror tag** in a fork repo (e.g. tagging a
  plain `v0.17.0` straight from a rebase). Only tag the fork's own line — a
  stray mirror tag outranks/clashes with it.
- **Docker-image forks** (corrosion) follow the same line; image tags are pinned
  by exact string.
- Consumers still **pin** an explicit version for reproducibility (now `latest`
  is at least correct as a fallback).

## Always RUN tasks, don't just parse

parse-clean ≠ runtime-correct (`ls <glob-string>` fails → use `glob`; `{{…}}` in
a mise task body is Tera, not literal). Verify locally before pushing, especially releases.
