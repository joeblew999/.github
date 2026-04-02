---
name: rust-wasm
description: Rust to WASM compilation patterns for plat-trunk. Use when writing, building, or debugging Rust code that compiles to WASM for the Truck CAD kernel, dealing with wasm-bindgen, WASM boundary contracts, or schema-driven codegen.
---

# Rust/WASM Skill — plat-trunk

## Stack Context
- Truck Rust CAD kernel compiled to WASM via `wasm-pack`
- WASM boundary contracts defined by `SchemaEntry` tuples (`schemars::JsonSchema`)
- `cad-schema.json` is source of truth → generates MCP tools, Hono/Zod routes, browser `cadCommand()`
- Toolchain managed by `mise` (not wasm-pack directly)
- Tests written in Rust

## Build Patterns

Always use mise tasks, not raw wasm-pack:
```bash
mise run rust:wasm-pack   # compile to WASM
mise run rust:build       # cargo build
mise run rust:test        # cargo test
```

## WASM Boundary Rules
- All types crossing the WASM boundary must implement `schemars::JsonSchema`
- Use `SchemaEntry` tuples as the single source of truth
- Never add raw JS glue — generate it from the schema
- `check-alignment.mjs` enforces one TS file per target calling sync WASM functions

## Crate Structure
- `pt-log` crate for unified observability (`tracing-web` + `tracing-subscriber` .json())
- Pure Rust sync path — no JS in the sync layer
- BLAKE3 content-addressed R2 keys
- `DocStore` trait for storage abstraction

## Error Handling
- Always propagate errors to JS via `Result<T, JsValue>`
- Log with `tracing` not `println!`
- RUST_BACKTRACE=1 in test tasks

## Common Gotchas
- `wasm-bindgen` version must be pinned in mise.toml — mismatches cause silent failures
- OPFS (browser storage) is async — never call from sync Rust context
- Automerge CRDT bytes go to R2, not D1 — D1 is for metadata only
