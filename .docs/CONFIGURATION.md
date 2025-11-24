# Configuration Guide: Bootstrap & Dependencies

## 🔍 Key Insights from Analysis

### 1. **Bee vs Toolbelt Integration**

After analyzing the codebases, here's what we found:

**Bee (github.com/blinkinglight/bee):**
- ✅ Pure event sourcing focus on NATS JetStream
- ✅ Minimal, clean protobuf-based approach
- ✅ Simple CQRS patterns
- ❓ Early stage (v0.3 roadmap shows snapshots coming)

**Toolbelt (github.com/delaneyj/toolbelt):**
- ✅ Mature protobuf code generation (`toolbelt/natsrpc`)
- ✅ Embedded NATS server capabilities (`toolbelt/embeddednats`)
- ✅ Rich utility functions and patterns
- ✅ Production-ready components

**Our Recommendation:**
- **Phase 1**: Use our current approach (manual protobuf + NATS client)
- **Phase 2**: Evaluate toolbelt's `natsrpc` for code generation (more mature than bee)
- **Phase 3**: Consider bee for event sourcing patterns when it reaches v1.0

### 2. **Bootstrap Sequencing Solution**

The two-phase problem is solved with our bootstrap script:

```bash
# Phase 1: External Dependencies (Manual/Automated)
./bootstrap.sh --mode dev            # Development with embedded NATS
./bootstrap.sh --mode docker         # Production with Docker
./bootstrap.sh --nats-type synadia_cloud  # Synadia Cloud deployment

# Phase 2: Self-Management (Automated)
# After bootstrap, GitHub manages itself via workflows
```

### 3. **Race Condition Prevention**

**Problem**: Multiple template changes trigger simultaneous regenerations

**Solution**: NATS-based distributed locking
```go
// Prevent concurrent regenerations
lockKey := fmt.Sprintf("github.%s.regeneration_lock", org)
_, err := js.Publish(ctx, lockKey, payload, jetstream.WithMsgID(reason))
if err == jetstream.ErrMsgIdDuplicate {
    return ErrRegenerationInProgress
}
```

## 🚀 Quick Start Guide

### Development Bootstrap
```bash
# 1. Clone and setup
git clone https://github.com/joeblew999/.github
cd .github

# 2. Bootstrap in development mode
task bootstrap-dev

# 3. Test the system
task nats-test-connection
task verify-github
```

### Production Bootstrap (Self-Hosted)
```bash
# 1. Set environment variables
export GITHUB_ORG="your-org"
export GITHUB_TOKEN="your-token"
export TERRAFORM_BACKEND="s3"
export AWS_BUCKET="your-terraform-state-bucket"

# 2. Bootstrap
./bootstrap.sh --mode kubernetes --terraform-backend s3

# 3. Validate
task verify-github
```

### Production Bootstrap (Synadia Cloud)
```bash
# 1. Set Synadia credentials
export SYNADIA_CREDS_FILE="/path/to/synadia.creds"
# OR
export SYNADIA_JWT="your-jwt"
export SYNADIA_NKEY_SEED="your-nkey-seed"

# 2. Bootstrap
task bootstrap-synadia

# 3. Validate
task verify-github
```

## 🔧 Configuration Options

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `GITHUB_ORG` | GitHub organization name | `joeblew999` | ✅ |
| `GITHUB_TOKEN` | GitHub personal access token | - | For webhook auto-registration |
| `NATS_DEPLOYMENT_TYPE` | NATS deployment type | `self_hosted` | ✅ |
| `BOOTSTRAP_MODE` | Bootstrap mode | `auto` | ✅ |
| `TERRAFORM_BACKEND` | Terraform state backend | `local` | ✅ |

### NATS Deployment Types

**`self_hosted`** - Single node self-hosted NATS
- Good for: Development, small organizations
- Requirements: Docker or Kubernetes
- Pros: Full control, no external dependencies
- Cons: You manage infrastructure

**`self_hosted_cluster`** - Multi-node NATS cluster
- Good for: Production, high availability
- Requirements: Kubernetes cluster
- Pros: High availability, scalable
- Cons: More complex setup

**`synadia_cloud`** - Managed Synadia Cloud
- Good for: Production, zero infrastructure management
- Requirements: Synadia Cloud account
- Pros: Fully managed, globally distributed
- Cons: External dependency, cost

**`hybrid`** - Mix of cloud and self-hosted
- Good for: Edge computing, global + local processing
- Requirements: Both Synadia and self-hosted setup
- Pros: Best of both worlds
- Cons: Most complex configuration

### Bootstrap Modes

**`dev`** - Development mode
- Uses embedded NATS server
- No Kubernetes required
- Perfect for local development and testing

**`docker`** - Docker-based deployment
- Runs NATS and controller in Docker containers
- Good for simple production deployments

**`kubernetes`** - Kubernetes deployment
- Full production deployment with StatefulSets
- Auto-scaling and monitoring included

**`auto`** - Automatic mode detection
- Chooses best mode based on environment
- Falls back to dev mode if Docker/K8s unavailable

## 🔄 Workflow Integration

### Current State: Manual Setup Required
1. ✅ Templates and files generated
2. ✅ NATS infrastructure deployed
3. ✅ Controllers running
4. ❌ GitHub webhooks (manual setup)
5. ❌ Auto-scaling policies (manual setup)

### Future State: Fully Automated
1. ✅ Everything from current state
2. ✅ GitHub webhooks auto-registered
3. ✅ Auto-scaling based on event volume
4. ✅ Cross-org coordination
5. ✅ Advanced observability

## 🐛 Troubleshooting

### Common Issues

**Bootstrap fails with "NATS connection refused"**
```bash
# Check if NATS is running
docker ps | grep nats
# OR
kubectl get pods -n nats-system

# Test connectivity
task nats-test-connection
```

**GitHub workflows not triggering**
```bash
# Check webhook registration
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$GITHUB_ORG/.github/hooks

# Manually trigger workflow
gh workflow run regenerate-github-files.yml
```

**Terraform state conflicts**
```bash
# Force unlock if state is locked
terraform force-unlock LOCK_ID

# Import existing resources
terraform import nats_account.github_org existing-account-id
```

### Debug Mode

Enable debug logging:
```bash
export NATS_DEBUG=true
export TERRAFORM_LOG=DEBUG
export DEBUG=true

./bootstrap.sh --mode dev
```

## 📈 Scaling Considerations

### Small Organization (< 10 repos)
- Use `bootstrap-dev` for simplicity
- Single NATS node sufficient
- Manual webhook setup acceptable

### Medium Organization (10-100 repos)
- Use `self_hosted_cluster` or `synadia_cloud`
- Enable auto-scaling
- Implement proper monitoring

### Large Organization (100+ repos)
- Use `hybrid` deployment
- Multi-region NATS clusters
- Advanced observability and alerting
- Custom scaling policies

## 🔮 Future Roadmap

### Phase 1: Bootstrap Stabilization ✅
- ✅ Bootstrap script
- ✅ Race condition prevention
- ✅ Cross-platform support

### Phase 2: Enhanced Integration (Next)
- 🔄 Automatic webhook registration
- 🔄 Toolbelt/natsrpc evaluation
- 🔄 Advanced monitoring

### Phase 3: Enterprise Features (Future)
- ⏳ Multi-org coordination
- ⏳ Compliance automation
- ⏳ Advanced security policies

This configuration provides a solid foundation that solves the bootstrap sequencing problem while keeping the door open for future enhancements!
