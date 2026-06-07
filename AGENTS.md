# Agent Guidelines: joeblew999/.github

Shared mise task library for `joeblew999` repos. Consumers pull namespaces by
tag via `[task_config].includes`.

## Model

- **Tasks are TOML** in `tasks/<ns>.toml`; bodies are nushell.
- **The global mise config owns the common toolset** — runtime-free binaries
  every shared task inherits: nushell, fnox, gh, jq, usage, git-cliff. `mise run
  mise:global` installs them. Tasks pin none of these.
- **Tools that need a runtime stay per-task** in their namespace: `cf:*`/
  `wrangler:*` (wrangler — node), `bw:*` (bitwarden — node), `mobile:*`
  (java/ruby/cocoapods/tauri-cli), `rust:*` (wasm-pack). They install only when
  their task runs.
- **Common tools float to `latest`** (only `java`/`ruby` pinned).
- **Specs use registry short-names** (`fnox`, `gh`, …); `nushell` →
  `github:nushell/nushell`; forks keep their backend.
- **Everything CI does is a mise task** → run it locally, then a real GitHub run
  only confirms. `reusable-mise-ci.yml` is just `mise run mise:global` +
  `mise run <task>`.

## Tasks

- `mise:global` — install the common toolset into the global config.
- `mise:sweep` — prune orphaned tool installs.
- `mise:release -- vX.Y.Z` — tag + push a release (local).
- `cliff:repo <owner/repo>` — an upstream's unreleased delta (+ `cliff:unreleased`/`cliff:show`).
- `ci:* cf:* bw:* secrets:* prove:* fnox:* wrangler:* rust:* mobile:*`.

## Nushell gotchas

- `$"… ($var) …"` = variable; `$"… \(lit\) …"` = literal parens (don't write `$"x (lit)"`).
- Lists need commas; `sort` doesn't dedupe (`sort | uniq`); parse-check = `nu --ide-check 1 <f>`.
- Repo detect: `git remote get-url origin` (not `gh repo view` — follows forks).
- `unset FNOX_AGE_KEY` in fnox tasks (Claude Code leaks it).

## Add a task

Edit `tasks/<ns>.toml` (no version pins for common tools) → `mise run
ci:check-toml-tasks` → update `CHANGELOG.md` → `mise run mise:release -- vX.Y.Z`.

## Consume

```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//tasks/mise.toml?ref=<tag>",   # mise:global etc.
  "git::https://github.com/joeblew999/.github.git//tasks/<ns>.toml?ref=<tag>",   # one per namespace
]
[tools]
# repo-specific only — common tools come from the global config (mise run mise:global)
```

CI: `uses: joeblew999/.github/.github/workflows/reusable-mise-ci.yml@<tag>` with `{ task: check }`.

## Secrets

`fnox` = local store (keychain; `fnox set` always `-p keychain`). `bw:*` syncs
keychain ↔ self-hosted NodeWarden. CI reads GH Actions secrets, never runs fnox.
