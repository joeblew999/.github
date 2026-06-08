# joeblew999/.github

Shared **mise task library** + **Claude plugin marketplace** + GitHub org config.
Guide: [AGENTS.md](./AGENTS.md) · Releases: [CHANGELOG.md](./CHANGELOG.md).

## Order of operations (READ FIRST)

How a change flows — **always in this order**:

1. **Edit** here — a task in `tasks/<ns>.toml`, the `fleet` skill, or a workflow.
2. **Validate — local AND CI** via the sandbox
   [`.github-example`](https://github.com/joeblew999/.github-example) (consumes
   `.github@main`): push `.github` `main`, then *local* = `mise run <task>` there,
   *CI* = its `mise.yaml` runs the shared `reusable-mise-ci.yml@main`. **Both green
   before release; no release while iterating.**
3. **Release** only once it works: `mise run release:github -- vX.Y.Z`
   (changelog → tag → GitHub release).
4. **Consumers adopt** by bumping their `?ref=` / `@ref` / plugin version.
   Old refs never break (immutable) — which is why you refactor here *deeply*.

## New repo — what a dev runs

```sh
# 1. add the includes to mise.toml (pin ?ref= to the latest tag):
#    [task_config]
#    includes = [
#      "git::https://github.com/joeblew999/.github.git//tasks/mise.toml?ref=<tag>",
#      "git::https://github.com/joeblew999/.github.git//tasks/ci.toml?ref=<tag>",
#    ]
mise trust             # load the config + includes
mise run mise:global:bootstrap   # bootstrap the machine's toolset (nu, gh, …)
mise run mise:repo:bootstrap     # bootstrap this repo's .github/workflows
mise run ci            # verify
```

Working example: [.github-example](https://github.com/joeblew999/.github-example).
Namespaces: `bw cf ci cliff env fnox mise mobile prove rust secrets wrangler`.
