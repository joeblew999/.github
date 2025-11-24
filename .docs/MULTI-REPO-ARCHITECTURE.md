# Multi-Repo Infrastructure Platform Design

## Overview

The `.github` repository is evolving from a simple organization config into a **foundational infrastructure platform** that other repositories can leverage through Taskfile includes and shared components.

## Architecture Vision

```
┌─────────────────────────────────────────────────────────────────┐
│                    joeblew999/.github                          │
│                  (Infrastructure Platform)                      │
├─────────────────────────────────────────────────────────────────┤
│ 🏗️  Core Infrastructure                                         │
│   • Taskfile.yml (shared tasks)                                │
│   • secret-sync.sh (multi-platform secret mgmt)               │
│   • NATS controllers & monitoring                              │
│   • Terraform modules                                          │
│   • GitHub Actions workflows                                   │
│   • Bee/Protobuf schemas                                       │
│                                                                 │
│ 🔐 Secret Management Layer                                      │
│   • Cross-platform .env → GitHub → Cloud sync                 │
│   • Encrypted backups & rotation                               │
│   • Platform integrations (Synadia, Cloudflare)               │
│                                                                 │
│ 🌐 Cloud Platform Integrations                                 │
│   • Cloudflare R2 (Terraform backend)                         │
│   • Cloudflare Containers (NATS deployment)                   │
│   • Synadia Cloud (managed NATS)                              │
│   • GitHub Actions (CI/CD orchestration)                      │
└─────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │         Shared via:          │
                    │   • Taskfile includes        │
                    │   • GitHub Actions reuse     │
                    │   • Go modules               │
                    │   • Terraform modules        │
                    │   • NATS event schemas       │
                    └───────────────┬───────────────┘
                                    │
    ┌───────────────────────────────┼───────────────────────────────┐
    │                               │                               │
    ▼                               ▼                               ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Product Repo A │    │  Product Repo B │    │  Product Repo C │
│  (Web App)      │    │  (API Service)  │    │  (CLI Tool)     │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ includes:       │    │ includes:       │    │ includes:       │
│   ../.github/   │    │   ../.github/   │    │   ../.github/   │
│   Taskfile.yml  │    │   Taskfile.yml  │    │   Taskfile.yml  │
│                 │    │                 │    │                 │
│ inherits:       │    │ inherits:       │    │ inherits:       │
│ • secrets:*     │    │ • secrets:*     │    │ • secrets:*     │
│ • nats:*        │    │ • nats:*        │    │ • nats:*        │
│ • cloudflare:*  │    │ • cloudflare:*  │    │ • cloudflare:*  │
│ • install-*     │    │ • install-*     │    │ • install-*     │
│                 │    │                 │    │                 │
│ adds:           │    │ adds:           │    │ adds:           │
│ • build:*       │    │ • api:*         │    │ • release:*     │
│ • deploy:*      │    │ • test:*        │    │ • package:*     │
│ • test:*        │    │ • migrate:*     │    │ • distribute:*  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Taskfile Include Strategy

### Current State (.github/Taskfile.yml)
```yaml
# Foundation tasks that ALL repos need
tasks:
  # Infrastructure
  secrets:*          # Secret management
  nats:*             # NATS operations
  cloudflare:*       # Cloudflare integration
  
  # Development
  install-*          # Cross-platform tool installation
  check:*            # Validation and health checks
  
  # CI/CD Foundation
  verify-github:*    # GitHub state validation
  bootstrap:*        # Infrastructure bootstrap
```

### Product Repo Pattern
```yaml
# product-repo/Taskfile.yml
version: '3'

includes:
  infra:
    taskfile: ../.github/Taskfile.yml
    dir: ../.github

vars:
  PROJECT_NAME: my-webapp
  
tasks:
  # Project-specific tasks
  build:
    desc: Build web application
    cmds:
      - npm run build
  
  deploy:
    desc: Deploy to production
    deps: [infra:secrets:test, infra:cloudflare:setup]
    cmds:
      - wrangler deploy
      
  test:
    desc: Run tests with infrastructure
    deps: [infra:nats:bootstrap]
    cmds:
      - npm test
      
  # Inherit all infrastructure tasks
  setup:
    desc: Setup project with infrastructure
    cmds:
      - task: infra:secrets:setup
      - task: infra:bootstrap
      - npm install
```

## Phase-Based Implementation

### Phase 1: Foundation (Current)
**Status: ✅ Complete**
- ✅ Secret management system
- ✅ Cross-platform Taskfile
- ✅ NATS infrastructure
- ✅ Cloudflare integration
- ✅ GitHub Actions workflows

### Phase 2: Shared Infrastructure
**Status: 🚧 In Progress**
- [ ] Extract reusable Taskfile components
- [ ] Create shared Terraform modules
- [ ] Standardize secret management interface
- [ ] Document include patterns

### Phase 3: Multi-Repo Integration
**Status: 📋 Planned**
- [ ] First product repo using includes
- [ ] NATS event routing between repos
- [ ] Shared monitoring & observability
- [ ] Cross-repo secret synchronization

### Phase 4: Organization Platform
**Status: 🔮 Future**
- [ ] Self-service repo onboarding
- [ ] Automated compliance checking
- [ ] Organization-wide cost optimization
- [ ] Multi-cloud orchestration

## Design Considerations

### 1. Careful Phase Management
```yaml
# Versioned includes to prevent breaking changes
includes:
  infra:
    taskfile: ../.github/v1.2.3/Taskfile.yml  # Pinned version
    # OR
    taskfile: ../.github/Taskfile.yml          # Latest (risky)
