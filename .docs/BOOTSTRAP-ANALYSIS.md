# Bootstrap Sequencing Analysis: The Two-Phase Problem

## 🐔🥚 The Bootstrap Dilemma

Our current architecture has a **circular dependency**:

```
Phase 1: Need NATS → To run GitHub workflows → To deploy NATS infrastructure
Phase 2: Need GitHub workflows → To manage NATS → To handle GitHub events
```

## Critical Sequencing Issues

### 1. **Terraform in GitHub Actions vs. Manual Deployment**

**Current Problem:**
- Terraform runs in GitHub Actions (ephemeral)
- NATS infrastructure needs persistent state
- GitHub Actions need NATS to coordinate
- But NATS isn't deployed yet!

**Solutions:**
```bash
# Option A: Bootstrap Phase (Manual)
terraform apply -target=nats_bootstrap
# Creates minimal NATS infrastructure

# Option B: External State Management
terraform init -backend-config="bucket=github-bootstrap-state"
# Uses external state storage

# Option C: Hybrid Approach
task nats-bootstrap  # Local deployment
task verify-nats     # Health check
task github-deploy   # Now GitHub can manage itself
```

### 2. **Race Conditions in Idempotent Operations**

**The Problem:**
```
Event 1: template_changed → triggers regeneration
Event 2: template_changed → triggers regeneration (while #1 running)
Event 3: regeneration_completed → triggers template_changed detection
```

**Idempotent Race Prevention:**
```go
// NATS-based locking
type RegenerationLock struct {
    nc *nats.Conn
    js jetstream.JetStream
    lockSubject string
    lockTimeout time.Duration
}

func (l *RegenerationLock) AcquireLock(ctx context.Context, org, reason string) error {
    lockKey := fmt.Sprintf("github.%s.regeneration_lock", org)
    
    // Try to create lock stream entry
    _, err := l.js.Publish(ctx, lockKey, []byte(reason), jetstream.WithMsgID(reason))
    if err != nil {
        // Lock already exists
        return ErrLockHeld
    }
    
    // Set expiration
    time.AfterFunc(l.lockTimeout, func() {
        l.ReleaseLock(ctx, org)
    })
    
    return nil
}
```

### 3. **Infrastructure Dependencies**

**Bootstrap Order:**
1. **Manual NATS setup** (or embedded NATS for development)
2. **GitHub webhook registration** (manual or API)
3. **Terraform state initialization** (S3/GCS/etc.)
4. **NATS controller deployment** (manual docker run)
5. **GitHub Actions enablement** (now self-managing)

### 4. **Cross-Platform Bootstrap Scripts**

```bash
# bootstrap.sh (works on all platforms)
#!/bin/bash
set -euo pipefail

echo "🚀 GitHub Organization Bootstrap"

# Phase 1: Check prerequisites
task check-prerequisites

# Phase 2: Initialize external state
task init-terraform-state

# Phase 3: Deploy minimal NATS
task nats-bootstrap-deploy

# Phase 4: Register GitHub webhooks
task github-webhook-setup

# Phase 5: Deploy NATS controller
task nats-controller-deploy

# Phase 6: Enable GitHub self-management
task github-enable-automation

echo "✅ Bootstrap complete! GitHub is now self-managing."
```

## Proposed Solution: Staged Bootstrap

### Stage 1: **External Dependencies** (Manual/Scripted)
- Terraform state backend setup
- Synadia Cloud account (if using)
- GitHub webhook registration
- Basic secrets management

### Stage 2: **Minimal NATS Infrastructure**
```bash
# Deploy minimal NATS (self-hosted or Synadia)
terraform apply -target=nats_bootstrap_cluster
terraform apply -target=nats_jetstream_basic
```

### Stage 3: **Controller Bootstrap**
```bash
# Deploy NATS controller (Docker/Kubernetes)
docker run -d \
  -e NATS_URLS="nats://bootstrap-nats:4222" \
  -e GITHUB_ORG="joeblew999" \
  -e BOOTSTRAP_MODE="true" \
  github-nats-controller:latest
```

### Stage 4: **Self-Management Activation**
```bash
# Now GitHub can manage itself
task github-enable-self-management
# - Creates workflows that manage NATS
# - Sets up auto-scaling
# - Enables snake prevention
```

## Race Condition Prevention

### 1. **Event Deduplication**
```go
// Use NATS message IDs for deduplication
msgID := fmt.Sprintf("%s-%s-%d", org, eventType, time.Now().Unix())
js.Publish(ctx, subject, data, jetstream.WithMsgID(msgID))
```

### 2. **Distributed Locking**
```go
// NATS-based distributed locks
type DistributedLock struct {
    js jetstream.JetStream
    stream string
    key string
    ttl time.Duration
}
```

### 3. **Workflow State Machine**
```protobuf
enum WorkflowState {
  WORKFLOW_STATE_IDLE = 0;
  WORKFLOW_STATE_PENDING = 1;
  WORKFLOW_STATE_RUNNING = 2;
  WORKFLOW_STATE_COMPLETED = 3;
  WORKFLOW_STATE_FAILED = 4;
}

message WorkflowStateEvent {
  string org = 1;
  string workflow_id = 2;
  WorkflowState current_state = 3;
  WorkflowState target_state = 4;
  string reason = 5;
  google.protobuf.Timestamp timestamp = 6;
}
```

## Implementation Strategy

### Phase 1: **Fix Bootstrap Sequence**
1. Create `bootstrap.sh` script
2. Add `task bootstrap` command
3. Document manual steps clearly
4. Add state validation checks

### Phase 2: **Add Race Prevention**
1. Implement NATS distributed locking
2. Add event deduplication
3. Create workflow state machine
4. Add comprehensive monitoring

### Phase 3: **Bee Integration** (Optional)
1. Evaluate bee vs toolbelt/natsrpc overlap
2. Choose best code generation approach
3. Integrate gradually (not breaking current system)

Would you like me to implement the bootstrap script and race prevention patterns first?
