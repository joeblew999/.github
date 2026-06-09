# Migration

Old `?ref=` tags are **immutable** — your repo keeps working until you bump. When
you adopt a new version, this file lists what changed; then follow
[README §1 "Use it in a repo"](./README.md#1-use-it-in-a-repo) to re-bootstrap.

---

## → v0.40.0  (two-layer restructure — BREAKING)

`tasks/` split into **pure `tool-*` primitives** + **5 orchestration namespaces**
(`ci · secrets · cfapp · release · mobile`). Files and task namespaces were renamed.

**1. Bump every `?ref=`** in `mise.toml` `[task_config].includes` → `?ref=v0.40.0`.

**2. Rename the include filenames you use:**

| old | new |
|---|---|
| `tasks/cf.toml` | `tasks/tool-cf.toml` |
| `tasks/gh.toml` | `tasks/tool-gh.toml` |
| `tasks/docker.toml` | `tasks/tool-docker.toml` |
| `tasks/cliff.toml` | `tasks/tool-cliff.toml` |
| `tasks/rust.toml` | `tasks/tool-rust.toml` |
| `tasks/wrangler.toml` | `tasks/tool-wrangler.toml` |
| `tasks/fnox.toml` | `tasks/tool-fnox.toml` |
| `tasks/bw.toml` | `tasks/secrets-bw.toml` |
| `tasks/provision.toml` **+** `tasks/prove.toml` | `tasks/cfapp.toml` |
| `tasks/env.toml` | **removed** — delete the include |

(`ci.toml`, `mise.toml`, `release.toml`, `secrets.toml`, `mobile.toml` keep their names.)

**3. Rename any task you invoke** (grep the whole repo — `mise.toml`, shell, CI yml, docs):

| old | new |
|---|---|
| `mise:global` | `mise:global:bootstrap` |
| `ci:watch` / `ci:clean` | `gh:run-watch` / `gh:run-clean` |
| `ci:check-toml-tasks` / `ci:check-workflow-nu` / `ci:parse-check` | `ci:check-nu` |
| `bw:<x>` | `secrets:bw-<x>` |
| `cf:provision-*` / `provision:*` | `cfapp:provision-*` |
| `cf:access-*` / `cf:service-token-*` / `provision:access-*` | `cfapp:access-*` / `cfapp:service-token-*` |
| `cf:secrets-put-mapped` | `cfapp:provision-secrets` |
| `prove:bindings`/`secrets`/`deployed`/`access-policy` | `cfapp:verify-bindings`/`-secrets`/`-deployed`/`-access-policy` |

(The `cf:*` primitives — `d1-create`/`r2-create`/`queue-create`/`secret-put`/`token-check`
— are now pure wrangler/curl and read the CF token from `$env`; you drive them via
`cfapp:*`, which provides the token from fnox.)

**4. Re-bootstrap + verify:** follow [README §1](./README.md#1-use-it-in-a-repo) —
`mise run mise:repo:bootstrap`, then `mise run ci` **locally**, then push and confirm
the GitHub Actions matrix is green. Don't skip the local run.

**Reference:** copy the shape of
[`.github-example`](https://github.com/joeblew999/.github-example) — the canonical
consumer, CI-tested against every `.github` change, so it's never stale.
