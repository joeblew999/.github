# Changelog

All notable changes to the shared mise task library. Bump consumer repos'
`[task_config].includes` pin when adopting a new release.

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
