# CLAUDE.md - AI Assistant Guide for joeblew999/.github

This document provides essential context for AI assistants working with this repository.

## Repository Overview

This is a **meta-repository** that manages GitHub configuration and workflows across the entire `joeblew999` organization. It serves as the "command center" for organization-wide automation, template distribution, and optional NATS-based event orchestration.

**Key Problems Solved:**
- Consistent CI/CD workflows across hundreds of repositories
- Single source of truth for GitHub configurations
- Automated template propagation to all repos
- Secret management across the organization
- Optional advanced event-driven orchestration

## Quick Reference

### Essential Commands (via Taskfile)

```bash
# Core Operations
task setup              # Generate .github files from templates
task clean              # Remove generated files
task check              # Verify generated files match templates
task status             # Show system health

# Secret Management
task secrets:setup      # Initialize secret management
task secrets:sync       # Sync secrets to GitHub
task secrets:test       # Test secret connectivity

# NATS (Optional Advanced)
task nats-controller    # Run local NATS controller
task nats-deploy        # Deploy NATS infrastructure

# Cloudflare (Optional)
task cloudflare:setup   # Setup R2 + Containers
task cloudflare:deploy  # Deploy to Cloudflare
```

### Key Environment Variables

```bash
GITHUB_ORG=joeblew999              # GitHub organization
GITHUB_TOKEN=xxx                   # GitHub personal access token
NATS_URLS=nats://localhost:4222   # NATS server URLs
NATS_DEPLOYMENT_TYPE=self_hosted  # synadia_cloud|self_hosted|hybrid
CLOUDFLARE_ACCOUNT_ID=xxx         # For Cloudflare integration
```

## Directory Structure

```
/home/user/.github/
├── .claude/                    # Claude agent configurations
│   └── agents/                 # Specialized agent prompts
├── .docs/                      # Internal documentation (hidden)
│   ├── BOOTSTRAP-ANALYSIS.md
│   ├── MULTI-REPO-ARCHITECTURE.md
│   └── TODO.md
├── .github/                    # Generated GitHub configuration
│   ├── workflows/              # GitHub Actions workflows
│   └── issue-templates/        # Issue templates
├── cmd/                        # Go CLI tools
│   ├── github-setup/           # Template processor
│   ├── nats-bootstrap/         # Embedded NATS server
│   └── nats-controller/        # NATS workflow controller
├── logging/                    # NATS logging tools (Playwright-based)
├── profile/                    # Organization profile (README.md)
├── schemas/                    # Protobuf event schemas
├── templates/                  # Source templates (edit these!)
├── terraform/                  # Infrastructure as code
│   ├── nats-github-infrastructure.tf
│   ├── cloudflare-*.tf
│   └── workers/
├── well-known-registry/        # Well-known endpoints tooling
├── Taskfile.yml                # Main task runner (source of truth)
├── bee.yaml                    # Bee event orchestration config
├── bootstrap.sh                # NATS environment setup
├── secret-sync.sh              # Secret synchronization
└── README.md                   # Main documentation
```

## Core Concepts

### 1. Template System

Templates in `templates/` directory generate `.github/` files:

```bash
# Edit templates, never generated files directly
templates/
├── CODEOWNERS
├── dependabot.yml
├── issue-templates/
├── pull_request_template.md
└── workflows/

# Run to regenerate
task setup
```

The Go-based processor (`cmd/github-setup/main.go`) provides cross-platform template rendering with Go text/template syntax.

### 2. The "Snake Eating Its Tail" Problem

This repository modifies itself:
1. Template changes trigger GitHub Action
2. Action runs `task setup` to regenerate files
3. Action commits changes... which could trigger another Action!

**Solution:** Commits include `[skip-regen]` tag:
```yaml
# .github/workflows/regenerate-github-files.yml
if: "!contains(github.event.head_commit.message, '[skip-regen]')"
```

### 3. Idempotent Operations

All operations are safe to run multiple times:
- `task clean` removes all generated files completely
- `task setup` rebuilds from templates
- `task check` validates without making changes

### 4. Cross-Platform Compatibility

The codebase works on Windows, macOS, and Linux:
- Uses Go CLI tools instead of jq/awk/sed
- Taskfile handles platform detection
- All scripts use portable constructs

## Technology Stack

### Core
| Technology | Purpose |
|------------|---------|
| **Go 1.24** | Template processor, CLI tools, NATS controller |
| **Taskfile** | Task automation (replaces Make) |
| **GitHub Actions** | CI/CD automation |
| **Git** | Version control |

