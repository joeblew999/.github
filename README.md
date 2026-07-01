# joeblew999/.github

Shared **mise task library** + Claude plugin marketplace + GitHub org config for
the fleet. Every capability is a **mise task**, shared **by reference** (`?ref=` /
`@ref`, never copied), and **runs the same locally as in CI**.

Platform systems map: **[SYSTEMS.md](./SYSTEMS.md)** (auth → `iam`, deploy →
`vm-uncloud`, …) · Agent guide: [AGENTS.md](./AGENTS.md) · history:
[CHANGELOG.md](./CHANGELOG.md) · example consumer:
[.github-example](https://github.com/joeblew999/.github-example).

**New repo?** Start at §1 below. **Upgrading an existing repo?** → [MIGRATION.md](./MIGRATION.md).

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

> green locally ⇒ green for *that* OS in CI. Push, and the matrix runs the
> identical task on the other OSes. **Always run it locally first** — pushing
> untested is the only thing that breaks CI.

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
[`.github-example`](https://github.com/joeblew999/.github-example) does exactly this
— copy it.

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
Note the two OS knobs are independent: **CI** verifies on all 3 OSes by default, but
**publish** defaults to ubuntu + macOS — set `CI_RELEASE_OS_MATRIX` to add windows.

> **Verify vs publish.** `ci` *verifies* on every push (cheap, no secrets) — and the
> matrix compiles a native binary per OS. *Publishing* downloadable binaries/images
> is a **separate opt-in** — `mise run mise:repo:bootstrap --release` — which runs on
> a git **tag**, not every push, with its own os-matrix.

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

**The one rule:** plumbing (`git`/`curl`/`tar`) is fine anywhere. A *tool* file
that drives another tool's binary or reaches into `fnox` is mis-placed — push that
up to an orchestration file. Secrets flow **down**: orchestration reads `fnox`,
sets `$env`, then `mise run`s the pure primitive (the child inherits the env).

---

## 4. Developing this repo

Version pins protect consumers (an old `?ref=` is immutable), so **refactor
deeply** — rename, merge, move. The loop, mirroring §2's local-first rule:

```
edit → mise run ci                 # locally FIRST — the same task CI runs
     → git push                    # .github main (rolling, untagged)
# then validate as a real consumer, in .github-example:
     → purge mise's include cache  # ?ref=main is cached
     → mise run mise:repo:bootstrap-delete && mise run mise:repo:bootstrap
     → mise run ci                 # local green, THEN
     → git push                    # triggers the OS matrix
```

`.github` also **dogfoods** itself — its own CI *runs* the credential-free tasks on
the matrix (not just parses them), so cross-OS bugs surface here, not in consumers.
Cut a release with `mise run release:github -- vX.Y.Z`.
