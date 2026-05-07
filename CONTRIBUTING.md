# Contributing

See [AGENTS.md](./AGENTS.md) for the full authoring guide — task structure, rules, release workflow, and gotchas.

The short version (TOML-tasks, the v0.16+ pattern):

```bash
# 1. add the task to tasks/<namespace>.toml — extend the namespace's _base
vim tasks/<namespace>.toml

# 2. lint the embedded nu code locally (sub-second)
mise run ci:check-toml-tasks

# 3. test the resolved task
mise tasks info <namespace>:<task-name>
mise run <namespace>:<task-name>

# 4. release
mise run release -- vX.Y.Z
```

Don't add new tasks under `mise-tasks/` — that tree is [deprecated](mise-tasks/DEPRECATED.md).