### Optional Advanced Features
| Technology | Purpose |
|------------|---------|
| **NATS/JetStream** | Event-driven orchestration |
| **Terraform** | Infrastructure as code |
| **Synadia Cloud** | Managed NATS platform |
| **Cloudflare R2** | Terraform state storage |
| **Cloudflare Containers** | NATS deployment |
| **Bee** | Event schema evolution |

## Development Workflows

### Editing Templates

1. Edit files in `templates/` directory (not `.github/`)
2. Run `task setup` to regenerate
3. Run `task check` to verify
4. Commit changes (CI will auto-regenerate with `[skip-regen]`)

### Adding New Workflows

1. Create template in `templates/workflows/`
2. Use Go template syntax for organization-specific values:
   ```yaml
   # Example: templates/workflows/ci.yml
   name: CI for {{.GitHubOrg}}
   ```
3. Run `task setup` and verify

### Secret Management

```bash
# Initial setup
task secrets:setup

# Edit secrets
cp .env.example .env
# Edit .env with actual values

# Sync to GitHub
task secrets:sync

# Test
task secrets:test
```

**Never commit:**
- `.env` files
- Credentials files (`.creds`, `.nkey`)
- Backup files (`secrets-backup-*.tar.gz.gpg`)

## Key Files Reference

### Entry Points
| File | Purpose |
|------|---------|
| `Taskfile.yml` | All automation commands |
| `cmd/github-setup/main.go` | Template processor |
| `bootstrap.sh` | NATS environment setup |

### Configuration
| File | Purpose |
|------|---------|
| `.env.example` | Template for secrets |
| `bee.yaml` | Event orchestration config |
| `go.mod` | Go module dependencies |

### Documentation
| File | Audience |
|------|----------|
| `README.md` | Users (public) |
| `CONTRIBUTING.md` | Contributors |
| `SECRET-MANAGEMENT.md` | DevOps |
| `CLOUDFLARE-INTEGRATION.md` | Infrastructure |
| `.docs/*` | Internal development |

## Important Patterns

### Go Template Syntax

Templates use Go's text/template:
```go
{{.GitHubOrg}}              // Variable substitution
{{if eq .OS "windows"}}...{{end}}  // Conditionals
```

### Taskfile Variables

```yaml
vars:
  GITHUB_ORG: joeblew999
  OS: "{{OS}}"              # Auto-detected
  ARCH: "{{ARCH}}"          # Auto-detected
  EXE_EXT: '{{if eq OS "windows"}}.exe{{end}}'
```

### NATS Subject Hierarchy

```
github.{org}.template_changed      # Template modifications
github.{org}.workflow_status       # GitHub Actions status
github.{org}.regeneration_requested # Regen requests
nats.{org}.infrastructure_scaling  # Auto-scaling events
```

## Common Tasks for AI Assistants

### When Asked to Modify Templates
1. Always edit `templates/` not `.github/`
2. Test with `task setup` && `task check`
3. Explain the regeneration workflow

### When Asked About Workflows
1. Check `templates/workflows/` for source
2. Check `.github/workflows/` for generated output
3. Note the `[skip-regen]` pattern

### When Asked About NATS
1. This is **optional** advanced functionality
2. Basic usage doesn't require NATS
3. Point to README.md "NATS Integration" section

### When Asked About Secrets
1. Never output actual secret values
2. Reference `SECRET-MANAGEMENT.md`
3. Use `task secrets:*` commands

## Gotchas & Warnings

1. **Never edit `.github/` directly** - Changes will be overwritten
2. **Always include `[skip-regen]`** - In commits that modify `.github/`
3. **Use Go CLI tools** - Not jq/awk/sed (cross-platform)
4. **Taskfile is truth** - Don't bypass for ad-hoc scripts
5. **Hidden dirs start with `.`** - `.docs/`, `.claude/`, `.bin/`
6. **Profile is special** - `profile/README.md` is the org profile

## Testing

```bash
# Local validation
task check              # Verify generated files
task validate-all       # Full validation suite

# GitHub verification
task verify-github      # Check GitHub state matches local

# NATS testing (if using)
task nats-test-connection
```

## Git Conventions

### Branch Naming
- Feature branches: `feature/*` or `claude/*`
- Always push to feature branch, not main

### Commit Messages
- Regular commits: Standard format
- Regeneration commits: Include `[skip-regen]`
- Example: `chore: regenerate .github files from templates [skip-regen]`

## Related Resources

- [Taskfile Documentation](https://taskfile.dev)
- [GitHub Community Health Files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file)
- [NATS Documentation](https://docs.nats.io)
- [Go Template Documentation](https://pkg.go.dev/text/template)
- [Charmbracelet/.github](https://github.com/charmbracelet/.github) - Inspiration for this pattern

## Support

- Issues: https://github.com/joeblew999/.github/issues
- Organization: https://github.com/joeblew999
