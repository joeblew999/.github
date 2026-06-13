# Platform systems — the map

The shared, reusable systems across the fleet, and the **one repo to start in**
for each. Projects *consume* these; the components of each system live in their
own repos (linked from the system's home README — not duplicated here).

> **The convention:** a shared system gets a **home/front-door repo** (overview +
> how to use it + deploy). Its building blocks stay in their own repos. So
> cross-cutting "how does this fit together?" always has one address — here, then
> the system's home.

| System | Home repo | What it is |
| --- | --- | --- |
| **Auth** | **[`iam`](https://github.com/joeblew999/iam)** | Rauthy (OIDC IdP — AuthN) + Cedar (policy AuthZ) + Cloudflare email. Reused on **every** project. Start here to add auth to a project. |
| **Deploy** | **[`vm-uncloud`](https://github.com/joeblew999/vm-uncloud)** | The single home for Hetzner deployments via uncloud — recipes (Rauthy, Moltis, WordPress, Windows VMs…), one cost ledger. |
| **Tooling** | **[`.github`](https://github.com/joeblew999/.github)** (this repo) | Shared mise task library (by-reference, same locally + CI) + Claude plugin marketplace + org config. |

Each home README links its components. For example, **`iam`** composes the Rauthy
recipe (in `vm-uncloud`), the `connectrpc-oidc` + `connectrpc-cedar` crates (in
`cf-connectrpc-middleware`), and the email handler (in `saasmail`).

---

*Add a row when a new reusable system gets a home repo. Individual product repos
that just consume the platform don't belong here — they live on their own.*
