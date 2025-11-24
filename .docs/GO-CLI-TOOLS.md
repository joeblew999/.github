# Go CLI Tools for Cross-Platform Scripting

This document outlines Go CLI tools that can replace traditional Unix command-line utilities to ensure cross-platform compatibility in Taskfiles.

## Core Tools for JSON/String Manipulation

### 1. gojq - JSON Processor (jq replacement)
- **Install**: `go install github.com/itchyny/gojq/cmd/gojq@latest`
- **Purpose**: JSON processing, filtering, and transformation
- **Usage**: `gojq '.field' file.json`
- **Advantages**: 100% compatible with jq syntax, faster than jq

### 2. yq - YAML/JSON/XML Processor
- **Install**: `go install github.com/mikefarah/yq/v4@latest`
- **Purpose**: YAML, JSON, XML processing
- **Usage**: `yq eval '.field' file.yaml`
- **Advantages**: Supports multiple formats, powerful transformations

## Text Processing Tools

### 3. Miller (mlr) - Data Processing
- **Install**: `go install github.com/johnkerl/miller/cmd/mlr@latest`
- **Purpose**: CSV, TSV, JSON data processing
- **Usage**: `mlr --json cut -f field1,field2 file.json`
- **Advantages**: Powerful data manipulation, multiple format support

### 4. Dasel - Data Selector
- **Install**: `go install github.com/tomwright/dasel/cmd/dasel@latest`
- **Purpose**: Query and modify JSON, YAML, TOML, XML
- **Usage**: `dasel -f file.json '.field'`
- **Advantages**: Single tool for multiple formats

## File and Text Utilities

### 5. Golang text utilities
For simpler operations, we can use built-in Go tools or create small utilities:

#### head/tail replacement
- **ghead**: `go install github.com/rakyll/goutils/cmd/ghead@latest`
- **gtail**: `go install github.com/rakyll/goutils/cmd/gtail@latest`

#### grep replacement
- **ggrep**: Can use `gojq` for structured data or create simple Go utility

## Recommended Standard Stack

For this project, recommend standardizing on:

1. **gojq** - JSON processing (replaces jq)
2. **yq** - YAML/JSON processing (additional functionality)
3. **dasel** - Multi-format data selection (backup for complex queries)

## Implementation Strategy

1. Add `setup-tools` task to install required Go CLI tools
2. Replace existing tool usage:
   - `jq` → `gojq`
   - `head` → `gojq` for structured data, or built-in string manipulation
   - `grep` → `gojq` for structured data, or pattern matching in Go
   - `cut` → `gojq` or string manipulation

3. Use Taskfile variables to define tool commands for easy switching
4. Add validation tasks to ensure tools are installed

## Benefits

- **Cross-platform**: Works on Windows, macOS, Linux
- **No external dependencies**: All tools built as static Go binaries
- **Version control**: Tools installed via `go install` are version-tracked
- **Performance**: Go tools are typically fast and memory-efficient
- **Maintainability**: Single ecosystem, consistent behavior
