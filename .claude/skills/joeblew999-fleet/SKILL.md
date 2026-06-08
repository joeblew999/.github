---
name: joeblew999-fleet
description: How this repo plugs into the joeblew999 fleet — mise tasks from joeblew999/.github, the namespace=tool convention, releases via release:github, and how to re-stamp. Use when working on mise.toml tasks, CI, releases, or onboarding wiring in any joeblew999 repo.
---

# joeblew999 fleet conventions

This repo consumes the shared mise task library at **joeblew999/.github**, pinned
by tag (`?ref=vX.Y.Z`) in `mise.toml` `[task_config].includes`. The canonical
source of truth is that repo's `AGENTS.md`.

## Do everything through mise — locally AND in CI

Every operation is a `mise run <task>`. CI runs the *same* task, so if it works
locally it works in CI. Never hand-write CI steps that duplicate a task.

- Build/test/lint/release: mise tasks (some shared from .github, some repo-local).
- CI = `joeblew999/.github/.github/workflows/reusable-mise-ci.yml@<tag>` running one task.

## NAMESPACE = TOOL

Each task namespace maps to one tool; orchestration gets its own namespace:
- `mise:*` mise · `cliff:*` git-cliff (changelog queries only) · `docker:*` docker
- `release:*` release orchestration: **`release:github`** (changelog+tag+push+gh
  release+verified upload) and **`release:pack`** (tar.gz a staging dir)
- `ci:*` guards · `rust:* cf:* wrangler:* bw:* secrets:* …` their tool/domain

Never put a task in another tool's namespace.

## Rust toolchain (if this is a Rust repo)

Owned by **rustup + `rust-toolchain.toml`**, NEVER mise (mise exports
`RUSTUP_TOOLCHAIN`, which overrides the toolchain file). `ci:check-global` fails
if `rust`/`RUSTUP_TOOLCHAIN` appears in any mise config.

## Cutting a release

```sh
mise run release:pack -- --dir <staging-dir>     # if shipping binaries
mise run release:github -- vX.Y.Z [archives...]  # changelog+tag+push+release+upload
```
Fork version scheme: `vX.Y.Z-jb.N`.

## Re-stamping wiring + skills

`mise run stamp:repo` (re)stamps the .github CI workflow stub + claude skills
into this repo and prints the includes block. Bump the `?ref=` to adopt newer
shared tasks — old refs keep working, so it's always safe.

## .github is version-protected

When you fix the shared lib, refactor **deeply** — consumers pin tags, so `main`
changes can't break them. Don't leave cruft; ship a new tag.
