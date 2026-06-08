# Reusable workflows — how this works

These `reusable-*.yml` are the **engine**. Repos don't copy them — they call them.

## The flow

1. `reusable-mise-ci.yml` / `reusable-mise-upgrade.yml` hold all the logic **and the defaults**.
2. A repo runs **`mise run mise:repo:bootstrap`**, which writes a thin stub
   `.github/workflows/mise.yml` that just does `uses: …/reusable-mise-ci.yml@main`.
3. CI runs `mise run mise:global:bootstrap`, then `mise run ci` — **the same task you run locally.**

## Isomorphic: local == CI

`mise run ci` on your machine is exactly *one cell* of the CI run. Run it locally
first — if it's green, that OS is green in CI. You can't run the other OSes
locally; that's the only thing the matrix adds.

## What it runs on (the matrix)

- The OS list lives in **one place**: the `os-matrix` input in `reusable-mise-ci.yml`
  (default: `ubuntu + macos + windows`).
- The stub **inherits** it. Override per-repo at bootstrap:
  `mise run mise:repo:bootstrap --os-matrix '["ubuntu-latest"]'` (or edit the stub's `with:`).
- CI fans `mise run ci` across each OS. **Locally there is no matrix — you're just the OS you're on.**
- A task that needs to know its OS reads `$nu.os-info.name` (nushell, cross-platform):
  `macos` / `linux` / `windows`. Local = your OS; CI = that cell's OS.

## How a repo controls its own `ci`

The lib's `ci` is a **floor** — it runs the shared guards. A repo adds its own work
with a local `ci` that depends on it; mise **merges** same-named tasks, so the guards
still run and you don't re-list them:

```toml
[tasks.ci]
depends = ["test"]      # → guards (from .github) + your task

[tasks.test]
run = '''
#!/usr/bin/env nu
print "your work here"
'''
```

To change *which* task CI runs: `--task <name>` at bootstrap (or the stub's `with: task:`).

## Dev cycle (when you change the lib)

```
edit .github
mise run ci                     # locally, FIRST — same task CI runs
git push                        # .github main
# then in a consumer (e.g. .github-example):
<purge mise's git-include cache>
mise run mise:repo:bootstrap-delete
mise run mise:repo:bootstrap
mise run ci                     # locally, green, before pushing
git push                        # triggers the OS matrix
```

Local-first every time — pushing untested is what breaks CI.
