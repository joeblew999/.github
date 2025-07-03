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




