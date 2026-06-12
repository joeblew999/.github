---
name: joeblew999-fleet
description: How to work in any joeblew999 fleet repo — the joeblew999/.github distribution flows (mise task includes, reusable CI that runs local==remote, mise:global:bootstrap, this skills marketplace), the two-layer model (pure tool-* primitives + orchestration), releasing via release:github, and "distribute by reference, never copy/stamp files". Use when touching mise.toml/tasks, CI workflows, releases, rust toolchains, or onboarding a repo to .github.
---

# joeblew999 fleet conventions

Every repo shares tooling + agent conventions from **joeblew999/.github** (whose
`AGENTS.md` is the full SSOT). Work *with* the flows below; never reinvent them.

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

Two **optional** dials, each where it must live — the single command never changes:
- **local vs remote** for a heavy task → `DOCKER_BUILD = "ci"` (`auto`·`ci`·`local`·
  `never`) in `mise.toml` `[env]` — the task reads it at runtime (`$env.CI`). Default
  `auto` = build wherever capable.
- **which OSes** the matrix runs → `--os-matrix` at `mise:repo:bootstrap` (it lives
  in the workflow because GitHub picks the matrix before mise starts).

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
Fork version scheme: `vX.Y.Z-jb.N`.

## Always RUN tasks, don't just parse

parse-clean ≠ runtime-correct (`ls <glob-string>` fails → use `glob`; `{{…}}` in
a mise task body is Tera, not literal). Verify locally before pushing, especially releases.
