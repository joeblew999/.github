# Contributing

See [AGENTS.md](./AGENTS.md) for the full authoring guide — task structure, rules, release workflow, and gotchas.

The short version:

```bash
# 1. create the task file
vim mise-tasks/<namespace>/<task-name>
chmod +x mise-tasks/<namespace>/<task-name>

# 2. test locally
mise tasks ls
mise run <namespace>:<task-name>

# 3. update the task table
vim mise-tasks/README.md

# 4. release
mise run release -- vX.Y.Z
```
