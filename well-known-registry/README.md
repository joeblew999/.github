# Well-Known Endpoints Registry

A validated registry of `.well-known` endpoints with schema validation and provenance tracking.

## Quick Start

```bash
cd well-known-registry
task setup     # Install dependencies 
task validate  # Validate registry
task stats     # Show statistics
```

## Commands

```bash
task build      # Build tool
task validate   # Validate data
task generate   # Generate code/docs
task stats      # Show stats
task clean      # Clean generated files
```

## Files

- `data/well-known-endpoints.json` - Main registry (3 endpoints)
- `schemas/registry.jtd` - JTD validation schema  
- `main.go` - Go CLI tool
- `generated/` - Auto-generated docs and API format

## Query Examples

```bash
# Authentication endpoints
jq '.endpoints | to_entries | map(select(.value.category == "authentication"))' data/well-known-endpoints.json

# WebAuthn browser support
jq '.endpoints.webauthn.browser_support' data/well-known-endpoints.json
```

## Registry Stats

✅ **3 endpoints** across 2 categories  
✅ **All official authority** with verification  
✅ **Full browser support** tracking  
✅ **Schema validation** and documentation generation  

## Contributing

1. Edit `data/well-known-endpoints.json`
2. Run `task validate` 
3. Run `task generate`
4. Commit changes