```

### 2. Namespace Isolation
```yaml
# Clear task namespacing
tasks:
  # Infrastructure tasks (from .github)
  infra:secrets:sync:     # Clear namespace
  infra:nats:deploy:
  infra:cloudflare:setup:
  
  # Project-specific tasks
  build:                  # No namespace needed
  test:
  deploy:
```

### 3. Dependency Management
```yaml
# Clear dependency chains
deploy:
  deps: 
    - infra:secrets:test      # Ensure secrets work
    - infra:nats:health       # Ensure NATS is ready
    - build                   # Ensure app is built
  cmds:
    - wrangler deploy
```

### 4. Configuration Inheritance
```yaml
# Shared configuration with project overrides
vars:
  # From .github (inherited)
  GITHUB_ORG: joeblew999
  NATS_URL: "{{.NATS_URL}}"
  
  # Project-specific (override)
  PROJECT_NAME: my-webapp
  BUILD_ENV: production
```

## Benefits of This Architecture

### For Product Repos
- **Reduced Boilerplate**: No need to reimplement secret management, NATS setup, etc.
- **Consistent Operations**: Same commands work across all repos
- **Automatic Updates**: Infrastructure improvements flow to all repos
- **Cross-Platform**: Inherits all platform compatibility
- **Secure by Default**: Secret management and security patterns built-in

### For Organization
- **Centralized Control**: Infrastructure changes in one place
- **Cost Optimization**: Shared Cloudflare/NATS resources
- **Compliance**: Consistent security and operational practices
- **Observability**: Organization-wide monitoring via NATS
- **Scaling**: Easy to onboard new repos and teams

## Implementation Strategy

### Step 1: Extract Shared Components
```bash
# Create versioned includes
mkdir -p .github/includes/v1
cp Taskfile.yml .github/includes/v1/infrastructure.yml

# Refactor current Taskfile.yml
cat > Taskfile.yml << 'EOF'
version: '3'

includes:
  base: ./includes/v1/infrastructure.yml

# Organization-specific tasks only
tasks:
  setup:
    desc: Setup .github organization files
    cmds:
      - task: base:secrets:init
      - go run cmd/github-setup/main.go
EOF
```

### Step 2: Create First Product Repo
```bash
# In a new product repo
mkdir my-webapp
cd my-webapp

cat > Taskfile.yml << 'EOF'
version: '3'

includes:
  org:
    taskfile: ../.github/includes/v1/infrastructure.yml
    dir: ../.github

tasks:
  setup:
    deps: [org:secrets:setup, org:bootstrap]
    cmds:
      - npm install
      
  build:
    deps: [org:secrets:test]
    cmds:
      - npm run build
      
  deploy:
    deps: [build, org:cloudflare:test]
    cmds:
      - wrangler deploy
EOF
```

### Step 3: Test Integration
```bash
# In product repo
task setup       # Should inherit infrastructure setup
task deploy      # Should use shared secrets/cloudflare
```

## Security Considerations

### Secret Isolation
- Each repo has its own `.env` with project-specific secrets
- Shared secrets (GitHub tokens, etc.) come from .github repo
- Clear separation between infrastructure and application secrets

### Access Control
- Infrastructure repo controls who can modify shared components
- Product repos can only override project-specific configuration
- NATS provides secure event routing between repos

### Audit Trail
- All infrastructure changes go through .github repo
- Product repos inherit security practices automatically
- Centralized logging and monitoring via NATS

## Future Possibilities

### Self-Service Onboarding
```bash
# Future: Automated repo creation
task org:create-repo --name my-new-service --type api
# Would create repo with proper Taskfile includes, secrets, etc.
```

### Cross-Repo Orchestration
```yaml
# Future: Deploy multiple related repos together
deploy:all:
  cmds:
    - task: infra:nats:publish --subject deploy.start --data '{"repos":["api","web","worker"]}'
    # NATS coordinates deployment across repos
```

### Organization Monitoring
```bash
# Future: Organization-wide observability
task org:status    # Health of all repos and infrastructure
task org:costs     # Cost breakdown across all cloud resources
task org:security  # Security posture across all repos
```

## Next Steps

1. **Extract Shared Tasks**: Move infrastructure tasks to includes/
2. **Version Management**: Implement versioned includes strategy
3. **First Product Repo**: Create one product repo using includes
4. **Documentation**: Document patterns and best practices
5. **Automation**: Add tools for easy repo onboarding

This architecture positions the `.github` repo as the **foundational platform** for your entire organization, providing secure, scalable, and maintainable infrastructure that all product repos can leverage.

The key insight: **Infrastructure as Code** → **Infrastructure as Platform** → **Organization as Code**
