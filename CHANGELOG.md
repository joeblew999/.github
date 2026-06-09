## [0.45.0] - 2026-06-09

### 🚀 Features

- *(docker)* $DOCKER_BUILD policy (auto|ci|local|never) — repos control local-vs-remote docker build independently via mise.toml [env]
## [0.44.0] - 2026-06-09

### 🚀 Features

- *(docker)* Add docker:build — CI-safe build-only verify (no push/secrets), skips where docker is unusable so one ci stays green on every OS

### 🐛 Bug Fixes

- *(docker)* Docker:build gate — which-guard (no crash when binary absent on macOS runner) + require OSType=linux (skip Windows-containers daemon); avoid {{}} Tera
- *(docker)* Remove literal double-brace from docker:build comment (Tera parsed it → __tera_one_off error at runtime)

### ⚙️ Miscellaneous Tasks

- *(release)* V0.44.0
## [0.43.0] - 2026-06-09

### 🐛 Bug Fixes

- *(release)* Correct caller-grants-contents:write docs + generate mise-release.yml stub

### ⚙️ Miscellaneous Tasks

- *(release)* V0.43.0
## [0.41.2] - 2026-06-09

### 📚 Documentation

- *(migration)* Point repos at v0.41.1 (additive from v0.40.x) + withdraw note for v0.41.0/v0.42.0
- Regenerate CHANGELOG from cliff (drop withdrawn v0.41.0/v0.42.0) + make MIGRATION version-stable (defer per-version detail to CHANGELOG)

### ⚙️ Miscellaneous Tasks

- *(release)* V0.41.2
## [0.41.1] - 2026-06-09

### 🚀 Features

- *(docs)* Generate README two-layer tables from tasks/ + CI guard; update skill
- *(release)* Reusable-mise-release workflow + release:publish task

### 🐛 Bug Fixes

- *(docs)* Docs:check compares EOL-insensitively + .gitattributes eol=lf (Windows CRLF false-stale)

### ⚙️ Miscellaneous Tasks

- *(release)* V0.41.0
- *(release)* V0.42.0
- *(release)* V0.41.1
## [0.40.1] - 2026-06-09

### 📚 Documentation

- Add MIGRATION.md (v0.40.0 rename tables) + link from README

### ⚙️ Miscellaneous Tasks

- *(release)* V0.40.1
## [0.40.0] - 2026-06-09

### 🚀 Features

- *(workflow-templates)* Bootstrap the mise CI workflow org-wide
- *(ci)* Ci:audit-lib-refs --write + wire into reusable-mise-upgrade
- *(mise)* Mise:repo:bootstrap[-delete] + base ci; rename bootstrap tasks
- *(dogfood)* Make .github's CI realistic — exercise tasks, not just parse

### 🐛 Bug Fixes

- *(mise:repo:bootstrap)* Tera raw-block the YAML so ${{ }} survives; reword comment to contain no Tera tokens
- *(mise:repo:bootstrap)* Run CI on all 3 OSes (ubuntu+macos+windows), sccache off
- *(mise:repo:bootstrap)* Inherit reusable defaults; stub overrides only
- *(ci:check-global, mise:sweep)* Forward-slash glob pattern for Windows
- *(reusable-mise-upgrade)* Seed nu via mise:global:bootstrap before the nushell tasks
- *(release:pack, ci:audit-lib-refs)* Windows glob bug — caught by realistic dogfood

### 🚜 Refactor

- *(mise:repo:bootstrap)* Generate minimal stub, no hardcoded YAML/Tera
- *(ci:check-global, mise:sweep)* Proper relative-glob nushell
- *(ci)* Obey our own rules — isomorphic, DRY, namespace=tool
- *(cf)* Decompose into atomic primitives + provision orchestration
- *(docker)* Pure namespace — GHCR_USER from env/fnox, drop the ^gh call
- *(cf)* Strictly single-tool — drives only wrangler+curl, fnox moves up
- *(docker, gh)* Strict purity — tokens from $env, no fnox
- Prefix pure-tool files with tool- so the two layers are visible
- *(orchestration)* 7 namespaces → 5 (one per lifecycle concern)
- Remove dead env.toml (env:resolve was an orphaned hidden helper)

