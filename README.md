# joeblew999/.github

Shared **mise task library** + Claude plugin marketplace + GitHub org config for
the fleet. Every capability is a **mise task**, shared **by reference** (`?ref=` /
`@ref`, never copied), and **runs the same locally as in CI**.

Agent guide: [AGENTS.md](./AGENTS.md) · history: [CHANGELOG.md](./CHANGELOG.md) ·
example consumer: [.github-example](https://github.com/joeblew999/.github-example).

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

**Make `ci` yours.** The shared `ci` runs the library's guards. Add a *local* `ci`
that depends on your own tasks; mise **merges** them, so the guards *and* your work
run — both locally and on the matrix:

```toml
[tasks.ci]
depends = ["test"]

[tasks.test]
run = '''
#!/usr/bin/env nu
print "your work here"
'''
```

**Pick your OSes.** The matrix is the reusable workflow's `os-matrix` (default all
three). Override per repo at bootstrap — `mise run mise:repo:bootstrap --os-matrix
'["ubuntu-latest"]'` — or edit the stub. A task can read its current OS with
`$nu.os-info.name` → `macos` / `linux` / `windows`.

---

## 3. What's inside — two layers

`tasks/` is split into two layers, and the **filename tells you which**.

### Tool layer — `tool-*.toml`  (pure primitives)

Each task drives **only its own tool** + ubiquitous plumbing (`git`/`curl`/`tar`).
No foreign tool, no `fnox` — secrets arrive in `$env` (set by the layer above).

| file | drives |
|---|---|
| `tool-wrangler` | `wrangler` *(only — nothing else)* |
| `tool-cf` | `wrangler` + `curl` |
| `tool-gh` | `gh` |
| `tool-docker` | `docker` |
| `tool-cliff` | `git-cliff` |
| `tool-rust` | `cargo` / `wasm-pack` |
| `tool-fnox` | `fnox` |

### Orchestration layer — plain `*.toml`  (5 lifecycle namespaces)

Each composes tool tasks (`depends` / `mise run`) and owns the cross-tool work +
the `fnox`→`$env` bridge.

| namespace | does | by driving |
|---|---|---|
| `ci` | verify code | nu guards |
| `secrets` | manage secrets | `fnox` + `gh` + `keychain` + `bw` |
| `cfapp` | Cloudflare Worker lifecycle (provision → access → verify) | `cf:*` + `wrangler` + `curl` + `fnox` |
| `release` | ship (changelog → tag → release) | `git-cliff` + `git` + `gh` + `tar` |
| `mobile` | build mobile apps | `tauri` + `rustup` + `java` / `pod` / `xcode-select` |

Plus the **`mise`** runner (`global:bootstrap` / `repo:bootstrap` / `sweep` / `upgrade`).

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
