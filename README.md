# joeblew999 Organization

https://github.com/joeblew999?preview=true

## Single Source of Truth

Uses Taskfile locally and in CI for consistency:
- `task setup` - Generate .github files from templates
- `task clean` - Remove generated files

Templates auto-regenerate when changed via GitHub Actions calling same Taskfile.

## Idempotent Operations

All Taskfile operations are idempotent and remediate race conditions:
- Clean removes all generated files completely before setup
- Setup ensures consistent directory structure from templates
- Check validates generated files match templates exactly

## Snake Chasing Its Own Tail

This repository has a unique architecture challenge:
1. **Templates change** → triggers GitHub Action
2. **Action runs `task setup`** → generates new `.github` files
3. **Action commits changes** → could trigger another Action
4. **Potential infinite loop!** 🐍

**Solution:** GitHub Actions use `[skip-regen]` commit tags to prevent recursion.

**Why GitHub CLI helps:** `task verify-github` lets us see inside GitHub to verify:
- Workflows are actually running
- Templates are deployed correctly  
- Auto-regeneration is working
- No infinite loops occurred

This gives us observability into the "snake" to ensure it doesn't eat its own tail!




