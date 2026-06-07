# Changelog

All notable changes to the shared mise task library. Bump consumer repos'
`[task_config].includes` pin when adopting a new release.

## v0.24.0 — 2026-06-07

**No more version pinning.** Common tools float to `latest`; the lib carries no
versions except two deliberate toolchain pins.

### Changed

- **All common tools → `latest`**: fnox, nushell, gh, jq, usage, git-cliff
  (lib `[tools]`), plus wrangler, wasm-pack, tauri-cli (per-task). git is
  versioned by you globally; mise floats the rest. **Deliberate exceptions:**
  `java` (`temurin-17` — Android NDK/Gradle need a specific JDK) and `ruby`
  (`3.3` — CocoaPods toolchain) stay pinned.
- **Dropped 7 now-empty `_base` tasks** (cf/ci/mobile/prove/rust/secrets/wrangler)
  + their `extends` + orphaned comments — after the v0.22/v0.23 sweeps they held
  nothing. `bw:_base` stays (carries `@bitwarden/cli`). So `extends` (and the
  `[settings].experimental` it needs) is now only relevant to `bw:*` consumers.

### Still open (next refactor)

- Retire the deprecated `mise-tasks/` dir: port `release` → a `mise:release`
  TOML task and update the 5 workflows that still reference `mise-tasks/`. Left
  for a deliberate, workflow-aware pass.

## v0.23.0 — 2026-06-07

**Canonical tool specs + global config as the single source of truth.** Resolves
the v0.22.0 "still open" item.

### Changed

- **Standardised every tool spec to its registry short-name**: `github:jdx/fnox`
  → `fnox`, `aqua:cli/cli` → `gh`, `aqua:jqlang/jq` → `jq`, `cargo:usage-cli` →
  `usage`, `aqua:orhun/git-cliff` → `git-cliff`, `npm:wrangler` → `wrangler`.
  (nushell has no registry short-name, so `github:nushell/nushell` stays as the
  canonical backend.) mise no longer sees the same tool under multiple backends.
- **Bumped the canonical versions** to current: `fnox 1.25.1`, `nushell 0.113.1`.

### Added

- **`mise:global-sync --write`** now safe (specs are canonical, so `mise use -g`
  aligns instead of duplicating). Run from `.github` to make the lib's `[tools]`
  the canonical **global** set; every repo then inherits and nothing drifts.

### Migration

Consumers: drop the ubiquitous tools (nushell, fnox, gh, git-cliff…) from your
repo `[tools]` and rely on global; run `mise run mise:global-sync --write` once
from `.github`, then `mise run mise:sweep` to prune the now-orphaned installs.

## v0.22.0 — 2026-06-07

**Stop pinning ubiquitous tool versions per-task.** Every `*:_base` (and a few
tasks) pinned `nushell 0.112` / `fnox 1.24`, while consumer repos pin their own
(e.g. nushell `0.113.1`, fnox `1.25.1`) and the global config a third (fnox
`1.19.0`). That three-way skew installed duplicate versions and confused the
mise GUI / `[tools]` view. Tasks now declare **no version pins** for ubiquitous
tools — they inherit from the consumer's global config / `[tools]`, so there's
one version and no drift.

### Changed

- **Swept every `*:_base`**: removed `nushell` + `fnox` version pins across all
  namespaces. Genuinely task-specific tools stay per-task (`wrangler`, `java`,
  `@bitwarden/cli`, `gh`). `cliff:*` dropped its `_base` entirely — `git-cliff`
  now comes from your global config (`mise use -g aqua:orhun/git-cliff`).
- **Requirement:** consumers must have the ubiquitous tools (nushell, fnox, gh,
  git-cliff) available via their **global** `~/.config/mise/config.toml` or repo
  `[tools]`. The lib still pins them in its own `[tools]` for self-runs.

### Added

- **`mise:global-sync`** — reports drift between a repo's `[tools]` and the
  global config and prints the `mise use -g` commands to align (read-only;
  normalises tool short-names so `github:jdx/fnox` vs `fnox` isn't mistaken for
  two tools). Run it from `.github` to make the lib's `[tools]` the canonical
  global set. Never repoints the config path (VSCode-safe).

### Still open

