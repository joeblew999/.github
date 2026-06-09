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

**Add your own CI work** — define a *local* `ci` that depends on your tasks; mise
merges it with the shared guards, so both run:

```toml
[tasks.ci]
depends = ["test"]

[tasks.test]
run = '''
#!/usr/bin/env nu
print "your work here"
'''
```

---

## 2. How CI works — local == CI

CI is **isomorphic**. `mise:repo:bootstrap` writes a thin stub that `uses:` the
shared `reusable-mise-ci.yml`, which just runs `mise run ci` — *the same task you
run locally*. Consequences:

- `mise run ci` on your machine **is one cell** of the CI matrix. Green locally ⇒
  green for that OS in CI; the matrix only adds the *other* OSes (you can't run
  them locally).
- The OS list lives in **one place** — the reusable's `os-matrix` input (default
  `ubuntu + macos + windows`). Override per repo at bootstrap:
  `mise run mise:repo:bootstrap --os-matrix '["ubuntu-latest"]'`.
- A task can read its own OS via `$nu.os-info.name` → `macos` / `linux` / `windows`.
- `.github` **dogfoods** itself — its CI *runs* the credential-free tasks on the
  matrix (not just parses them), so cross-OS bugs get caught for real.

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
| `ci` | verify code | nu guards + dogfood |
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
deeply** — rename, merge, move. The loop:

```
edit → mise run ci                 # locally FIRST — the same task CI runs
     → git push                    # .github main (rolling, untagged)
# then validate as a real consumer, in .github-example:
     → purge mise's include cache  # ?ref=main is cached
     → mise run mise:repo:bootstrap-delete && mise run mise:repo:bootstrap
     → mise run ci                 # local green, THEN
     → git push                    # triggers the OS matrix
```

Local-first every time — pushing untested is what breaks CI. Cut a release with
`mise run release:github -- vX.Y.Z`.
