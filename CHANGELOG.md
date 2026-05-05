# Changelog

All notable changes to the shared mise task library. Bump consumer repos'
`[task_config].includes` pin when adopting a new release.

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
