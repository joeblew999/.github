# Organization Config Registry

**Concept:** Use this `.github` repo as a central config registry with NATS KV distribution.

## Architecture

```
.github repo changes → GitHub Actions → NATS KV → Other repos
```

## Flow

1. **Central Registry** - `.github` repo stores org-wide configs
2. **Auto-Sync** - GitHub Actions push changes to NATS KV store  
3. **Real-time Distribution** - Other repos pull from NATS KV
4. **Decoupled Access** - No direct GitHub API dependencies

## Benefits

- ✅ **Centralized config management** - One source of truth
- ✅ **Real-time propagation** - Changes sync instantly via NATS
- ✅ **Secure distribution** - NATS handles auth/encryption
- ✅ **Audit trail** - All changes tracked in `.github` repo

## Example Usage

```yaml
# In other repo Taskfiles
get-config:
  cmd: nats kv get org.config.NATS_URL

deploy:
  deps: [get-config]
  cmd: deploy-with-config
```

## Implementation Notes

- Implementation TBD - would likely need new folder structure
- Could use `config/` directory in repo root for org-wide settings
- GitHub Actions would sync `config/` contents to NATS KV
- Other repos would have standardized tasks to pull from NATS KV
- Version control and rollback capabilities via GitHub history

## Potential Config Categories

- **Infrastructure** - NATS URLs, database connections, service endpoints
- **Security** - Certificate authorities, JWT signing keys (references)
- **Feature Flags** - Org-wide feature toggles
- **Deployment** - Environment-specific settings, rollout strategies
- **Monitoring** - Log levels, metrics endpoints, alert thresholds

*Note: This is a future enhancement concept. Current implementation focuses on NATS-Playwright integration.*
