---
name: truck-kernel
description: Truck Rust CAD kernel patterns for plat-trunk. Use when working with B-Rep geometry, coordinate transforms, scene graph, assembly hierarchy, MVT tiles, or the monstertruck community fork.
---

# Truck Kernel Skill — plat-trunk

## Stack Context
- Truck Rust CAD kernel (RICOS Co. Ltd — Fukumitsu + Tanimura-san)
- monstertruck community fork: meta-crate with feature flags, upstream ingestion branch
- plat-trunk contributes: `monstertruck-mvt` (coordinate transforms), `monstertruck-ifc` (IFC)
- Platform: browser-native B-Rep CAD at cad.ubuntusoftware.net

## Coordinate Transform Pipeline
```
Truck model space → real-world metres → ECEF/Mercator → MVT tile space
```
- `monstertruck-mvt` owns this pipeline
- Never mix coordinate spaces — always transform explicitly at boundaries

## Scene Graph
- Assembly hierarchy per ADR-0005
- Scene controller is a module singleton: `sceneController`
- Sketch operations via `sketch` singleton
- All geometry mutations go through `cadDocManager`

## CRDT Sync (ADR-0001, ADR-0038)
- Automerge CRDT for sync
- Branch doc bytes stored in R2 (BLAKE3 keys) per ADR-0038
- OPFS as browser storage (ADR-0036)
- Pure Rust sync path — no JS in sync layer (ADR-0008)
- `DocStore` trait abstracts storage backend

## MCP Tools
- 29–52+ MCP tools for AI agent geometry authoring
- All generated from `cad-schema.json` via `SchemaEntry` tuples
- Tool names follow `truck_<operation>` convention

## IFC Integration
- `monstertruck-ifc` crate
- STEP→gmsh→femio pipeline explored for RICOS FEA data
- IsoGCN AI training dataset publicly downloadable from RICOS

## Upstream Contribution Rules
- Always work on `upstream-ingestion` branch for monstertruck contributions
- Feature-flag new capabilities — don't break the meta-crate
- Coordinate with Moritz Möller (virtualritz@protonmail.com) on fork decisions

## Common Gotchas
- Truck uses its own topology types — don't convert to/from nalgebra prematurely
- B-Rep shell must be closed before export — validate with truck's own checker
- MVT tile coordinates are integers — quantise at the last step only
