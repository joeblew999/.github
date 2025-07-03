# Cloudflare Integration Guide

This document covers the integration of Cloudflare R2 (object storage) and Cloudflare Containers with our NATS infrastructure for advanced, globally distributed, and cost-effective deployment options.

## Table of Contents

1. [Cloudflare R2 as Terraform Backend](#cloudflare-r2-as-terraform-backend)
2. [Cloudflare Containers for NATS](#cloudflare-containers-for-nats)
3. [Cost Analysis](#cost-analysis)
4. [Implementation Guide](#implementation-guide)
5. [Advanced Patterns](#advanced-patterns)

## Cloudflare R2 as Terraform Backend

### Overview

Cloudflare R2 provides S3-compatible object storage with **zero egress fees** and global edge distribution, making it an excellent choice for Terraform state storage.

### Key Benefits

- **Zero Egress Fees**: No charges for data retrieval/access
- **S3 Compatibility**: Drop-in replacement for AWS S3 backend
- **Global Distribution**: Automatic geographic distribution
- **Cost Effective**: $0.015/GB/month (vs AWS S3 $0.023/GB/month)
- **Built-in State Locking**: Native support via S3-compatible API

### Configuration

#### 1. Setup R2 Backend

```hcl
terraform {
  backend "s3" {
    bucket                      = "terraform-state-joeblew999"
    key                         = "nats-infrastructure/terraform.tfstate"
    region                      = "auto"
    endpoint                    = "https://<account-id>.r2.cloudflarestorage.com"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style             = true
    use_lockfile               = true
  }
}
```

#### 2. Environment Variables

```bash
export AWS_ACCESS_KEY_ID=<r2-access-key>
export AWS_SECRET_ACCESS_KEY=<r2-secret-key>
export AWS_ENDPOINT_URL_S3=https://<account-id>.r2.cloudflarestorage.com
```

#### 3. Migration from Local State

```bash
# Initialize with new backend
terraform init -migrate-state

# Verify state migration
terraform state list
```

### R2 Features for Our Use Case

- **Bucket Versioning**: Automatic state file versioning for recovery
- **Encryption**: Server-side encryption (AES-256)
- **Location Hints**: Optimize for primary regions
- **CORS Support**: Enable cross-origin access for web interfaces
- **Public Buckets**: Optional for read-only access patterns

## Cloudflare Containers for NATS

### Overview

Cloudflare Containers enable deploying containerized NATS servers on a global edge network with automatic scaling, built-in observability, and tight integration with the Workers platform.

### Key Benefits

- **Global Edge Deployment**: Containers run close to users worldwide
- **Zero Cold Start**: Pre-provisioned containers with sub-second startup
- **Pay-per-Use**: Only pay when containers are actively processing
- **Auto-scaling**: Automatic instance management based on demand
- **Integrated Platform**: Native Workers, KV, R2, and Durable Objects integration

### Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Worker API    │    │  NATS Container │    │   R2 Storage    │
│  (Orchestrator) │◄──►│   (Instance)    │◄──►│  (Persistence)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   KV Storage    │    │   Monitoring    │    │   Custom DNS    │
│ (Coordination)  │    │   (Built-in)    │    │   (Routing)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Container Specifications

#### Instance Types
- **dev**: 256 MiB memory, 1/16 vCPU, 2 GB disk
- **basic**: 1 GiB memory, 1/4 vCPU, 4 GB disk
- **standard**: 4 GiB memory, 1/2 vCPU, 4 GB disk

#### Limits (Beta)
- **Memory**: 40 GiB total per account
- **CPU**: 40 vCPU total per account
- **Concurrent Instances**: Based on memory/CPU allocation

### Deployment Workflow

#### 1. Worker-Based Orchestration

```javascript
export class NATSContainer extends Container {
  defaultPort = 4222;
  sleepAfter = '5m';
  maxInstances = 5;
}

export default {
  async fetch(request, env) {
    const sessionId = extractSessionId(request);
    const container = getContainer(env.NATS_CONTAINER, sessionId);
    return await container.fetch(request);
  }
};
```

#### 2. Container Configuration

```dockerfile
FROM nats:2.10-alpine
COPY nats-server.conf /etc/nats/
EXPOSE 4222 8222 6222
CMD ["nats-server", "--config", "/etc/nats/nats-server.conf"]
```

#### 3. Wrangler Deployment

```bash
# Deploy container-enabled worker
wrangler deploy

# Monitor deployment
wrangler tail
```

## Cost Analysis

### R2 vs AWS S3 (Monthly)

| Service | Storage (10GB) | Operations (1M reads) | Egress (100GB) | Total |
|---------|---------------|----------------------|----------------|-------|
| **Cloudflare R2** | $0.15 | $0.36 | **$0.00** | **$0.51** |
| **AWS S3** | $0.23 | $0.40 | $9.00 | **$9.63** |
| **Savings** | 35% | 10% | 100% | **95%** |

### Containers vs Traditional VPS

#### Small NATS Deployment (basic instance, 50% utilization)
| Service | Monthly Cost | Features |
|---------|-------------|----------|
| **Cloudflare Containers** | ~$5-10 | Global edge, auto-scale, zero-ops |
| **AWS ECS Fargate** | ~$15-25 | Regional, manual scaling |
| **DigitalOcean Droplet** | ~$12 | Single region, manual management |

#### Benefits Beyond Cost
- **Operational Overhead**: Near-zero with Cloudflare
- **Global Reach**: Automatic edge deployment
- **Scaling**: Seamless based on demand
- **Integration**: Native Workers ecosystem

## Implementation Guide

### Phase 1: R2 Backend Migration

1. **Create R2 Bucket**
   ```bash
   # Using Terraform
   cd terraform/
   terraform apply -target=aws_s3_bucket.terraform_state
   ```

2. **Configure Backend**
   ```bash
   # Update terraform configuration
   # Uncomment backend "s3" block in cloudflare-r2-backend.tf
   ```

3. **Migrate State**
   ```bash
   terraform init -migrate-state
   ```

### Phase 2: Container Deployment

1. **Setup Cloudflare Account**
   ```bash
   # Install wrangler
   npm install -g wrangler

   # Login to Cloudflare
   wrangler login
   ```

2. **Deploy Worker**
   ```bash
   # Copy wrangler configuration
   cp terraform/templates/wrangler.toml.tpl wrangler.toml
   
   # Update configuration with your values
   # Deploy
   wrangler deploy
   ```

3. **Test Deployment**
   ```bash
   # Health check
   curl https://nats-orchestrator.<your-subdomain>.workers.dev/health
   
   # Create container instance
   curl -X POST https://nats-orchestrator.<your-subdomain>.workers.dev/api/containers \
     -H "Content-Type: application/json" \
     -d '{"sessionId":"test-instance"}'
   ```

### Phase 3: Integration

1. **Update NATS Controller**
   ```go
   // Add Cloudflare endpoint support
   config.CloudflareEndpoint = "https://nats-orchestrator.<subdomain>.workers.dev"
   ```

2. **Configure GitHub Actions**
   ```yaml
   # Add Cloudflare deployment steps
   - name: Deploy to Cloudflare
     run: wrangler deploy
     env:
       CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
   ```

## Advanced Patterns

### Multi-Region NATS Clusters

```javascript
// Worker handles global routing
export default {
  async fetch(request, env) {
    const region = getOptimalRegion(request);
    const container = getContainer(env.NATS_CONTAINER, `nats-${region}`);
    return await container.fetch(request);
  }
};
```

### Event-Driven Scaling

```javascript
// Auto-scale based on connection count
async function checkAndScale(env) {
  const stats = await getNATSStats();
  if (stats.connections > threshold) {
    await createAdditionalContainer(env);
  }
}
```

### Cross-Platform Integration

```yaml
# GitHub Actions - hybrid deployment
- name: Deploy to Synadia Cloud
  if: env.DEPLOYMENT_TARGET == 'synadia'
  run: task deploy:synadia

- name: Deploy to Cloudflare
  if: env.DEPLOYMENT_TARGET == 'cloudflare'
  run: wrangler deploy
```

### State Synchronization

```go
// Go controller with multi-backend support
type StateBackend interface {
    Store(key string, value []byte) error
    Load(key string) ([]byte, error)
}

type CloudflareR2Backend struct {
    bucket string
    client *s3.Client
}

type SynadiaBackend struct {
    endpoint string
    auth     *AuthConfig
}
```

## Security Considerations

### R2 Security
- **Access Keys**: Use least-privilege R2 tokens
- **Bucket Policies**: Restrict access to state files
- **Encryption**: Enable server-side encryption
- **Versioning**: Enable for state recovery

### Container Security
- **Worker Secrets**: Use environment variables for sensitive data
- **NATS Auth**: Implement proper authentication and authorization
- **Network Policies**: Use Cloudflare Access for admin endpoints
- **Audit Logging**: Enable comprehensive request logging

### Best Practices
- **Separation of Concerns**: Different tokens for different environments
- **Rotation**: Regular key rotation policies
- **Monitoring**: Real-time security event monitoring
- **Backup**: Regular state and configuration backups

## Monitoring and Observability

### Built-in Cloudflare Metrics
- Container resource usage (CPU, memory, disk)
- Request latency and error rates
- Geographic distribution of requests
- Worker execution metrics

### Custom NATS Metrics
- Connection counts and rates
- Message throughput
- JetStream storage usage
- Cluster health status

### Integration with External Systems
```javascript
// Export metrics to external monitoring
async function exportMetrics(metrics) {
  await fetch('https://your-monitoring-system.com/metrics', {
    method: 'POST',
    body: JSON.stringify(metrics)
  });
}
```

## Migration Strategy

### Gradual Migration Path

1. **Phase 1**: R2 backend only (low risk)
2. **Phase 2**: Hybrid deployment (containers + existing)
3. **Phase 3**: Full container deployment
4. **Phase 4**: Advanced features (auto-scaling, multi-region)

### Rollback Plan
- Keep existing infrastructure during transition
- Use feature flags for gradual rollout
- Maintain parallel state storage during migration
- Automated rollback triggers on error thresholds

## Conclusion

Cloudflare's R2 and Containers platform offer compelling advantages for our NATS infrastructure:

- **Cost Optimization**: 95% reduction in storage costs
- **Global Scale**: Automatic edge deployment
- **Operational Simplicity**: Near-zero maintenance overhead
- **Platform Integration**: Seamless Workers ecosystem
- **Future-Ready**: Advanced scaling and orchestration capabilities

The implementation can be done incrementally, starting with R2 backend migration (low risk, immediate cost savings) and progressing to container deployment (advanced capabilities, global scale).

This integration positions our `.github` organization repository as a truly modern, cloud-native, and globally scalable platform for event-driven development workflows.
