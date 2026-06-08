# joeblew999/.github

Shared **mise task library** + **Claude plugin marketplace** + GitHub org config.
Guide: [AGENTS.md](./AGENTS.md) · Releases: [CHANGELOG.md](./CHANGELOG.md).

## Order of operations (READ FIRST)

How a change flows — **always in this order**:

1. **Edit** here — a task in `tasks/<ns>.toml`, the `fleet` skill, or a workflow.
2. **Validate live** in the sandbox
   [`.github-example`](https://github.com/joeblew999/.github-example): it includes
   this repo by *local, unversioned path*, so `mise run <task>` there tests your
   edit instantly. **No release needed — iterate here.**
3. **Release** only once it works: `mise run release:github -- vX.Y.Z`
   (changelog → tag → GitHub release).
4. **Consumers adopt** by bumping their `?ref=` / `@ref` / plugin version.
   Old refs never break (immutable) — which is why you refactor here *deeply*.

## Use it

Pin the namespaces you want in a consumer's `mise.toml`:

```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//tasks/mise.toml?ref=<tag>",   # mise:global, mise:sweep, …
  "git::https://github.com/joeblew999/.github.git//tasks/ci.toml?ref=<tag>",
  # one URL per namespace — mise does NOT chain git:: includes
]
[tools]
# repo-specific tools only — common ones come from the global config:
#   mise run mise:global
```

Namespaces: `bw cf ci cliff env fnox mise mobile prove rust secrets wrangler`.

## Local = CI

Everything CI runs is a mise task, so it runs locally too. One-line CI:

```yaml
jobs:
  ci:
    uses: joeblew999/.github/.github/workflows/reusable-mise-ci.yml@<tag>
    with: { task: check }
```

`mise run cliff:repo -- <owner/repo>` shows any upstream's unreleased delta.
