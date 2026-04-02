# Claude Code Skills

Reusable Claude Code skills for plat-trunk and Ubuntu Software projects.

## Usage

### Option A — Global (all projects)

```bash
# 1. Clone or sync skills to your global Claude dir
git clone --depth=1 \
  --branch v0.1.0 \
  https://github.com/joeblew999/.github.git \
  /tmp/shared-github

cp -r /tmp/shared-github/.claude/skills/. ~/.claude/skills/

# 2. Start Claude Code with global skills
claude
# skills auto-load from ~/.claude/skills/
```

### Option B — Per project (via mise sync task)

Add a sync task to your project `mise.toml`:

```toml
[tasks.sync-skills]
description = "Pull shared Claude Code skills from .github repo"
run = """
  git clone --depth=1 --branch v0.1.0 \
    https://github.com/joeblew999/.github.git /tmp/shared-github
  mkdir -p .claude/skills
  cp -r /tmp/shared-github/.claude/skills/. .claude/skills/
"""
```

Then:

```bash
mise run sync-skills
claude --add-dir .claude/skills
```

## Available Skills

| Skill | Slash Command | Auto-triggers when... |
|-------|--------------|----------------------|
| `rust-wasm` | `/rust-wasm` | Working with Truck kernel WASM compilation, wasm-bindgen, SchemaEntry |
| `cf-workers` | `/cf-workers` | Working with Hono routes, Wrangler, D1/R2, Datastar SSE |
| `truck-kernel` | `/truck-kernel` | Working with B-Rep geometry, coordinate transforms, CRDT sync, MVT tiles |

## Pinning

Pin the `--branch` tag to match your mise-tasks pin so both stay in sync:

```bash
--branch v0.1.0
```

## Adding New Skills

Each skill is a folder under `.claude/skills/` containing a `SKILL.md` with YAML frontmatter:

```
.claude/skills/
└── my-skill/
    └── SKILL.md     # required: frontmatter + instructions
```

Frontmatter format:

```yaml
---
name: my-skill
description: When to auto-trigger this skill. Be specific.
---
```
