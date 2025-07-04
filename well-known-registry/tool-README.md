# Well-Known Registry Tool

A Go-based tool for managing the well-known endpoints registry with JTD schema validation.

## Installation

```bash
cd well-known-registry
go mod tidy
go build -o registry-tool .
```

## Usage

### Validate Registry
```bash
./registry-tool validate
```

### Generate Code & Documentation  
```bash
./registry-tool generate
```

### Show Statistics
```bash
./registry-tool stats
```

### Collect from Sources (Coming Soon)
```bash
./registry-tool collect
```

## Features

✅ **JTD Schema Validation** using delaneyj/toolbelt  
✅ **Go Type Generation** from JTD schemas  
✅ **Documentation Generation** from registry data  
✅ **Statistics & Analytics** for registry health  
✅ **CLI Interface** with cobra commands  

## Commands

- **`validate`** - Validate registry against JTD schema
- **`generate`** - Generate Go types and documentation  
- **`stats`** - Show registry statistics
- **`collect`** - Collect endpoints from external sources

## Generated Files

- `generated/types.go` - Go structs from JTD schema
- `generated/api.json` - Minified API-ready JSON
- `generated/docs.md` - Auto-generated documentation

## Dependencies

- **delaneyj/toolbelt** - JTD schema validation and Go generation
- **spf13/cobra** - CLI interface

Much cleaner than bash scripts! 🚀
