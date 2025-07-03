# NATS Controller Configuration Examples
# 
# This file provides examples of how to configure the NATS controller
# for different deployment scenarios.

# =============================================================================
# Environment Variables for NATS Controller
# =============================================================================

# Basic Configuration
export GITHUB_ORG="joeblew999"
export NATS_DEPLOYMENT_TYPE="self_hosted"  # or synadia_cloud, hybrid

# =============================================================================
# Synadia Cloud Configuration
# =============================================================================

# For Synadia Cloud deployments:
export NATS_DEPLOYMENT_TYPE="synadia_cloud"
export NATS_URLS="connect.ngs.global"
export NATS_CREDS_FILE="/path/to/synadia.creds"
# OR
export NATS_JWT="your-jwt-token"
export NATS_NKEY_SEED="your-nkey-seed"

# Optional Synadia settings
export NATS_JETSTREAM_DOMAIN="your-domain"

# =============================================================================
# Self-Hosted Single Node Configuration
# =============================================================================

# For single node self-hosted NATS:
export NATS_DEPLOYMENT_TYPE="self_hosted_single"
export NATS_URLS="nats://localhost:4222"

# With authentication (recommended for production)
export NATS_CREDS_FILE="/etc/nats/github-automation.creds"
# OR
export NATS_NKEY_FILE="/etc/nats/github-automation.nkey"

# With TLS (recommended for production)
export NATS_TLS_ENABLED="true"
export NATS_TLS_CERT_FILE="/etc/nats/tls/client.pem"
export NATS_TLS_KEY_FILE="/etc/nats/tls/client.key"
export NATS_TLS_CA_FILE="/etc/nats/tls/ca.pem"

# =============================================================================
# Self-Hosted Cluster Configuration
# =============================================================================

# For clustered self-hosted NATS:
export NATS_DEPLOYMENT_TYPE="self_hosted_cluster"
export NATS_URLS="nats://nats-0:4222,nats://nats-1:4222,nats://nats-2:4222"

# Kubernetes service discovery (typical pattern)
export NATS_URLS="nats://github-nats.nats-system.svc.cluster.local:4222"

# With JetStream domain (for super-clusters)
export NATS_JETSTREAM_DOMAIN="github"

# =============================================================================
# Hybrid Configuration (Synadia Cloud + Self-Hosted)
# =============================================================================

# For hybrid deployments (edge + cloud):
export NATS_DEPLOYMENT_TYPE="hybrid"
export NATS_URLS="connect.ngs.global,nats://localhost:4222"
export NATS_CREDS_FILE="/etc/nats/synadia.creds"

# =============================================================================
# Docker Compose Example
# =============================================================================

# docker-compose.yml environment section:
# environment:
#   - GITHUB_ORG=joeblew999
#   - NATS_DEPLOYMENT_TYPE=self_hosted
#   - NATS_URLS=nats://nats:4222
#   - NATS_CREDS_FILE=/etc/nats/github.creds
# volumes:
#   - ./nats-creds:/etc/nats:ro

# =============================================================================
# Kubernetes Deployment Example
# =============================================================================

# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   name: nats-github-controller
# spec:
#   template:
#     spec:
#       containers:
#       - name: controller
#         image: github-nats-controller:latest
#         env:
#         - name: GITHUB_ORG
#           value: "joeblew999"
#         - name: NATS_DEPLOYMENT_TYPE
#           value: "self_hosted_cluster"
#         - name: NATS_URLS
#           value: "nats://github-nats.nats-system.svc.cluster.local:4222"
#         - name: NATS_CREDS_FILE
#           value: "/etc/nats/github.creds"
#         volumeMounts:
#         - name: nats-creds
#           mountPath: /etc/nats
#           readOnly: true
#       volumes:
#       - name: nats-creds
#         secret:
#           secretName: nats-github-creds

# =============================================================================
# Development Configuration
# =============================================================================

# For local development (no auth):
export NATS_DEPLOYMENT_TYPE="self_hosted"
export NATS_URLS="nats://localhost:4222"
export GITHUB_ORG="joeblew999-dev"

# =============================================================================
# Testing Different Scenarios
# =============================================================================

# Test Synadia Cloud connection:
# NATS_DEPLOYMENT_TYPE=synadia_cloud \
# NATS_CREDS_FILE=/path/to/synadia.creds \
# ./nats-controller

# Test self-hosted cluster:
# NATS_DEPLOYMENT_TYPE=self_hosted_cluster \
# NATS_URLS=nats://nats-0:4222,nats://nats-1:4222,nats://nats-2:4222 \
# ./nats-controller

# Test hybrid deployment:
# NATS_DEPLOYMENT_TYPE=hybrid \
# NATS_URLS=connect.ngs.global,nats://localhost:4222 \
# NATS_CREDS_FILE=/path/to/synadia.creds \
# ./nats-controller

# =============================================================================
# Monitoring and Observability
# =============================================================================

# The controller provides monitoring endpoints when running:
# - Health check: Will be available when monitoring server is implemented
# - Metrics: Will provide Prometheus-compatible metrics
# - Status: Will show current connection status and event processing

# =============================================================================
# Security Best Practices
# =============================================================================

# 1. Always use authentication in production
# 2. Enable TLS for all connections
# 3. Use Kubernetes secrets for sensitive data
# 4. Rotate credentials regularly
# 5. Monitor connection health and metrics
# 6. Use network policies to restrict access
# 7. Keep NATS server and client libraries updated

# =============================================================================
# Troubleshooting
# =============================================================================

# Enable debug logging:
export NATS_DEBUG=true

# Check connection status:
# The controller logs will show connection status and any errors

# Test NATS connectivity:
# nats --server=nats://localhost:4222 pub test "hello"
# nats --server=nats://localhost:4222 sub test

# For Synadia Cloud:
# nats --creds=/path/to/synadia.creds pub test "hello"
