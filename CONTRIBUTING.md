# Contributing

See [AGENTS.md](./AGENTS.md) for the full authoring guide — task structure, rules, release workflow, and gotchas.

The short version (TOML-tasks, the v0.16+ pattern):

```bash
# 1. add the task to tasks/<namespace>.toml (run body is nushell)
vim tasks/<namespace>.toml

# 2. lint the embedded nu code locally (sub-second)
mise run ci:check-toml-tasks

# 3. test the resolved task
mise tasks info <namespace>:<task-name>
mise run <namespace>:<task-name>

# 4. release
mise run mise:release -- vX.Y.Z
```

