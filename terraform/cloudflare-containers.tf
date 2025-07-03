# Cloudflare Containers Configuration for NATS Deployment
# This configuration demonstrates deploying NATS on Cloudflare's container platform

# Variables for Cloudflare Containers
variable "cloudflare_api_token" {
  description = "Cloudflare API token with Workers:Edit permissions"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for custom domains"
  type        = string
  default     = ""
}

# Local configuration for NATS containers
locals {
  nats_container_config = {
    # Container instance configuration
    memory = "1 GiB"    # basic instance type
    cpu    = "1/4 vCPU" # basic instance type  
    disk   = "4 GB"     # basic instance type
    
    # NATS server configuration
    nats_port        = 4222
    nats_http_port   = 8222
    nats_cluster_port = 6222
    
    # Container settings
    max_instances = 5
    sleep_timeout = "5m"
    
    # Environment configuration
    environments = ["development", "staging", "production"]
  }
}

# Terraform configuration for Cloudflare provider
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Cloudflare provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Example Worker script for NATS container orchestration
resource "cloudflare_worker_script" "nats_orchestrator" {
  count = var.cloudflare_api_token != "" ? 1 : 0
  
  account_id = var.cloudflare_account_id
  name       = "nats-orchestrator"
  content    = templatefile("${path.module}/workers/nats-orchestrator.js", {
    nats_port        = local.nats_container_config.nats_port
    nats_http_port   = local.nats_container_config.nats_http_port
    max_instances    = local.nats_container_config.max_instances
    sleep_timeout    = local.nats_container_config.sleep_timeout
  })
  
  compatibility_date = "2024-01-01"
  
  # Container binding configuration
  plain_text_binding {
    name = "NATS_CONFIG"
    text = jsonencode({
      port         = local.nats_container_config.nats_port
      http_port    = local.nats_container_config.nats_http_port
      cluster_port = local.nats_container_config.nats_cluster_port
      debug        = true
      trace        = false
    })
  }
  
  # Secret bindings for NATS authentication
  secret_text_binding {
    name = "NATS_AUTH_TOKEN"
    text = "your-nats-auth-token-here"
  }
}

# Custom route for NATS API access
resource "cloudflare_worker_route" "nats_api" {
  count = var.cloudflare_api_token != "" && var.cloudflare_zone_id != "" ? 1 : 0
  
  zone_id     = var.cloudflare_zone_id
  pattern     = "nats-api.your-domain.com/*"
  script_name = cloudflare_worker_script.nats_orchestrator[0].name
}

# KV namespace for NATS cluster coordination
resource "cloudflare_workers_kv_namespace" "nats_cluster" {
  count = var.cloudflare_api_token != "" ? 1 : 0
  
  account_id = var.cloudflare_account_id
  title      = "nats-cluster-coordination"
}

# R2 bucket for NATS message persistence (if needed)
resource "cloudflare_r2_bucket" "nats_persistence" {
  count = var.cloudflare_api_token != "" ? 1 : 0
  
  account_id = var.cloudflare_account_id
  name       = "nats-message-persistence"
  location   = "apac"  # or "enam", "weur" based on primary region
}

# Output configuration for container deployment
output "cloudflare_containers_config" {
  description = "Cloudflare Containers configuration for NATS"
  value = {
    worker_name     = var.cloudflare_api_token != "" ? cloudflare_worker_script.nats_orchestrator[0].name : "nats-orchestrator"
    container_specs = local.nats_container_config
    deployment_info = {
      pricing = {
        memory_per_gib_second = "$0.0000025"
        cpu_per_vcpu_second   = "$0.000020"
        disk_per_gb_second    = "$0.00000007"
        egress_na_eu_per_gb   = "$0.025"
      }
      features = [
        "Global edge deployment",
        "Auto-scaling containers",
        "Pay-per-use pricing",
        "Built-in observability",
        "Zero cold start (pre-provisioned)",
        "Integrated with Workers platform"
      ]
      limits = {
        max_memory_per_account = "40 GiB"
        max_cpu_per_account    = "40 vCPU"
        concurrent_instances   = "Based on memory/CPU limits"
      }
    }
  }
  sensitive = false
}

# Example wrangler.toml configuration (as template file)
resource "local_file" "wrangler_config" {
  count = var.cloudflare_api_token != "" ? 1 : 0
  
  filename = "${path.module}/wrangler.toml.example"
  content = templatefile("${path.module}/templates/wrangler.toml.tpl", {
    worker_name     = "nats-orchestrator"
    account_id      = var.cloudflare_account_id
    zone_id         = var.cloudflare_zone_id
    kv_namespace_id = var.cloudflare_api_token != "" ? cloudflare_workers_kv_namespace.nats_cluster[0].id : ""
    r2_bucket_name  = var.cloudflare_api_token != "" ? cloudflare_r2_bucket.nats_persistence[0].name : ""
    nats_config     = local.nats_container_config
  })
}

# Docker configuration template for NATS container
resource "local_file" "nats_dockerfile" {
  filename = "${path.module}/containers/nats/Dockerfile.example"
  content  = file("${path.module}/templates/nats-dockerfile.tpl")
}

# Container configuration for different environments
resource "local_file" "container_configs" {
  count = length(local.nats_container_config.environments)
  
  filename = "${path.module}/containers/nats/${local.nats_container_config.environments[count.index]}.json"
  content = jsonencode({
    environment = local.nats_container_config.environments[count.index]
    nats_config = {
      port         = local.nats_container_config.nats_port
      http_port    = local.nats_container_config.nats_http_port
      cluster_port = local.nats_container_config.nats_cluster_port
      debug        = local.nats_container_config.environments[count.index] != "production"
      trace        = local.nats_container_config.environments[count.index] == "development"
      log_level    = local.nats_container_config.environments[count.index] == "production" ? "info" : "debug"
    }
    container = {
      memory        = local.nats_container_config.memory
      cpu           = local.nats_container_config.cpu
      disk          = local.nats_container_config.disk
      max_instances = local.nats_container_config.environments[count.index] == "production" ? 10 : 3
      sleep_timeout = local.nats_container_config.sleep_timeout
    }
  })
}
