# joeblew999/.github

Shared **mise task library** + **Claude plugin marketplace** + GitHub org config
for the whole fleet. Agent guide: [AGENTS.md](./AGENTS.md) · [CHANGELOG.md](./CHANGELOG.md).

Everything is a **mise task**, distributed **by reference** (`?ref=`/`@ref`, never
copied), and runs **the same locally and in CI**.

## Two layers

The `tasks/` dir is split into two layers — and the filenames show which is which.

### 1. Tool layer — `tool-*.toml` (pure primitives)

Each task drives **only its own tool** + ubiquitous plumbing (`git`/`curl`/`tar`).
**No foreign tool, no `fnox`** — secrets arrive in `$env` (set by the layer above).

| file | drives |
|---|---|
| `tool-wrangler` | `wrangler` *(only — nothing else)* |
| `tool-cf` | `wrangler` + `curl` |
| `tool-gh` | `gh` (+ `git`) |
| `tool-docker` | `docker` (+ `git`) |
| `tool-cliff` | `git-cliff` (+ `git`) |
| `tool-rust` | `cargo` / `wasm-pack` |
| `tool-fnox` | `fnox` (+ its keychain backend) |

### 2. Orchestration layer — plain `*.toml`

These **compose** tool tasks (via `depends` / `mise run`) and own the cross-tool
work + the `fnox`→`$env` bridge.

Five namespaces, one per lifecycle concern:

| file | composes | role |
|---|---|---|
| `ci` | `nu` guards + dogfood | **verify code** — parse + global-config guards + self-test |
| `secrets` (+ `secrets-bw`) | `fnox` + `gh` + `keychain` + `bw` | **manage secrets** — sync keychain ↔ fnox ↔ GitHub ↔ Bitwarden |
| `cfapp` | `cf:*` (via `mise run`) + `fnox` + `curl` + `wrangler` | **Cloudflare Worker app** — provision (D1/R2/queues/secrets) + Access + verify the deployed worker |
| `release` | `git-cliff` + `git` + `gh` + `tar` | **ship** — changelog → tag → GitHub release (+ `release:pack`) |
| `mobile` | `tauri`/`rustup` + `java`/`pod`/`xcode-select` | **build mobile** (Android + iOS) |

Plus two that are neither: **`mise`** (the runner) and **`env`** (a pure-nu util).

**The rule:** `git`/`curl`/`tar` are plumbing — usable anywhere. A *tool* file
driving another tool's binary, or reaching into `fnox`, is mis-placed → move that
work up to an orchestration file. Secrets flow **down**: orchestration reads
`fnox`, sets `$env`, then `mise run`s the pure primitive (child inherits env).

## New repo — what a dev runs

```sh
# 1. add the includes to mise.toml (pin ?ref= to the latest tag):
#    [task_config]
#    includes = [
#      "git::https://github.com/joeblew999/.github.git//tasks/mise.toml?ref=<tag>",
#      "git::https://github.com/joeblew999/.github.git//tasks/ci.toml?ref=<tag>",
#    ]
mise trust                       # load the config + includes
mise run mise:global:bootstrap   # seed the machine's toolset (nu, gh, …)
mise run mise:repo:bootstrap     # write this repo's .github/workflows
mise run ci                      # verify
```

Working example: [.github-example](https://github.com/joeblew999/.github-example).

## CI is isomorphic — local == one matrix cell

The reusable workflows (`reusable-mise-ci.yml` / `reusable-mise-upgrade.yml`) are
the **engine**; repos don't copy them, they `uses:` them. `mise run mise:repo:bootstrap`
writes a thin stub that calls the reusable, which just runs `mise run ci` — **the
same task you run locally**.

- `mise run ci` on your machine **is** one cell of the CI run. Green locally ⇒ green
  for that OS in CI. The matrix only adds the *other* OSes (you can't run them locally).
- The OS list lives once: the `os-matrix` input (default `ubuntu + macos + windows`).
  The stub inherits it; override at bootstrap with `--os-matrix '["ubuntu-latest"]'`.
- A task that needs its OS reads `$nu.os-info.name` → `macos`/`linux`/`windows`.
- `.github` **dogfoods**: its own CI *runs* the credential-free tasks on the matrix
  (composition + `release:pack`), so real cross-OS bugs get caught — not just parsed.

**Extend `ci` in your repo** — define a local `ci` that depends on your work; mise
merges it with the shared guards:

```toml
[tasks.ci]
depends = ["test"]   # → shared guards + your task

[tasks.test]
run = '''
#!/usr/bin/env nu
print "your work here"
'''
```

## Dev cycle (changing the lib)

```
edit .github  →  mise run ci            # locally FIRST — same task CI runs
              →  git push               # .github main
# then in a consumer (e.g. .github-example):
              →  purge mise's include cache   # ?ref=main is cached
              →  mise run mise:repo:bootstrap-delete && mise run mise:repo:bootstrap
              →  mise run ci            # locally green, THEN
              →  git push              # triggers the OS matrix
```

Local-first every time — pushing untested is what breaks CI. Releases are
version-protected, so refactor **deeply**: `mise run release:github -- vX.Y.Z`.
