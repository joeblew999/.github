# joeblew999/.github

Meta-repository for the `joeblew999` GitHub organisation.

## What lives here

| Path | Purpose |
|---|---|
| `mise-tasks/` | Shared mise task library — consumed by all repos via `[task_config].includes` |
| `profile/` | Org profile page shown at [github.com/joeblew999](https://github.com/joeblew999) |
| `.claude/` | Claude Code skills and agents shared across projects |
| `.github/` | Org-level GitHub config (CODEOWNERS, issue templates, dependabot, welcome workflow) |

## Using the shared task library

Add to any repo's `mise.toml`:

```toml
[task_config]
includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.2.0"]
```

See [mise-tasks/README.md](mise-tasks/README.md) for the full task list and wiring guide.
