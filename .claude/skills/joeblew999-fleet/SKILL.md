---
name: joeblew999-fleet
description: How to work in any joeblew999 fleet repo — the joeblew999/.github distribution flows (mise task includes, reusable CI, mise:global, this skills marketplace), the namespace=tool rule, releasing via release:github, and "distribute by reference, never copy/stamp files". Use when touching mise.toml/tasks, CI workflows, releases, rust toolchains, or onboarding a repo to .github.
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
| **global tools** | `mise run mise:global` | latest |
| **claude skills (this)** | `claude plugin marketplace add joeblew999/.github` + install `fleet` | plugin version |

Onboarding a repo = writing those small wiring lines (by hand / by you, the
agent — there is no copy tool). Upgrading = bump `?ref=`/`@ref`/plugin version.
Old refs are immutable, so nothing breaks — which is why .github should be
refactored DEEPLY, never surface-patched.

## NAMESPACE = TOOL

Each task namespace = one tool: `mise:` (mise), `cliff:` (git-cliff changelog
queries ONLY), `docker:` (docker), `ci:` (guards). Orchestration that composes
tools gets its OWN namespace: **`release:`** — `release:github` (changelog + tag
+ push + gh release + verified upload) and `release:pack` (tar.gz a staging dir).
Never put a task in another tool's namespace.

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
