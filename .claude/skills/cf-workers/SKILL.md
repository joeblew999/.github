---
name: cf-workers
description: Cloudflare Workers deployment and local dev patterns for plat-trunk. Use when working with Wrangler, Hono routes, Zod schemas, CF D1, R2, Durable Objects, or deploying the plat-trunk backend.
---

# Cloudflare Workers Skill — plat-trunk

## Stack Context
- Backend: Hono + Zod + Hono-MCP on CF Workers
- Frontend: Lit + Datastar (SSE transport)
- Storage: CF D1 (metadata) + R2 (Automerge CRDT branch doc bytes, BLAKE3-keyed)
- Deployed via Wrangler multi-worker local dev
- Subdomain: gedw99.workers.dev / cad.ubuntusoftware.net

## Tasks
```bash
mise run wrangler:dev      # local dev (multi-worker)
mise run wrangler:deploy   # deploy to CF
mise run cf:d1-migrate     # run D1 migrations
```

## Hono Route Patterns
- All routes must have Zod validation
- Routes generated from `cad-schema.json` — don't write manually
- MCP tools (29–52+) also generated from schema
- Use `NullNetworkAdapter` with injected fetch for testing

## D1 vs R2 Rules
- D1: user metadata, session state, schema versions
- R2: Automerge CRDT branch doc bytes only (BLAKE3 content-addressed keys)
- Never store CRDT bytes in D1

## Datastar / SSE
- Datastar handles SSE transport for real-time updates
- `reconcile.ts` uses `r:any` temporarily (deferred — waiting on official Datastar TS types)
- All window globals replaced with module singletons:
  `cadDocManager / sceneController / sketch / moduleRouter / workerRelay / warmCount`

## Wrangler Config
- Multi-worker setup — check `wrangler.toml` for binding names before adding new ones
- `app-config.ts` is the single config entrypoint
- `api-contract` enforced in CI

## Common Gotchas
- CF D1 is SQLite — no JSON operators available in all versions
- R2 keys must be BLAKE3 hashed — never use raw filenames
- Datastar SSE events must be flushed — don't buffer
