# mise-tasks

Reusable mise task library for plat-trunk and Ubuntu Software projects.

## Usage

Add to your project's `mise.toml`:

```toml
[task_config]
includes = [
  "git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.1.0"
]
```

Then run:

```bash
mise install          # install tools
mise tasks ls         # verify tasks loaded
```

## Available Tasks

| Task | Description |
|------|-------------|
| `rust:build` | `cargo build --all-targets` |
| `rust:test` | `cargo test --all-targets` |
| `rust:wasm-pack` | Compile Truck kernel to WASM via wasm-pack |
| `wrangler:dev` | Local dev (multi-worker) |
| `wrangler:deploy` | Deploy to Cloudflare Workers |
| `cf:d1-migrate` | Run D1 migrations |

## Pinning

Always pin to a tag in production:

```toml
"git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.1.0"
```

Use `ref=main` on local dev only. Bump the tag intentionally when tasks change.

## Cache

```bash
mise cache clear   # force re-fetch after bumping ref
```

Set `MISE_TASK_REMOTE_NO_CACHE=true` to always fetch latest (slow, CI use only).
