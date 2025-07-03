# Wrangler configuration for NATS container deployment
name = "${worker_name}"
main = "src/index.js"
compatibility_date = "2024-01-01"
account_id = "${account_id}"

# Container configuration
[[containers]]
class_name = "NATSContainer"
image = "./containers/nats/Dockerfile"
max_instances = ${nats_config.max_instances}
instance_type = "basic"  # 1 GiB memory, 1/4 vCPU, 4 GB disk

# Environment variables
[env]
NATS_PORT = "${nats_config.nats_port}"
NATS_HTTP_PORT = "${nats_config.nats_http_port}"
NATS_CLUSTER_PORT = "${nats_config.nats_cluster_port}"

# KV namespace binding
[[kv_namespaces]]
binding = "NATS_CLUSTER_KV"
id = "${kv_namespace_id}"

# R2 bucket binding  
[[r2_buckets]]
binding = "NATS_PERSISTENCE"
bucket_name = "${r2_bucket_name}"

# Custom domain routing
[[routes]]
pattern = "nats-api.your-domain.com/*"
zone_id = "${zone_id}"

# Development settings
[dev]
local_protocol = "https"
upstream_protocol = "https"
