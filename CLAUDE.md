# CLAUDE.md — joeblew999/.github

This is the **shared system** for every joeblew999 project. Drift here breaks every consumer repo. Stay disciplined.

## Hard rules

1. **Run `mise run ci:parse-check` BEFORE every push.** If it fails locally, it fails for every consumer.
2. **Adding a task = updating four places.** New task file + `chmod +x` + README.md row + (if it has a missing-prereq failure mode) `mise-tasks-lint.yml` cases array. Skip any of them and it ships broken.
3. **Reusable workflows are public API.** `reusable-mise-ci.yml` and `reusable-mise-upgrade.yml` inputs are pinned by tag in consumer repos. Removing/renaming inputs = major version bump.
4. **README.md `?ref=` example must match the latest tag.** Bump it when you cut a release.

## Operational checklist

See [AGENTS.md](./AGENTS.md) for the full convention. The "Adding a new shared task" checklist + "Keep this repo clean" invariants section are the things that prevent drift.

## Quick verify

```bash
mise run ci:parse-check                   # 51 nu files parse-clean
mise tasks ls | wc -l                     # ~50 visible
grep -c "^### " mise-tasks/README.md      # one section per namespace
```

If any of those numbers surprise you, something drifted — don't push.
