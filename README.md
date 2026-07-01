# joeblew999/.github

The fleet's shared **mise task library**, plus the Claude plugin marketplace and
org config. Every capability is a mise task, pulled into a repo **by reference**
(`?ref=vX` — never copied), and **run the same on your machine and in CI**.

The core idea: **`mise run ci` is your whole CI.** It runs on your OS locally and on
the ubuntu + macOS + windows matrix on push — the *same* task. Green locally means
green in CI for that OS.

- **This file is the source of truth**, for humans and agents. `AGENTS.md` /
  `CLAUDE.md` just point here.
- **Canonical consumer:** [.github-example](https://github.com/joeblew999/.github-example) —
  every change here is validated against it before release.
- **History:** [CHANGELOG.md](./CHANGELOG.md) (git-cliff generated).

---

## The fleet map

Each shared system has one **home repo** — start there. Its components live in their
own repos, linked from that home, never duplicated here.

| System | Home repo | What it is |
|---|---|---|
| **Auth** | [`cf-connectrpc-middleware`](https://github.com/joeblew999/cf-connectrpc-middleware) | Rauthy (OIDC — AuthN) + Cedar (AuthZ) + Cloudflare email. The `connectrpc-oidc` / `connectrpc-cedar` crates, Kumo client kit, `mise run stack:local`, and `docs/NEW-PROJECT.md`. |
| **Deploy** | [`vm-uncloud`](https://github.com/joeblew999/vm-uncloud) | Hetzner deployments via uncloud — recipes (Rauthy, Moltis, WordPress, Windows VMs…) and one cost ledger. |
| **Tooling** | [`.github`](https://github.com/joeblew999/.github) (this repo) | The mise task library, Claude plugin marketplace, org config. |

Add a row when a new *shared system* gets a home repo. Product repos that merely
consume the platform live on their own.

---

## Quickstart — add it to a repo

Point `mise.toml` at the task files you need and list your CI tasks:

```toml
# mise.toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//tasks/mise.toml?ref=<tag>",
  "git::https://github.com/joeblew999/.github.git//tasks/ci.toml?ref=<tag>",
]

[tasks.ci]
depends = ["rust:test"]   # your build/test tasks — THIS LIST is your CI
```

Then, once:

```sh
mise trust                      # load the config + includes
mise run mise:global:bootstrap  # seed machine tools (nu, gh, git-cliff…) — once per machine
mise run mise:repo:bootstrap    # generate .github/workflows/ (the CI stubs)
mise run ci                     # verify — the same task CI runs
```

That's the whole adoption. Two includes and a `depends` list is the minimum; add a
`tool-*` include and a task only for a feature you actually want (Rust, docker,
releases). **Copy nothing** — the [.github-example](https://github.com/joeblew999/.github-example)
shows every feature, but it's a showcase to keep them CI-tested, not a template to
clone.

Rust? Pin it in `rust-toolchain.toml` (rustup), **never** in mise — `ci:check-global`
enforces this. Agents/skills? `claude plugin marketplace add joeblew999/.github` and
install `fleet`.

---

## How CI works

One task, two places, identically:

| run it with… | where | OS coverage |
|---|---|---|
| `mise run ci` | your machine | your OS — instant, while you work |
| `git push` | GitHub Actions | the full matrix (ubuntu + macOS + windows) |

The generated `.github/workflows/mise.yml` does nothing but run that same
`mise run ci`. **Always run it locally first** — pushing untested is the only thing
that breaks CI.

**The lever is `[tasks.ci].depends`.** It lists what `mise run ci` runs. The shared
library also runs its guards (`ci:check-global`, `ci:check-nu`); add
your own tasks and they run alongside — locally and on the matrix. Add a task to check
it, remove it to stop. Set nothing and you still get the guards on all three OSes,
green out of the box; nothing compiles until you add it.

**All CI config lives in `mise.toml`.** You never hand-edit the generated workflow, and
re-bootstrap preserves your settings (bootstrap *reads* `[env]`, projects it into the
workflow, and never writes `mise.toml`).

| Knob (`[env]` unless noted) | Controls | Default | Applies |
|---|---|---|---|
| `[tasks.ci].depends` | what `ci` runs | guards only | immediately |
| `DOCKER_BUILD` | docker local vs remote | `auto` (where a linux daemon exists) | immediately |
| `CI_OS_MATRIX` | which OSes CI verifies on | all 3 | re-bootstrap |
| `CI_TASK` · `CI_SCCACHE` | CI task name · Rust build cache | `ci` · `true` | re-bootstrap |
| `CI_RELEASE` | publish binaries on a git **tag** | off | re-bootstrap |
| `CI_RELEASE_OS_MATRIX` | which OSes publish | ubuntu + macOS | re-bootstrap |
| `CI_DOCKER_IMAGE` | also push a GHCR image on a tag | off | re-bootstrap |
| `CI_DOCKERFILE` · `CI_DOCKER_CONTEXT` · `CI_DOCKER_PLATFORMS` | docker build inputs | `Dockerfile` · `.` · `linux/amd64` | immediately |
| `CI_BUILD_TASK` | build task for publish | `dist` | re-bootstrap |

The `CI_*` knobs need a re-bootstrap because GitHub reads the matrix from the workflow
before mise starts, so bootstrap projects them there. (One-off flags like
`--os-matrix` also work.)

**Verify vs publish.** `ci` *verifies* on every push (cheap, no secrets) and the matrix
compiles a native binary per OS. *Publishing* downloadable binaries/images is a
separate opt-in (`mise run mise:repo:bootstrap --release`) that runs on a **tag**, not
every push. The reusable CI caches `~/.cargo` + `target/` via
[`Swatinem/rust-cache`](https://github.com/Swatinem/rust-cache) (set `CI_SCCACHE=false`
for non-Rust repos).

---

## Docker

Two separate, opt-in things. Add the `tool-docker` include for either:

```toml
includes = [ "git::…/tasks/tool-docker.toml?ref=<tag>", … ]
```

**1. Build-check on every push** — verify your `Dockerfile` still builds. No push, no
secrets. Add `docker:build` to your CI list:

```toml
[tasks.ci]
depends = ["docker:build", …]
```

It builds wherever a linux daemon exists (the ubuntu runner, or your machine if Docker
is running) and **skips** where none does (macOS/Windows runners), so one `ci` stays
green on every OS. Pick where with `[env] DOCKER_BUILD = auto` (default) `| ci | local
| never`, and what with `CI_DOCKERFILE` / `CI_DOCKER_CONTEXT` (default `Dockerfile` /
`.`).

**2. Publish a runnable image on a tag** — build and push to GitHub Container Registry.
Turn it on in `[env]`:

```toml
[env]
CI_DOCKER_IMAGE     = "true"                     # publish an image on a git TAG
CI_DOCKERFILE       = ".docker/Dockerfile"       # if not ./Dockerfile
CI_DOCKER_PLATFORMS = "linux/amd64,linux/arm64"  # multi-arch (default linux/amd64)
GHCR_USER           = "joeblew999"               # your GH user/org (public)
```

then `mise run mise:repo:bootstrap --release` (it's a `CI_*` knob, so it needs a
re-bootstrap — which also grants the release workflow `packages: write`). On a `v*` tag
the release workflow builds and pushes:

```
ghcr.io/<owner>/<repo>:<tag>
```

Auth in CI is the built-in `GITHUB_TOKEN` — no PAT. Under the hood it runs
`mise run docker:image -- <tag>`, the same task you can run locally.

**3. Run the published image** — it's **private** by default:

```sh
fnox exec -- mise run run-image            # latest release  (a repo task wrapping docker:pull)
fnox exec -- mise run run-image -- v0.5.0  # a specific tag
mise run docker:settings -- <package>      # open ghcr visibility settings to make it public
```

Locally the GHCR token comes from your **fnox** keychain (`fnox set -p keychain
GHCR_TOKEN …`); in CI it's the `GITHUB_TOKEN`. The tasks — `docker:build`,
`docker:image`, `docker:pull`, `docker:login`, `docker:settings` — all live in
`tool-docker`.

---

## What's inside — two layers

`tasks/` splits into a **tool layer** (`tool-*.toml` — pure primitives that drive only
their own tool, no `fnox`) and an **orchestration layer** (plain `*.toml` — compose
tool tasks and own the `fnox`→`$env` bridge). The filename tells you which.

The tables below are **generated** from each task file's `# role:` header by
`mise run docs:gen`; CI fails if they drift.

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

**The one rule:** plumbing (`git`/`curl`/`tar`) is fine anywhere, but a *tool* file that
drives another tool's binary or reaches into `fnox` is misplaced — move it up to an
orchestration file. Secrets flow **down**: orchestration reads `fnox`, sets `$env`, then
`mise run`s the pure primitive (which inherits the env).

---

## Conventions

**Cross-platform or it's broken.** Every repo works on macOS, Linux *and* Windows, so:
- All task logic is **nushell** (`#!/usr/bin/env nu`) — never bash/sh/PowerShell, never
  a `.sh` file. No bash-isms, no hardcoded `/Users`, `/home`, `/opt` — derive from env
  and install state. If you reach for a shell script, you've broken the rule.
- A single plain command (e.g. `mise use -g …`) is fine — it's not shell-specific.
- The bootstrap that runs *before* nu exists uses bare `mise` commands only.

**Distribute by reference, never copy.** If you're writing code to clone or "stamp"
`.github` content into a repo, stop — you're reinventing. A repo upgrades by bumping a
pin, nothing else:

| What | Mechanism | Versioned by |
|---|---|---|
| mise tasks | `[task_config].includes = [".../tasks/<ns>.toml?ref=vX"]` | `?ref=` |
| CI | `.github/workflows/*.yml` → `uses: .../reusable-mise-ci.yml@vX` | `@ref` |
| global tools | `mise run mise:global:bootstrap` | latest |
| claude skills | this repo is a plugin **marketplace** — add it, install `fleet` | plugin version |

**Tools.** A repo's `[tools]` lists only what's unique to it. Runtime-free binaries
(nushell, fnox, gh, jq, usage, git-cliff) come from the global config; tools needing
node/ruby live per-task. Rust = rustup + `rust-toolchain.toml`, never mise.

**Secrets.** `fnox` = local keychain (`fnox set -p keychain`); `secrets:bw-*` syncs to
NodeWarden; CI reads GitHub Actions secrets and **never** runs fnox.

**Nushell tips.** `$"($var)"` interpolates, `$"\(lit\)"` is literal parens; use `glob`
(not `ls`) to expand a path pattern; lists need commas; detect the repo with
`git remote get-url origin`.

---

## Developing this repo

Version pins protect consumers (an old `?ref=` is immutable), so **refactor deeply** —
rename, merge, move, delete. Timidity is the bug; the pin is the safety net.

**Always in this order:**

1. **Edit** a task, skill, or workflow.
2. **Validate locally and in CI — both.** Run `mise run ci` locally first, then push to
   `.github` main (untagged). Then validate as a real consumer in `.github-example`
   (which pins `@main`): purge mise's include cache, re-bootstrap, `mise run ci`, push,
   confirm the matrix is green. `.github` also dogfoods itself — its CI *runs* the
   credential-free tasks across all OSes, so cross-OS bugs surface here, not in
   consumers. Local can pass while CI fails (a tool present on your box but not a
   runner) — check both.
3. **Release** only once it's green: `mise run release:github -- vX.Y.Z` (changelog →
   tag → GitHub release). Run the task, don't just parse it — parse-clean ≠ correct.
4. **Consumers adopt** by bumping `?ref=` / `@ref` / plugin version.

**Tags are APPEND-ONLY.** Never delete or re-point a published tag — a consumer may be
pinned to any tag, and deleting it 404s their includes and kills their CI (this has
happened). A bad release is superseded by a higher version, never deleted. And only
tag **after** the OS matrix is green — local green is one cell, not the matrix.

**Key tasks:** `mise:global:bootstrap`, `mise:repo:bootstrap [--release]`,
`release:github -- vX.Y.Z [assets]`, `release:pack`, `docker:image -- vX.Y.Z`,
`cliff:unreleased`, `ci:check-global`, `ci:check-nu`, `docs:gen` (regenerates the
tables above).

---

## Upgrading

Old `?ref=` tags never change, so a repo keeps working until you bump. To adopt a newer
version:

1. Pick the newest tag from [Releases](https://github.com/joeblew999/.github/releases).
2. Bump every `?ref=` in `mise.toml` `[task_config].includes`.
3. `mise run mise:repo:bootstrap` → `mise run ci` locally → push → confirm the matrix.

Re-running bootstrap is always safe and idempotent. A scheduled
`reusable-mise-upgrade` PR also does this for you — bumping tool versions
(`mise:upgrade`) and the `?ref=`/`@ref` pins (`ci:audit-lib-refs --write`) in one PR.
Per-version detail is in [CHANGELOG.md](./CHANGELOG.md); almost everything is additive.
The one breaking layout change is below.

<details>
<summary><b>Breaking → v0.40.0</b> (two-layer restructure — file/task renames)</summary>

`tasks/` split into pure `tool-*` primitives + 5 orchestration namespaces
(`ci · secrets · cfapp · release · mobile`). Bump every `?ref=` to ≥ v0.40.0, then:

**Include filenames:** `cf`→`tool-cf`, `gh`→`tool-gh`, `docker`→`tool-docker`,
`cliff`→`tool-cliff`, `rust`→`tool-rust`, `wrangler`→`tool-wrangler`,
`fnox`→`tool-fnox`, `bw`→`secrets-bw`, `provision`+`prove`→`cfapp`; `env` removed.
(`ci`, `mise`, `release`, `secrets`, `mobile` keep their names.)

**Task names:** `mise:global`→`mise:global:bootstrap`; `ci:watch`/`ci:clean`→
`gh:run-watch`/`gh:run-clean`; `ci:check-toml-tasks`/`ci:check-workflow-nu`/
`ci:parse-check`→`ci:check-nu`; `bw:<x>`→`secrets:bw-<x>`; `cf:provision-*`/
`provision:*`→`cfapp:provision-*`; `cf:access-*`/`cf:service-token-*`→`cfapp:access-*`/
`cfapp:service-token-*`; `cf:secrets-put-mapped`→`cfapp:provision-secrets`;
`prove:*`→`cfapp:verify-*`. The `cf:*` primitives (`d1-create`, `r2-create`,
`queue-create`, `secret-put`, `token-check`) are now pure wrangler/curl driven via
`cfapp:*`.

Then re-bootstrap and verify locally + on the matrix.
</details>