### 📚 Documentation

- Cross-ref the .github-example sandbox at top of README
- Put 'Order of operations' front-and-center in README
- *(AGENTS)* Put the order of operations at the very top (edit→validate→release→adopt)
- Step 2 = validate in BOTH local and CI (local can pass while CI fails)
- Sandbox consumes .github@main (rolling) via the proper reusable CI; fix step 2
- *(AGENTS)* Add the CONSUMER adoption order (skills→CLAUDE.md→includes→global→rust→CI)
- CI bootstrap = workflow-template (one click); update = mise-upgrade PR
- *(workflows)* README explaining the reusable/recursion system + header pointers
- *(SSOT)* Root README is the single source; AGENTS rule + reusable headers point here; fix mise.yaml→mise.yml
- Fix stale refs (cf:secrets-put-mapped→provision:secrets, ci:check-toml-tasks→ci:check-nu, tasks-toml-proof→dogfood, mise.yaml→mise.yml)
- *(README)* Rewrite around the two-layer model
- *(README)* Restructure for flow — use → how CI works → what's inside → develop
- *(README)* Make the consumer CI story clear — one task, local AND remote
- *(README)* Point repos at .github-example as the canonical, CI-tested reference

### ⚙️ Miscellaneous Tasks

- *(release)* V0.40.0
## [0.39.0] - 2026-06-08

### 🚀 Features

- *(marketplace)* .github is the joeblew999 Claude plugin marketplace (fleet skill)

### ⚙️ Miscellaneous Tasks

- *(release)* V0.39.0

### ◀️ Revert

- *(stamp)* Remove reinvented stamp:repo/templates/skills-copy — the fleet already stamps by reference
- *(stamp)* Actually remove tasks/stamp.toml + fix AGENTS heading
## [0.38.0] - 2026-06-08

### 🚀 Features

- *(stamp)* Stamp .github wiring + claude skills into consumer repos; AGENTS deep-refactor directive

### ⚙️ Miscellaneous Tasks

- *(release)* V0.38.0
## [0.37.0] - 2026-06-08

### 🚜 Refactor

- [**breaking**] Tool-based task namespaces (namespace = the tool)

### ⚙️ Miscellaneous Tasks

- *(release)* V0.37.0
## [0.36.2] - 2026-06-08

### 🐛 Bug Fixes

- *(release:pack)* Flat archives (contents at tar root, goreleaser-standard)

### ⚙️ Miscellaneous Tasks

- *(release)* V0.36.2
## [0.36.1] - 2026-06-08

### 🐛 Bug Fixes