- **Backend canonicalisation** — the lib uses `github:jdx/fnox` / `github:nushell/nushell`
  while global/repos use `fnox` / `nushell`. mise treats those as different
  tools, so making global authoritative (a `--write`) needs one canonical
  backend per tool chosen first. Tracked for a follow-up.

## v0.21.0 — 2026-06-07

Adds the `cliff:*` namespace — changelog / release intelligence via git-cliff.
Additive; opt-in per consumer (add the include). No change to existing tasks.

### Added

- **`tasks/cliff.toml`** (`cliff:*`) — map commits to release tags with
  [git-cliff](https://github.com/orhun/git-cliff), for this repo and any
  third-party repo you track (no cooperation needed from the other repo):
  - `cliff:unreleased` — this repo's changes since the last tag.
  - `cliff:show` — this repo's full changelog.
  - `cliff:repo <owner/repo> [fromTag]` — clone any external repo and show its
    unreleased delta. Defaults to the latest **semver** tag, so rolling tags
    (e.g. `nightly`) don't hide the delta.
  - mise-native: `aqua:orhun/git-cliff` pinned in `tools`; the nu bodies only
    call the binary. The inverse lookup ("which release shipped commit X?")
    stays a `git tag --contains <sha>` one-liner, not a task.

## v0.20.0 — 2026-06-04

### Added

- **`mise:sweep`** — reclaim dead mise state (dead config links + unused tool
  versions) across all repos under `--root`. Re-tracks live configs first.

## v0.19.2 — 2026-05-07

Docs + cleanup. No behaviour change for consumers — `?ref=` bump is
optional, but recommended so `ci:audit-lib-refs` stops flagging.

### Changed

- **README + CONTRIBUTING + AGENTS.md** refreshed for v0.19.x reality.
  README's `?ref=` example was on v0.3.0; CONTRIBUTING described the
  legacy file-task authoring flow only; AGENTS.md status block was a
  v0.16.x snapshot.
- **`mise-tasks-lint.yml`** slimmed 238 → 124 lines. Negative-path
  execution is fully covered by `tasks-toml-proof.yml`; the dead Tera
  bash check (no bash files left after v0.10.0) is gone. Workflow is
  now legacy-only as titled.
- **`mise-tasks/README.md`** + **`mise-tasks/CONSOLIDATION.md`** got
  deprecation/status banners pointing at `tasks/`.
- **`.claude/agents/github-meta-repo-expert.md`** deleted — claimed
  "Current release: v0.4.0", duplicated AGENTS.md content. `.claude/README.md`
  now points at AGENTS.md as SSOT.
- **Reusable workflows** clarified to ride the same tag stream as the
  task library (`@vX.Y.Z` in lockstep with `?ref=`).

## v0.19.1 — 2026-05-07

### Added

- **`ci:audit-lib-refs`** — scans every `mise config ls --tracked-configs`
  for `?ref=v…` URLs pointing at the lib and warns if any are not on the
  latest tag. Closes the gap that `mise outdated` doesn't see git URLs in
  `[task_config].includes`. Run from anywhere on the machine — it walks
  *all* tracked mise configs, not just the current repo.

## v0.19.0 — 2026-05-07

### Fixed (Gemini Code Assist feedback bundle)

- **`tasks/secrets.toml`** — `secrets:_base` block was nested inside
  `secrets:sync-github`'s comment header at the top of the file. mise
  parsed it correctly (the `["secrets:_base"]` table header restarted
  the section), but it read as a maintenance hazard. Moved to the top
  of the file with its own `── secrets:_base ──` banner.
- **`ci:check-toml-tasks`** — regex now handles BOTH `'''…'''` and
  `"""…"""` body forms. Previous version silently skipped any task body
  authored with triple-double-quotes.
- **`ci:check-toml-tasks`** — diagnostic filter now requires both
  `"type":"diagnostic"` AND `"severity":"Error"`. Was matching warnings
  and treating them as failures.
- **`ci:audit-lib-refs --dir`** (preview) — handles absolute paths
  correctly (was producing `/abs//rel/…` when an absolute path was
  passed).

### Changed

- **`.github` self-hosts** — root `mise.toml` now explicitly includes
  every `tasks/*.toml`, so the library runs its own `ci:check-toml-tasks`
  and `ci:check-workflow-nu` against itself. Catches drift inside the lib
  before consumers see it.

## v0.18.0 — 2026-05-07

### Changed

- **Extends-based per-task tools dedup** — every namespace now has a
  hidden `<ns>:_base` task that pins shared tools (always nu, sometimes
  fnox/gh/etc.). Each child task `extends = "<ns>:_base"` and only declares
  its delta. mise MERGES tools from base + child, so `nu` and other
  shared pins live in one place per namespace instead of being repeated
  across every task. ~80% reduction in `tools = { … }` block duplication
  across `tasks/`.

  Requires `[settings].experimental = true` in consumer mise.toml (the
  `extends` key is still flagged experimental; behaviour is stable).

## v0.17.5 — 2026-05-07

### Added

- **`ci:check-toml-tasks`** — lints every `run = '''…'''` body in
  `tasks/*.toml` by extracting it to a temp file and running
  `nu --ide-check 1`. Sub-second feedback locally vs. waiting on Actions.
- **`ci:check-workflow-nu`** — same idea for nu blocks embedded in
  `.github/workflows/*.yml`.

Both shared so consumers can wire them into a local `[tasks.check]`
aggregator. The lib runs them on itself in CI.

## v0.17.4 — 2026-05-07

### Added

- **`rust:build`**, **`rust:test`**, **`rust:wasm-pack`** — full `rust:*`
  namespace ported to TOML-tasks. `rust:wasm-pack` pins
  `cargo:wasm-pack = "0.13"` per-task (consumers don't pre-install).
- **`mise:upgrade`** — TOML port; bumps the lib include `?ref=` pin in
  the calling repo's mise.toml.

## v0.17.3 — 2026-05-07

### Added

- Final namespace ports to TOML: **`secrets:*`**, **`fnox:*`**, **`bw:*`**.
  Tools (fnox, bw, gh) propagate per-task — consumers no longer pin them
  globally.

## v0.17.2 — 2026-05-07

### Added

- **`prove:*`** namespace ported to TOML.

### Fixed

- **`wrangler:gen`** description corrected.

## v0.17.1 — 2026-05-07

### Added

- **`env:resolve`** ported to TOML.
- **`wrangler:*`** namespace ported to TOML with per-task `wrangler` pin.

## v0.17.0 — 2026-05-07

### Added

- Full **`cf:*`** namespace ported to TOML-tasks. Per-task tool pins
  (gh, jq, fnox, etc.) propagate via `git::` includes — consumers no
  longer need a global `[tools]` block.

## v0.16.2 — 2026-05-07

### Fixed

- **`mobile:rustup-target-add`** — defensive guard when `rustup` is not
  on PATH. Skips with a friendly message rather than blowing up with a
  command-not-found error.

## v0.16.1 — 2026-05-07

### Added

- **`mobile:*`** namespace ported to TOML-tasks (first non-cf port after
  v0.16.0).

## v0.16.0 — 2026-05-07

### Added

- **TOML-tasks with per-task tools** — new `tasks/*.toml` library
  alongside the legacy `mise-tasks/` file-tasks. Per-task `tools = { … }`
  blocks let each task pin its own dependencies (nu, gh, fnox, jq, …),
  so consumers no longer need a one-size-fits-all `[tools]` block in
  every mise.toml. Tools come along for the ride through the `git::`
  include URL.

  See [`mise-tasks/DEPRECATED.md`](mise-tasks/DEPRECATED.md) for the
  migration table and consumer wiring guide.

## v0.15.3 — 2026-05-07

### Fixed

- **`bw:*`**, **`secrets:*`** — `const here = (path self …)` was
  declared as `let` in earlier shipped tasks, which broke at runtime
  in nu (path self resolves at parse time, but `let` requires runtime
  context). Switched to `const`.

## v0.15.2 — 2026-05-07

### Changed

- README + AGENTS + CLAUDE drift cleanup. `mise-tasks-lint.yml` now
  covers `ci:*` tasks too.

## v0.15.1 — 2026-05-07

### Fixed

- **`ci:parse-check`** — only inspects files with a `#!/usr/bin/env nu`
  shebang. Previous version tripped on README.md and other plain text.

## v0.15.0 — 2026-05-07

### Added

- **Reusable workflows** at `.github/workflows/`:
  - `reusable-mise-ci.yml` — drop-in CI workflow callable via
    `uses: joeblew999/.github/.github/workflows/reusable-mise-ci.yml@vX.Y.Z`.
  - `reusable-mise-upgrade.yml` — automated weekly bump of the lib
    `?ref=` pin via `mise:upgrade`.

## v0.14.1 — 2026-05-07

### Added

- **`ci:parse-check`** — generic nu file parse-checker. Walks a path,
  runs `nu --ide-check 1` against every nu source file, exits non-zero
  on any parse error. Used by every consumer's local `check` task.

## v0.14.0 — 2026-05-07

### Added

- **`ci:watch`**, **`ci:clean`**, **`mise:upgrade`** — convenience
  tasks. `ci:watch` polls `gh run list` until the latest run on the
  current branch finishes; `ci:clean` cancels in-flight runs;
  `mise:upgrade` bumps the lib pin to the latest tag.

## v0.13.1 — 2026-05-05

### Fixed

- **`cf:service-token-setup`** — service tokens now correctly bypass the
  OAuth flow. v0.13.0 added the service-token "Include" rule to the existing
  `operator-only` policy whose `decision` is `allow` — but `allow` requires
  identity verification, so service-token-headed requests still got
  redirected through CF Access OAuth (`auth_status: NONE` → 302 to login,
  causing redirect loops in `wrangler dev` with `remote=true` AI bindings).

  v0.13.1 creates a **separate `service-token-only` policy** with
  `decision: "non_identity"`, which is the CF Access primitive that bypasses
  OAuth when valid service-token headers are present. The two policies coexist
  on the same Access App:

  ```
  operator-only        decision=allow         include=[email1, email2, ...]
  service-token-only   decision=non_identity  include=[service_token: <uuid>]
  ```

  The setup task also auto-scrubs any stale v0.13.0 includes left over in
  the operator-only policy. Re-run `cf:service-token-setup` after upgrading
  to migrate cleanly.

- **`cf:service-token-revoke`** — now deletes the `service-token-only` policy
  entirely instead of trying to scrub it from `operator-only`. Falls back to
  cleaning any stale allow-policy includes for full backward compatibility
  with v0.13.0 deployments.

## v0.13.0 — 2026-05-05

### Added

- **`cf:service-token-setup`** — new task. Provisions a CF Access service
  token so wrangler dev (with `remote = true` bindings), Playwright
  automation, CI, and any other non-interactive client can authenticate
  past the Access wall. Without one, `mise run dev` errors with:

  > The domain "X.workers.dev" is behind Cloudflare Access, but no Access
  > Service Token credentials were found and the current environment is
  > non-interactive…

  Usage (one-time per repo):

  ```bash
  mise run cf:service-token-setup
  ```

  Steps it performs:

  1. POSTs `/accounts/{id}/access/service_tokens` to create
     `<WORKER_NAME>-automation` (skipped if fnox already has the creds).
  2. Stores `client_id` + `client_secret` in fnox keychain under canonical
     names `CLOUDFLARE_ACCESS_CLIENT_ID` and `CLOUDFLARE_ACCESS_CLIENT_SECRET`
     — matches the env vars wrangler/vite-plugin look up automatically.
  3. PUTs the operator-only policy with a new `service_token` include rule
     so requests carrying these headers are allowed alongside the existing
     email allowlist.

  Idempotent. fnox is the source of truth: re-runs are no-ops once the
  creds are stored. If the CF-side token is deleted but fnox still has
  values, the task aborts with guidance (rotate or recreate).

- **`cf:service-token-revoke`** — companion task. Deletes the token at CF,
  scrubs its include rule from the operator-only policy, and clears the
  fnox keychain entries. Use to rotate (revoke + setup again), kill a
  leaked secret, or decommission. Idempotent — safe when nothing exists.

  ```bash
  mise run cf:service-token-revoke
  ```

  Order of operations: policy include → token delete → fnox clear. An
  in-flight request might still complete during teardown but will fail at
  the policy-check step on its next call, which is the correct failure
  mode for "revoked".

### Why this complements v0.12.0

`cf:access-setup` + `cf:access-revoke` cover the **human OAuth path**
(GitHub IdP, email allowlist, browser cookies). The two new tasks cover
the **machine-to-machine path** (service token via Client ID + Secret
headers). Same Access App, same operator-only policy — both auth modes
coexist as separate "Include" rules. Pick whichever your client supports.

## v0.12.0 — 2026-05-05

### Added

- **`cf:access-revoke`** — new task. Revokes ALL active Cloudflare Access
  sessions for the Worker (kicks everyone out — they re-login if still
  allowlisted). Useful when you want to evict someone *right now* rather
  than wait for their session cookie (24h default) to expire. Usage:

  ```bash
  mise run cf:access-revoke
  ```

  Calls `POST /accounts/{id}/access/apps/{app_id}/revoke_tokens`. Reads
  `WORKER_NAME` + `CF_SUBDOMAIN` from `config/<env>.env` to find the
  Access App. Does NOT touch the allow policy — pair with `cf:access-setup`
  (after editing `OPERATOR_EMAIL`) for permanent removal.

  Why app-wide and not per-user? The per-email endpoint
  (`organizations/revoke_user`) requires the broader scope "Access:
  Organizations, Identity Providers, and Groups: Edit" which the
  standard `cf:access-setup` token shape doesn't carry. The app-level
  endpoint works with the same `Access: Apps and Policies: Edit` scope
  that policy management already needs. Trade-off: any other
  allowlisted user is also evicted and must re-login (5s OAuth flow).

### Changed

- **`cf:access-setup`** — auto-revokes active sessions when the allow
  set shrinks. When a re-run drops one or more emails from the existing
  policy, the script now POSTs `apps/{id}/revoke_tokens` after the
  policy PUT succeeds. Closes the window where a removed user kept
  their existing session cookie until it timed out. No-op on adds or
  no-changes.

### Migration notes

Pure additive — bump the include pin, no caller-side changes:

```diff
- includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.11.0"]
+ includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.12.0"]
```

If someone you removed via `cf:access-setup` on v0.11.0 still has an
active session, run `mise run cf:access-revoke` once on v0.12.0 to
evict them (and re-login yourself).

## v0.11.0 — 2026-05-05

### Fixed

- **`cf:access-setup`** — allow-policy idempotency. Previous versions
  created a NEW policy on every re-run because the dedupe check compared
  the literal `OPERATOR_EMAIL` string (e.g. `"a@x.com,b@y.com"`) against
  a flat list of individual emails — never matched, so it always took
  the create path. Result: appending an email to `OPERATOR_EMAIL` and
  re-running piled on duplicate `operator-only` policies.

  v0.11.0 switches to a set-based ensure: split `OPERATOR_EMAIL` into a
  sorted set, find the existing `operator-only` allow policy, PUT-update
  its include list if the set differs, only POST a new policy when none
  exists. No caller-side changes — same `config/<env>.env` shape.

### Migration notes for consumers (mon-house, kv-manager, d1-manager, etc.)

1. Bump the include pin in your `mise.toml`:

   ```diff
   - includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.10.0"]
   + includes = ["git::https://github.com/joeblew999/.github.git//mise-tasks?ref=v0.11.0"]
   ```

2. **If you already have duplicate `operator-only` policies** from
   running v0.10.0 multiple times: the new task warns and uses the
   first one. Clean up the duplicates either via the CF dashboard
   (Access → Apps → your app → Policies) or via the API:

   ```bash
   # List policies
   TOKEN=$(fnox get CLOUDFLARE_API_TOKEN)
   ACCT=$(fnox get CLOUDFLARE_ACCOUNT_ID)
   curl -sS -H "Authorization: Bearer $TOKEN" \
     "https://api.cloudflare.com/client/v4/accounts/$ACCT/access/apps/<APP_ID>/policies" | jq

   # Delete the orphan(s) — keep the most comprehensive one
   curl -sS -X DELETE -H "Authorization: Bearer $TOKEN" \
     "https://api.cloudflare.com/client/v4/accounts/$ACCT/access/apps/<APP_ID>/policies/<POLICY_ID>"
   ```

3. Re-run `mise run cf:access-setup`. The output should now include
   one of: `✓ policy already matches`, `→ updating policy ... → ...`,
   or `→ no existing policy, creating`.

If you only ever ran v0.10.0 once with a single email, no cleanup is
needed — upgrade silently.

## v0.10.0 — 2026-05-02

Full nushell migration. All 33 mise-tasks ported from bash to nushell
for Windows compatibility. CI proof on every push (parse-check on macOS
+ Linux + Windows, fnox-keychain round-trip, 12-task real-execution
test). 9 consumer repos rolled out in lockstep.

See [`AGENTS.md`](./AGENTS.md) for the full v0.10.0 status snapshot.
