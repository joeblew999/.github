# joeblew999/.github

Shared mise task library. Each `tasks/<ns>.toml` is a namespace of nushell
tasks; a repo includes the ones it wants, pinned by tag.

## How tools work

One rule: **a repo's `[tools]` lists only what's unique to that repo.** Shared
tools live in one of two places:

| Tool kind | Lives in | Examples |
|---|---|---|
| Runtime-free binary | the **global** config — `mise run mise:global` | nushell, fnox, gh, jq, usage, git-cliff |
| Needs node/ruby/rust | the **task** that uses it | wrangler (`cf`/`wrangler`), bitwarden (`bw`), java/cocoapods (`mobile`), wasm-pack (`rust`) |

Common tools float to `latest`. Tasks never pin a tool that's in the global set.

## Tasks

| Task | Does |
|---|---|
| `mise:global` | install the global toolset (run locally; CI runs the same task) |
| `mise:sweep` | prune orphaned tool installs |
| `mise:release -- vX.Y.Z` | tag + push (hand-written CHANGELOG) |
| `cliff:release -- vX.Y.Z` | git-cliff CHANGELOG → commit → tag → GitHub release |
| `cliff:repo <owner/repo>` | another repo's unreleased delta |
| `ci:* cf:* bw:* secrets:* prove:* fnox:* wrangler:* rust:* mobile:*` | checks + domain tasks |

## Working here

1. Edit `tasks/<ns>.toml` — nushell body, no pins for global tools.
2. `mise run ci:check-toml-tasks` (CI runs the same task).
3. `mise run cliff:release -- vX.Y.Z` (or `mise:release`).

## Consuming

```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//tasks/mise.toml?ref=<tag>",
  "git::https://github.com/joeblew999/.github.git//tasks/<ns>.toml?ref=<tag>",
]
[tools]    # repo-specific only — globals come from `mise run mise:global`
```

CI: `uses: joeblew999/.github/.github/workflows/reusable-mise-ci.yml@<tag>` with
`{ task: check }`. Everything CI runs is a mise task, so it runs locally first.

## Nushell

- `$"($var)"` interpolates; `$"\(lit\)"` is literal parens.
- Lists need commas; `sort | uniq` to dedupe; parse-check is `nu --ide-check 1 <f>`.
- Detect repo via `git remote get-url origin`; `unset FNOX_AGE_KEY` in fnox tasks.

## Secrets

`fnox` = local keychain store (`fnox set -p keychain`); `bw:*` syncs it to
self-hosted NodeWarden; CI reads GH Actions secrets, never runs fnox.