- *(release:pack)* Use glob not ls for the archive count (ls won't expand a string path)

### ⚙️ Miscellaneous Tasks

- *(release)* V0.36.1
## [0.36.0] - 2026-06-08

### 🚀 Features

- *(tasks)* Shared release:pack + docker:* (fleet binary/docker release)

### ⚙️ Miscellaneous Tasks

- *(release)* V0.36.0
## [0.35.1] - 2026-06-08

### 🐛 Bug Fixes

- *(mise)* Anchor ci:check-global RUSTUP_TOOLCHAIN regex to line start

### ⚙️ Miscellaneous Tasks

- *(release)* V0.35.1
## [0.35.0] - 2026-06-08

### 🚀 Features

- *(mise)* Add ci:check-global guard enforcing rustup-owned Rust toolchains

### ⚙️ Miscellaneous Tasks

- *(release)* V0.35.0
## [0.34.0] - 2026-06-07

### 📚 Documentation

- Version-free <tag> in all task-header example refs (no more stale ?ref=)

### ⚙️ Miscellaneous Tasks

- *(release)* V0.34.0
## [0.33.0] - 2026-06-07

### 🐛 Bug Fixes

- *(cliff)* Target fork's own repo (--repo) + push only the release tag

### ⚙️ Miscellaneous Tasks

- *(release)* V0.33.0
## [0.32.0] - 2026-06-07

### 🐛 Bug Fixes

- *(cliff)* Allow fork-distinct semver suffix + verify uploaded assets

### ⚙️ Miscellaneous Tasks

- *(release)* V0.32.0
## [0.31.0] - 2026-06-07

### 🐛 Bug Fixes

- *(cliff)* Cliff:release works on any branch, not just main

### ⚙️ Miscellaneous Tasks

- *(release)* V0.31.0
## [0.30.0] - 2026-06-07

### 🚀 Features

- *(cliff)* Cliff:release uploads binary assets (optional trailing args)

### ⚙️ Miscellaneous Tasks

- *(release)* V0.30.0
## [0.29.0] - 2026-06-07

### 🚀 Features

- *(cliff)* Add cliff:release git-cliff release driver; rewrite AGENTS.md

### ⚙️ Miscellaneous Tasks

- *(release)* V0.29.0
## [0.28.0] - 2026-06-07

### 🚀 Features

- *(mise)* Mise:global task (local=CI); global = runtime-free binaries (v0.28.0)
## [0.27.0] - 2026-06-07

### ⚙️ Miscellaneous Tasks

- *(mise)* Retire dead experimental flag + rejected-approach workflow (v0.27.0)
## [0.26.0] - 2026-06-07

### 🚀 Features

- *(mise)* Namespaces front the tools — global toolset, CI parity (v0.26.0)
## [0.25.0] - 2026-06-07

### 🚜 Refactor

- *(mise)* Retire legacy mise-tasks/ tree; port release→mise:release (v0.25.0)
## [0.24.0] - 2026-06-07

### 🚀 Features

- *(mise)* No version pinning — common tools float to latest (v0.24.0)
## [0.23.0] - 2026-06-07

### 🚀 Features

- *(mise)* Canonical tool short-names + global as SSOT (v0.23.0)
## [0.22.0] - 2026-06-07

### 🚀 Features

- *(mise)* Drop per-task ubiquitous tool pins; add mise:global-sync (v0.22.0)
## [0.21.0] - 2026-06-07

### 🚀 Features

- *(cliff)* Add cliff:* namespace — git-cliff changelog/release intel (v0.21.0)
## [0.20.0] - 2026-05-31

### 🚀 Features

- *(mise)* Add mise:sweep task to reclaim dead mise state
## [0.19.2] - 2026-05-07

### 📚 Documentation

- Mark legacy mise-tasks/ as deprecated
- Refresh README/CONTRIBUTING/CHANGELOG; slim legacy lint workflow
- *(agents)* Clarify reusable workflow versioning aligns with task lib tag
- Refresh AGENTS.md status block; drop stale .claude agent file
- *(changelog)* V0.19.2 entry
## [0.19.1] - 2026-05-07

### 🚀 Features

- *(ci)* Ci:audit-lib-refs — drift detection for ?ref= URLs (v0.19.1)
## [0.19.0] - 2026-05-07

### 🐛 Bug Fixes

- *(v0.19)* Gemini Code Assist feedback bundle (#47)
## [0.18.0] - 2026-05-07

### 🚜 Refactor

- *(tasks)* Extends-based tools dedup across all namespaces (v0.18) (#46)
## [0.17.5] - 2026-05-07

### 🚀 Features

- *(ci)* Ci:check-toml-tasks + ci:check-workflow-nu shared tasks (v0.17.5) (#45)
## [0.17.4] - 2026-05-07

### 🚀 Features

- *(tasks)* Port rust:* + mise:upgrade + inline ide-check (v0.17.4) (#44)

### 🐛 Bug Fixes

- *(lint)* Skip 3 Windows-broken legacy *-dry cases (covered by TOML proof)

### 📚 Documentation

- *(agents)* Refresh for v0.16.x TOML-task reality + bump fnox 1.23→1.24 (#39)
## [0.17.3] - 2026-05-07

### 🚀 Features

- *(tasks)* Port secrets/fnox/bw — final namespace batch (v0.17.3) (#43)
## [0.17.2] - 2026-05-07

### 🚀 Features

- *(tasks)* Port prove:* to TOML + fix wrangler:gen description (v0.17.2) (#42)
## [0.17.1] - 2026-05-07

### 🚀 Features

- *(tasks)* Port env:resolve + wrangler:* to TOML (v0.17.1) (#41)
## [0.17.0] - 2026-05-07

### 🚀 Features

- *(tasks)* Port full cf:* namespace to TOML (v0.17.0) (#40)
## [0.16.2] - 2026-05-07

### 🐛 Bug Fixes

- *(mobile)* Guard rustup-target-add when rustup not on PATH (#38)
## [0.16.1] - 2026-05-07

### 🚀 Features

- *(tasks)* Port mobile:* namespace to TOML with per-task tools (#37)
## [0.16.0] - 2026-05-07

### 🚀 Features

- TOML-tasks with per-task tools (v0.16.0) (#36)
## [0.15.3] - 2026-05-07

### 🐛 Bug Fixes

- *(bw, secrets)* Const here = (path self ...) — was let, broken at runtime

### 💼 Other

- Pointer to AGENTS.md only (don't duplicate content)
## [0.15.2] - 2026-05-07

### ⚙️ Miscellaneous Tasks

- README + AGENTS + CLAUDE drift cleanup; lint covers ci:* tasks
## [0.15.1] - 2026-05-07

### 🐛 Bug Fixes

- *(ci:parse-check)* Filter to files with nu shebang (skip .md, etc.)
## [0.15.0] - 2026-05-07

### 🚀 Features

- *(workflows)* Reusable Mise CI + Mise upgrade workflows (v0.15.0)
## [0.14.1] - 2026-05-07

### 🚀 Features

- *(ci)* Ci:parse-check task — generic nu file parse-checker (v0.14.1)
## [0.14.0] - 2026-05-07

### 🚀 Features

- *(ci, mise)* Add ci:watch, ci:clean, mise:upgrade tasks (v0.14.0)
## [0.13.1] - 2026-05-05

### 🐛 Bug Fixes

- *(cf)* Service tokens need decision: non_identity policy (v0.13.1)
## [0.13.0] - 2026-05-05

### 🚀 Features

- *(cf)* Cf:service-token-setup + cf:service-token-revoke (v0.13.0)
## [0.12.1] - 2026-05-05

### 🐛 Bug Fixes

- *(cf)* Use app-level revoke_tokens (works with existing token scope)
## [0.12.0] - 2026-05-05

### 🚀 Features

- *(cf)* Auto-revoke removed users + new cf:access-revoke task (v0.12.0)
## [0.11.0] - 2026-05-05

### 🚀 Features

- *(lint)* Real-execution negative-path tests for every task
- *(lint)* Migrate 3 more workflow steps from bash to nu (full SSOT in CI)

### 🐛 Bug Fixes

- *(test)* Real bug + test-expectation fixes after first run
- *(test)* Use 'shell: nu' for negative-path test — dogfood SSOT in CI
- *(lint)* Factor Tera-check shebang lookup into a nu def
- *(lint)* Revert Tera-syntax check to bash — pragmatic, not every step migrates cleanly
- *(lint)* Nu shell — drop redundant mise wrapper, use glob, handle Windows
- *(lint)* Use 'path type' to filter dirs out of glob
- *(lint)* Revert verify-scripts + parse-check to bash
- *(cf:access-setup)* Set-based allow-policy ensure (v0.11.0)

### 📚 Documentation

- Consolidation plan — stop adding primitives, plan composition layer
- *(AGENTS.md)* Refresh for v0.10.0 + link consolidation plan
- *(consolidation)* Note utm-dev-cli generalization beyond Tauri
## [0.10.0] - 2026-05-02

### 🚀 Features

- *(lint)* Nu cross-platform proof step + accept nu shebangs
- *(lint)* Add fnox keychain round-trip proof on Windows + macOS
- *(bw)* Port bw:list to nushell — first real shared task on nu
- *(bw)* Port ALL bw:* tasks to nushell — full SSOT migration
- Port ALL remaining mise-tasks bash → nushell — full SSOT

### 🐛 Bug Fixes

- *(lint)* Comment in bw/bootstrap was self-flagging Tera-syntax check

### ⚙️ Miscellaneous Tasks

- Pin nushell to 0.112 in .github mise.toml
## [0.9.0] - 2026-05-02

### 🚀 Features

- *(bw)* Keychain ↔ NodeWarden hybrid sync tasks
## [0.8.3] - 2026-05-01

### 🐛 Bug Fixes

- *(wrangler:gen)* Use bash native substitution (works with all envsubsts) (#35)
## [0.8.2] - 2026-05-01

### 🐛 Bug Fixes

- *(wrangler:gen)* Only substitute vars defined in env file (#34)
## [0.8.1] - 2026-05-01

### 🚀 Features

- *(wrangler:gen)* Auto-detect .toml.template vs .jsonc.template (#33)
## [0.8.0] - 2026-05-01

### 🚀 Features

- *(cf)* Provision-queues + soften provision-d1-r2 (#32)
## [0.7.0] - 2026-04-30

### 🚀 Features

- *(mise-tasks)* Wrangler:gen + prove:{deployed,access-policy,bindings,secrets}
## [0.6.0] - 2026-04-30

### 🚀 Features

- *(mise-tasks)* Cf:access-setup, cf:provision-d1-r2, cf:secrets-put-mapped, env:resolve
## [0.5.0] - 2026-04-28

### 🚀 Features

- *(mobile)* Add Tauri mobile mise-tasks for Android + iOS

### ⚙️ Miscellaneous Tasks

- Clean up .github repo — pin tools, remove stale content, plan vm: namespace
## [0.4.0] - 2026-04-28

### 🚀 Features

- *(mise-tasks)* Add #USAGE annotations for tab completion via jdx/usage

### 📚 Documentation

- Add utm-dev cross-platform wiring + fix stale v0.2.0 refs
## [0.3.0] - 2026-04-28

### 🚀 Features

- *(mise-tasks)* Wrangler:tail, wrangler:secret-list, cf:token-check

### 🐛 Bug Fixes

- Close all audit gaps in mise-tasks + CI lint
- *(mise-tasks)* Three quality fixes from audit

### 📚 Documentation

- *(agents)* CLAUDE.md + AGENTS.md + release task + README authoring guide

### ⚙️ Miscellaneous Tasks

- Delete NATS / Taskfile / age era — keep mise-tasks + org config
- Repo hygiene + mise-tasks dev experience
- Test on ubuntu + macos + windows, shell: bash for SSOT
- Trigger lint on workflow file changes + add workflow_dispatch
- Use actions/checkout@v5 (consistent with all other repos)
- Bump jdx/mise-action v2 → v4 (Node 24)
- Bump actions/checkout v5 → v6 (latest)
## [0.2.0] - 2026-04-27

### 🚀 Features

- Refactor to template-based approach with Go processor
- Complete template-based GitHub organization setup
- Add GitHub CLI validation and verification
- Add comprehensive enhancements and finalization
- Add workflow monitoring and template test marker
- Add NATS-powered snake prevention with Synadia Cloud integration
- Add comprehensive cross-platform compatibility
- Integrate bee for next-generation event-driven GitHub workflows
- Multi-repo infrastructure platform with comprehensive secret management
- Add comprehensive logging system with Playwright guidance for Synadia NATS
- Add complete NATS-Playwright integration
- Add Claude agent configuration for meta-repo expertise
- Add email contact as SVG image in repository
- Add security credentials and compliance benefits
- Enhance profile with notable clients, team leadership, and education
- Make product development focus front and center
- Add investor outreach to partnership opportunities
- Add European Climate Foundation to Notable Clients with role detail
- Add Ubuntu Software logo to profile
- Add email signature SVG
- Add rust-wasm Claude Code skill
- Add cf-workers Claude Code skill
- Add truck-kernel Claude Code skill
- Add mise rust:build task
- Add mise rust:test task
- Add mise rust:wasm-pack task
- Add mise wrangler:dev task
- Add mise wrangler:deploy task
- Add mise cf:d1-migrate task
- *(mise-tasks)* Shared secrets + fnox tasks (keychain workflow)

### 🐛 Bug Fixes

- Resolve idempotent race condition
- Regenerate GitHub Actions from templates
- Properly quote GITHUB_OUTPUT in workflow template [skip-regen]
- Add write permissions to GitHub Actions workflow [skip-regen]
- Use absolute GitHub URL for email SVG image
- Change email SVG text to white to match profile style
- Use full URL text for blog link
- Adjust email SVG vertical alignment
- Further adjust email SVG vertical alignment
- Fine-tune email SVG vertical alignment
- *(mise-tasks)* Chmod +x existing tasks
- *(mise-tasks)* Detect repo via git remote, not gh repo view

### 💼 Other

- *(deps)* Bump github.com/nats-io/nats.go from 1.43.0 to 1.47.0 (#15)
- Bump github.com/nats-io/nats-server/v2 from 2.11.6 to 2.12.2
- *(deps)* Bump github.com/nats-io/nats-server/v2 from 2.12.2 to 2.12.3 (#18)

### 🚜 Refactor

- Simplify Playwright architecture and clean up JS files
- Move internal docs to .docs/ directory
- Move Blog & Updates to About Me section
- Move Current Focus to About Me section
- Polish profile content and organization
- Reorganize profile with About Me at top and update CAD kernel deployment info
- Update focus to product development with consulting availability
- Remove redundant Current Focus section from About Me
- Reframe Archethought Inc. as collaboration partnership

### 📚 Documentation

- Add snake chasing its tail architecture explanation
- Add well-known endpoints guide and demo env
- Add introductory context to README explaining repository purpose
- Add credit to charmbracelet for pioneering .github pattern
- Add CGO build support and GUI app capabilities to README
- Explain special .github repository files near top of README
- Add Ubuntu Software company link to organization profile
- Clarify Ubuntu Software builds systems and products for orgs
- Add call-to-action for product info, tools, and blog
- Add Global Collaboration Network section
- Add Current Focus section on Offline AI & Vision Systems
- Add Blog & Updates section with RSS feed
- Add Notable Open Source Projects section to profile
- Add 3D Solids CAD Kernel and Digital Twin capabilities
- Add Partnership Opportunities section to profile
- Add email contact as image to reduce spam
- Add international background and company location
- Clarify contact method usage
- Clarify email is displayed as text to prevent spam
- Usage guide for mise-tasks
- Usage guide for Claude Code skills

### 🎨 Styling

- Improve profile layout with better spacing and organization
- Declutter Blog & Updates section

### 🧪 Testing

- Trigger workflow to verify CI fix
- Verify fixed GitHub Actions workflow

### ⚙️ Miscellaneous Tasks

- Regenerate .github files from templates [skip-regen]
- *(deps)* Bump actions/checkout from 4 to 5
- *(deps)* Bump actions/first-interaction from 1 to 3 (#5)
- *(deps)* Bump actions/setup-go from 4 to 6 (#9)
- Add working files and tooling configurations
- *(deps)* Bump actions/checkout from 5 to 6 (#17)
