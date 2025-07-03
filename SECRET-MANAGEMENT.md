# Secret Management System

This document describes the comprehensive secret management system for the `.github` organization repository.

## Overview

The secret management system provides secure, automated synchronization of secrets between:
- Local `.env` files (development)
- GitHub Secrets (CI/CD)
- Cloud platforms (Synadia NATS, Cloudflare)

## Quick Start

```bash
# 1. Initialize secret management
task secrets:setup

# 2. Copy and fill in your secrets
cp .env.example .env
# Edit .env with your actual values

# 3. Sync secrets to GitHub
task secrets:sync

# 4. Test access
task secrets:test
```

## Secret Types

### Required Secrets

| Secret | Purpose | How to Get |
|--------|---------|------------|
| `GITHUB_TOKEN` | GitHub API access | [Personal Access Tokens](https://github.com/settings/tokens) |
| `GITHUB_ORG` | Organization name | Your GitHub org (e.g., `joeblew999`) |

### Optional Platform Secrets

#### Synadia Cloud NATS
| Secret | Purpose | How to Get |
|--------|---------|------------|
| `SYNADIA_TOKEN` | API access | [Synadia Cloud Console](https://cloud.synadia.com/) |
| `SYNADIA_ACCOUNT` | Account name | Your Synadia account |
| `NATS_CREDS_FILE` | NATS credentials | Download from Synadia Console |

#### Cloudflare
| Secret | Purpose | How to Get |
|--------|---------|------------|
| `CLOUDFLARE_API_TOKEN` | API access | [API Tokens](https://dash.cloudflare.com/profile/api-tokens) |
| `CLOUDFLARE_ACCOUNT_ID` | Account ID | Cloudflare Dashboard sidebar |
| `CLOUDFLARE_ZONE_ID` | DNS Zone ID | Domain overview page |
| `CLOUDFLARE_R2_ACCESS_KEY` | R2 Storage access | R2 console |
| `CLOUDFLARE_R2_SECRET_KEY` | R2 Storage secret | R2 console |

#### Development
| Secret | Purpose | Default |
|--------|---------|---------|
| `NATS_URL` | Local NATS server | `nats://localhost:4222` |
| `DEBUG` | Debug logging | `true` |

## Available Commands

### Setup and Initialization
```bash
task secrets:init      # Create .env.example template
task secrets:setup     # Complete setup flow with guide
```

### Daily Operations
```bash
task secrets:sync      # Sync .env → GitHub Secrets
task secrets:test      # Test access to all platforms
task secrets:list      # List current GitHub secrets
```

### Security and Maintenance
```bash
task secrets:security  # Run security checks
task secrets:generate  # Generate random secrets (webhooks)
task secrets:rotate    # Guided secret rotation
```

### Backup and Recovery
```bash
task secrets:backup    # Create encrypted backup
task secrets:restore   # Restore from backup
```

## Security Features

### File Security
- `.env` automatically added to `.gitignore`
- Checks for secure file permissions (600)
- Scans git history for potential secret leaks

### Secret Validation
- Validates required secrets before sync
- Tests platform connectivity
- Provides clear error messages

### Backup and Recovery
- GPG-encrypted backups
- Timestamped backup files
- Safe restore process

## Platform Integration

### GitHub Secrets
All secrets are automatically synced to GitHub repository secrets, allowing GitHub Actions to access them securely.

```yaml
# In GitHub Actions
- name: Use secrets
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    SYNADIA_TOKEN: ${{ secrets.SYNADIA_TOKEN }}
    CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

### NATS Credentials
NATS credentials files are base64-encoded before storing in GitHub Secrets:

```bash
# Automatic in secret-sync.sh
NATS_CREDS_B64=$(cat "$NATS_CREDS_FILE" | base64 -w 0)
gh secret set NATS_CREDS_FILE --body "$NATS_CREDS_B64"
```

### Terraform Backend
Supports multiple backend types via environment variables:

```bash
# In .env
TF_BACKEND_TYPE=r2  # or 's3', 'local'
TF_STATE_BUCKET=terraform-state-joeblew999
```

## Security Best Practices

### Token Permissions

#### GitHub Token
Required scopes:
- `repo` - Full repository access
- `workflow` - Workflow management
- `admin:org` - Organization administration
- `admin:repo_hook` - Repository webhook management

#### Cloudflare Token
Required permissions:
- `Zone:Read` - DNS zone access
- `Account:Read` - Account information
- Custom permissions for specific resources

### Secret Rotation

1. **Regular Rotation**: Rotate secrets every 90 days
2. **Emergency Rotation**: Immediate rotation if compromise suspected
3. **Staged Rotation**: Test new secrets before revoking old ones

```bash
# Guided rotation process
task secrets:rotate
```

### Access Control

1. **Principle of Least Privilege**: Only grant necessary permissions
2. **Environment Separation**: Different secrets for dev/staging/prod
3. **Audit Trail**: Monitor secret usage and access

## Troubleshooting

### Common Issues

#### `.env file not found`
```bash
# Solution
cp .env.example .env
# Edit .env with your values
```

#### `GitHub authentication failed`
```bash
# Check token validity
gh auth status

# Refresh authentication
gh auth login
```

#### `NATS connection failed`
```bash
# Check local server
nats server check

# Check credentials
nats --creds="$NATS_CREDS_FILE" server check
```

#### `Cloudflare authentication failed`
```bash
# Check token
wrangler whoami

# Login with new token
wrangler login
```

### Debug Mode

Enable detailed logging:
```bash
# In .env
DEBUG=true

# Run commands to see detailed output
task secrets:test
```

## Advanced Usage

### Custom Secret Patterns

The system can be extended to handle custom secrets:

```bash
# In secret-sync.sh, add to sync_to_github()
[ -n "$CUSTOM_SECRET" ] && gh secret set CUSTOM_SECRET --body "$CUSTOM_SECRET"
```

### Multi-Environment Support

Use different `.env` files for different environments:
```bash
# Development
cp .env.example .env.dev

# Production
cp .env.example .env.prod

# Sync specific environment
ENV_FILE=.env.prod ./secret-sync.sh sync
```

### Automated Secret Rotation

Schedule secret rotation in CI/CD:
```yaml
# .github/workflows/secret-rotation.yml
name: Secret Rotation
on:
  schedule:
    - cron: '0 2 1 */3 *'  # Every 3 months

jobs:
  rotate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Rotate secrets
        run: task secrets:rotate
```

## Integration with Other Systems

### NATS Controller
The NATS controller automatically uses secrets for connection:
```go
// Reads from environment variables set by secret sync
natsURL := os.Getenv("NATS_URL")
credsFile := os.Getenv("NATS_CREDS_FILE")
```

### Terraform
Terraform configurations use secrets via environment variables:
```hcl
# terraform/cloudflare.tf
variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}
```

### GitHub Actions
Workflows access secrets automatically:
```yaml
- name: Deploy to Cloudflare
  env:
    CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
  run: wrangler deploy
```

## Monitoring and Observability

### Secret Usage Tracking
Monitor secret usage across platforms:
```bash
# Check GitHub secret access logs
gh api /repos/:owner/:repo/actions/secrets

# Monitor NATS connections
nats sub '$SYS.ACCOUNT.*.CONNECT'

# Cloudflare audit logs
wrangler audit-log
```

### Health Checks
Regular validation of secret functionality:
```bash
# Automated health checks
task secrets:test

# Platform-specific checks
task nats:health
task cloudflare:test
```

## Migration and Backup

### Migrating from Other Systems
```bash
# From AWS Secrets Manager
aws secretsmanager get-secret-value --secret-id prod/github --query SecretString

# From HashiCorp Vault
vault kv get -field=github_token secret/prod

# Convert to .env format and sync
task secrets:sync
```

### Disaster Recovery
```bash
# Create encrypted backup
task secrets:backup

# Store backup in secure location
# Restore when needed
task secrets:restore
```

## Compliance and Auditing

### Audit Trail
- All secret operations are logged
- Git history excludes sensitive data
- Platform audit logs available

### Compliance Features
- Encryption at rest (GPG backups)
- Encryption in transit (HTTPS/TLS)
- Access logging and monitoring
- Regular rotation schedules

## Contributing

When adding new secrets or platforms:

1. Update `.env.example` with new variables
2. Add validation to `secret-sync.sh`
3. Update sync logic for new platform
4. Add tests for connectivity
5. Update this documentation

## Support

For issues with secret management:

1. Check the troubleshooting section
2. Run `task secrets:security` for diagnostics
3. Review logs with `DEBUG=true`
4. Create an issue with sanitized logs (no secrets!)

---

This secret management system provides a secure, automated foundation for managing credentials across your entire development and deployment pipeline.
