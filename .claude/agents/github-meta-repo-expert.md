# .github repo expert

This repo (`joeblew999/.github`) is a shared mise task library and GitHub org config store.

## Structure

```
mise-tasks/          shared mise tasks consumed by all repos via [task_config].includes
  fnox/init          bootstrap fnox keychain provider for a fresh dev
  secrets/           sync-github, sync-github-dry, status, migrate-to-keychain
  cf/                d1-migrate
  rust/              build, test, wasm-pack
  wrangler/          dev, deploy
.github/             org-level GitHub config (CODEOWNERS, dependabot, issue templates)
  workflows/
    welcome.yml      greets first-time contributors
    mise-tasks-lint  verifies task scripts load + are executable on every push
profile/             GitHub org profile shown at github.com/joeblew999
.claude/             Claude Code skills and agents
```

## How consuming repos wire in the shared tasks

In `mise.toml`:
```toml
[task_config]
includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.2.0"]

[env]
FNOX_SYNC_KEYS = "CLOUDFLARE_API_TOKEN,CLOUDFLARE_ACCOUNT_ID,..."
```

## Adding or editing tasks

1. Edit or create the file under `mise-tasks/<namespace>/<task-name>`
2. `chmod +x` it — mise requires the executable bit
3. Run `mise tasks ls` locally (this repo has a `mise.toml` that includes `mise-tasks/` directly)
4. Push to main, then tag a new semver: `git tag v0.X.0 && git push --tags`
5. Bump `?ref=vX.Y.Z` in consuming repos

## Secrets pattern

`fnox` is the canonical secret store, backed by macOS Keychain (no age key file).
`FNOX_SYNC_KEYS` in each consuming repo controls which keys get pushed to GitHub Actions.
CI never runs fnox — it reads from GitHub Actions secrets that `secrets:sync-github` populates.

## Key constraint

Tasks must not use `${#array[@]}` (bash array-length) syntax — mise uses the Tera template
engine to pre-process task scripts, and `{#` is parsed as a Tera comment block start.
Use `grep | wc -l` or `while read` loops instead.
