# Terraform configuration for NATS-powered GitHub organization management
# Supports both Synadia Cloud and self-hosted NATS deployments
# Called by NATS controllers for self-similar infrastructure deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    nats = {
      source  = "synadia-io/nats"
      version = "~> 0.1"
    }
  }
}

# Configuration variables
variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "joeblew999"
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-west-2"
}

variable "deployment_type" {
  description = "NATS deployment type: synadia_cloud, self_hosted_single, self_hosted_cluster, hybrid"
  type        = string
  default     = "synadia_cloud"
  
  validation {
    condition = contains([
      "synadia_cloud",
      "self_hosted_single", 
      "self_hosted_cluster",
      "hybrid"
    ], var.deployment_type)
    error_message = "Deployment type must be one of: synadia_cloud, self_hosted_single, self_hosted_cluster, hybrid."
  }
}

# Synadia Cloud configuration
variable "synadia_account" {
  description = "Synadia Cloud account ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "synadia_nkey" {
  description = "Synadia Cloud N-Key for authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "synadia_team" {
  description = "Synadia Cloud team name"
  type        = string
  default     = ""
}

# Self-hosted configuration
variable "self_hosted_cluster_name" {
  description = "Name for self-hosted NATS cluster"
  type        = string
  default     = "github-nats"
}

variable "self_hosted_replicas" {
  description = "Number of NATS server replicas for self-hosted cluster"
  type        = number
  default     = 3
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for self-hosted NATS"
  type        = string
  default     = "nats-system"
}

# Resource configuration
variable "resource_requests" {
  description = "Resource requests for NATS pods"
  type = object({
    cpu    = string
    memory = string
  })
  default = {
    cpu    = "100m"
    memory = "128Mi"
  }
}

variable "resource_limits" {
  description = "Resource limits for NATS pods"
  type = object({
    cpu    = string
    memory = string
  })
  default = {
    cpu    = "500m"
    memory = "512Mi"
  }
}

# JetStream configuration
variable "jetstream_enabled" {
  description = "Enable JetStream for persistent messaging"
  type        = bool
  default     = true
}

variable "jetstream_storage_size" {
  description = "JetStream storage size"
  type        = string
  default     = "10Gi"
}

variable "jetstream_storage_class" {
  description = "Storage class for JetStream persistence"
  type        = string
  default     = "gp3"
}

# Monitoring configuration
variable "monitoring_enabled" {
  description = "Enable NATS monitoring and metrics"
  type        = bool
  default     = true
}

variable "grafana_enabled" {
  description = "Deploy Grafana dashboard for NATS monitoring"
  type        = bool
  default     = false
}

# Backup configuration
variable "backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Backup schedule in cron format"
  type        = string
  default     = "0 2 * * *"  # Daily at 2 AM
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

# Local values for conditional deployment
locals {
  is_synadia_cloud = contains(["synadia_cloud", "hybrid"], var.deployment_type)
  is_self_hosted   = contains(["self_hosted_single", "self_hosted_cluster", "hybrid"], var.deployment_type)
  is_cluster_mode  = var.deployment_type == "self_hosted_cluster" || var.deployment_type == "hybrid"
  
  # Common labels
  common_labels = {
    "app.kubernetes.io/name"       = "nats"
    "app.kubernetes.io/instance"   = var.github_org
    "app.kubernetes.io/component"  = "messaging"
    "app.kubernetes.io/part-of"    = "github-automation"
    "app.kubernetes.io/managed-by" = "terraform"
    "github.com/org"               = var.github_org
  }
  
  # NATS configuration
  nats_config = {
    cluster_name = var.self_hosted_cluster_name
    replicas     = local.is_cluster_mode ? var.self_hosted_replicas : 1
    jetstream    = var.jetstream_enabled
    monitoring   = var.monitoring_enabled
  }
}

# =============================================================================
# Synadia Cloud Resources
# =============================================================================

# NATS Account for Synadia Cloud (conditionally created)
resource "nats_account" "github_org" {
  count = local.is_synadia_cloud ? 1 : 0
  
  name = var.github_org
  
  limits {
    max_connections = 1000
    max_streams     = 100
    max_consumers   = 500
    max_data        = "10GB"
    max_payload     = "1MB"
  }
  
  tags = {
    purpose     = "github-automation"
    environment = "production"
    managed_by  = "terraform"
  }
}
    max_payload     = "1MB"
  }
  
  exports {
    service {
      subject = "github.${var.github_org}.*.status"
      public  = true
    }
  }
  
  imports {
    service {
      subject = "terraform.deploy"
      account = var.synadia_account
    }
  }
}

# JetStream for GitHub events
resource "nats_stream" "github_events" {
  name     = "GITHUB_EVENTS_${upper(var.github_org)}"
  account  = nats_account.github_org.name
  
  subjects = [
    "github.${var.github_org}.template_changed",
    "github.${var.github_org}.workflow_status",
    "github.${var.github_org}.regeneration_requested"
  ]
  
  retention    = "workqueue"
  max_age      = "7d"
  max_msgs     = 1000000
  max_bytes    = "1GB"
  storage      = "file"
  replicas     = 3
  discard      = "old"
  
  # Prevent snake tail chasing
  duplicate_window = "2m"
}

# Consumer for template change processing
resource "nats_consumer" "template_processor" {
  stream_name = nats_stream.github_events.name
  account     = nats_account.github_org.name
  
  name           = "template-processor"
  durable        = true
  filter_subject = "github.${var.github_org}.template_changed"
  
  ack_policy     = "explicit"
  ack_wait       = "30s"
  max_deliver    = 3
  deliver_policy = "all"
  
  # Rate limiting to prevent overwhelming GitHub API
  rate_limit = 10  # messages per second
}

# Consumer for workflow status monitoring
resource "nats_consumer" "workflow_monitor" {
  stream_name = nats_stream.github_events.name
  account     = nats_account.github_org.name
  
  name           = "workflow-monitor"
  durable        = true
  filter_subject = "github.${var.github_org}.workflow_status"
  
  ack_policy  = "explicit"
  max_deliver = 1
  
  # Deliver only new messages
  deliver_policy = "new"
}

# AWS ECS cluster for NATS controllers
resource "aws_ecs_cluster" "nats_controllers" {
  name = "github-nats-controllers-${var.github_org}"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = {
    Organization = var.github_org
    Purpose      = "github-automation"
    ManagedBy    = "nats-terraform"
  }
}

# IAM role for NATS controllers
resource "aws_iam_role" "nats_controller_role" {
  name = "nats-controller-${var.github_org}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Policy for GitHub API access
resource "aws_iam_role_policy" "github_api_policy" {
  name = "github-api-access"
  role = aws_iam_role.nats_controller_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${var.region}:*:secret:github-token-*"
      }
    ]
  })
}

# ECS task definition for NATS controller
resource "aws_ecs_task_definition" "nats_controller" {
  family                   = "nats-controller-${var.github_org}"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 256
  memory                  = 512
  execution_role_arn      = aws_iam_role.nats_controller_role.arn
  task_role_arn          = aws_iam_role.nats_controller_role.arn
  
  container_definitions = jsonencode([
    {
      name  = "nats-controller"
      image = "ghcr.io/${var.github_org}/nats-controller:latest"
      
      environment = [
        {
          name  = "NATS_URL"
          value = "nats://connect.ngs.global"
        },
        {
          name  = "GITHUB_ORG"
          value = var.github_org
        },
        {
          name  = "SYNADIA_NKEY"
          value = var.synadia_nkey
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/nats-controller-${var.github_org}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      
      essential = true
    }
  ])
}

# Auto-scaling for NATS controllers based on message queue depth
resource "aws_appautoscaling_target" "nats_controller_scaling" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.nats_controllers.name}/nats-controller-${var.github_org}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Synadia Cloud Team and User management
resource "nats_team" "github_team" {
  count = local.is_synadia_cloud && var.synadia_team != "" ? 1 : 0
  
  account = nats_account.github_org[0].name
  name    = var.synadia_team
  
  permissions {
    can_publish   = ["github.>", "workflows.>", "events.>"]
    can_subscribe = ["github.>", "workflows.>", "events.>", "_INBOX.>"]
  }
}

# =============================================================================
# Self-Hosted NATS Resources (Kubernetes)
# =============================================================================

# Kubernetes namespace for NATS
resource "kubernetes_namespace" "nats" {
  count = local.is_self_hosted ? 1 : 0
  
  metadata {
    name   = var.kubernetes_namespace
    labels = local.common_labels
    
    annotations = {
      "managed-by" = "terraform"
      "github.com/org" = var.github_org
    }
  }
}

# NATS ConfigMap for self-hosted deployment
resource "kubernetes_config_map" "nats_config" {
  count = local.is_self_hosted ? 1 : 0
  
  metadata {
    name      = "${var.self_hosted_cluster_name}-config"
    namespace = kubernetes_namespace.nats[0].metadata[0].name
    labels    = local.common_labels
  }
  
  data = {
    "nats.conf" = templatefile("${path.module}/nats-config.template", {
      cluster_name    = var.self_hosted_cluster_name
      cluster_mode    = local.is_cluster_mode
      jetstream       = var.jetstream_enabled
      monitoring      = var.monitoring_enabled
      max_payload     = "1MB"
      max_connections = 1000
    })
  }
}

# NATS StatefulSet for self-hosted deployment
resource "kubernetes_stateful_set" "nats" {
  count = local.is_self_hosted ? 1 : 0
  
  metadata {
    name      = var.self_hosted_cluster_name
    namespace = kubernetes_namespace.nats[0].metadata[0].name
    labels    = local.common_labels
  }
  
  spec {
    service_name = "${var.self_hosted_cluster_name}-headless"
    replicas     = local.nats_config.replicas
    
    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "nats"
        "app.kubernetes.io/instance" = var.github_org
      }
    }
    
    template {
      metadata {
        labels = merge(local.common_labels, {
          "app.kubernetes.io/version" = "2.10"
        })
      }
      
      spec {
        service_account_name = kubernetes_service_account.nats[0].metadata[0].name
        
        container {
          name  = "nats"
          image = "nats:2.10-alpine"
          
          args = [
            "--config",
            "/etc/nats/nats.conf"
          ]
          
          port {
            name           = "client"
            container_port = 4222
            protocol       = "TCP"
          }
          
          port {
            name           = "cluster"
            container_port = 6222
            protocol       = "TCP"
          }
          
          port {
            name           = "monitor"
            container_port = 8222
            protocol       = "TCP"
          }
          
          dynamic "port" {
            for_each = var.jetstream_enabled ? [1] : []
            content {
              name           = "leafnodes"
              container_port = 7422
              protocol       = "TCP"
            }
          }
          
          resources {
            requests = var.resource_requests
            limits   = var.resource_limits
          }
          
          volume_mount {
            name       = "config"
            mount_path = "/etc/nats"
            read_only  = true
          }
          
          dynamic "volume_mount" {
            for_each = var.jetstream_enabled ? [1] : []
            content {
              name       = "jetstream-storage"
              mount_path = "/data"
            }
          }
          
          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8222
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
          }
          
          readiness_probe {
            http_get {
              path = "/healthz"
              port = 8222
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
          }
        }
        
        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.nats_config[0].metadata[0].name
          }
        }
      }
    }
    
    dynamic "volume_claim_template" {
      for_each = var.jetstream_enabled ? [1] : []
      content {
        metadata {
          name   = "jetstream-storage"
          labels = local.common_labels
        }
        
        spec {
          access_modes       = ["ReadWriteOnce"]
          storage_class_name = var.jetstream_storage_class
          
          resources {
            requests = {
              storage = var.jetstream_storage_size
            }
          }
        }
      }
    }
  }
}

# Service Account for NATS pods
resource "kubernetes_service_account" "nats" {
  count = local.is_self_hosted ? 1 : 0
  
  metadata {
    name      = var.self_hosted_cluster_name
    namespace = kubernetes_namespace.nats[0].metadata[0].name
    labels    = local.common_labels
  }
  
  automount_service_account_token = true
}

# Headless service for StatefulSet
resource "kubernetes_service" "nats_headless" {
  count = local.is_self_hosted ? 1 : 0
  
  metadata {
    name      = "${var.self_hosted_cluster_name}-headless"
    namespace = kubernetes_namespace.nats[0].metadata[0].name
    labels    = local.common_labels
  }
  
  spec {
    cluster_ip = "None"
    
    selector = {
      "app.kubernetes.io/name"     = "nats"
      "app.kubernetes.io/instance" = var.github_org
    }
    
    port {
      name        = "client"
      port        = 4222
      target_port = 4222
      protocol    = "TCP"
    }
    
    port {
      name        = "cluster"
      port        = 6222
      target_port = 6222
      protocol    = "TCP"
    }
    
    port {
      name        = "monitor"
      port        = 8222
      target_port = 8222
      protocol    = "TCP"
    }
  }
}

# Client service for external access
resource "kubernetes_service" "nats_client" {
  count = local.is_self_hosted ? 1 : 0
  
  metadata {
    name      = var.self_hosted_cluster_name
    namespace = kubernetes_namespace.nats[0].metadata[0].name
    labels    = local.common_labels
    
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-internal" = "true"
    }
  }
  
  spec {
    type = "LoadBalancer"
    
    selector = {
      "app.kubernetes.io/name"     = "nats"
      "app.kubernetes.io/instance" = var.github_org
    }
    
    port {
      name        = "client"
      port        = 4222
      target_port = 4222
      protocol    = "TCP"
    }
    
    port {
      name        = "monitor"
      port        = 8222
      target_port = 8222
      protocol    = "TCP"
    }
  }
}

# =============================================================================
# Monitoring Resources
# =============================================================================

# ServiceMonitor for Prometheus (if monitoring enabled)
resource "kubernetes_manifest" "nats_service_monitor" {
  count = local.is_self_hosted && var.monitoring_enabled ? 1 : 0
  
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    
    metadata = {
      name      = var.self_hosted_cluster_name
      namespace = kubernetes_namespace.nats[0].metadata[0].name
      labels    = local.common_labels
    }
    
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name"     = "nats"
          "app.kubernetes.io/instance" = var.github_org
        }
      }
      
      endpoints = [
        {
          port     = "monitor"
          path     = "/metrics"
          interval = "30s"
        }
      ]
    }
  }
}

# =============================================================================
# Backup Resources
# =============================================================================

# CronJob for NATS JetStream backups
resource "kubernetes_cron_job_v1" "nats_backup" {
  count = local.is_self_hosted && var.backup_enabled && var.jetstream_enabled ? 1 : 0
  
  metadata {
    name      = "${var.self_hosted_cluster_name}-backup"
    namespace = kubernetes_namespace.nats[0].metadata[0].name
    labels    = local.common_labels
  }
  
  spec {
    schedule                      = var.backup_schedule
    concurrency_policy           = "Forbid"
    successful_jobs_history_limit = 3
    failed_jobs_history_limit     = 1
    
    job_template {
      metadata {
        labels = local.common_labels
      }
      
      spec {
        template {
          metadata {
            labels = local.common_labels
          }
          
          spec {
            restart_policy = "OnFailure"
            
            container {
              name  = "backup"
              image = "natsio/nats-box:latest"
              
              command = ["/bin/sh"]
              args = [
                "-c",
                <<-EOT
                  # Connect to NATS and backup JetStream
                  nats --server=nats://${var.self_hosted_cluster_name}:4222 \
                    stream backup --all /backup/$(date +%Y%m%d_%H%M%S)
                  
                  # Upload to S3 (if configured)
                  if [ -n "$AWS_S3_BUCKET" ]; then
                    aws s3 sync /backup/ s3://$AWS_S3_BUCKET/nats-backups/
                  fi
                  
                  # Cleanup old local backups
                  find /backup -type d -mtime +${var.backup_retention_days} -exec rm -rf {} +
                EOT
              ]
              
              env {
                name  = "AWS_S3_BUCKET"
                value = "github-nats-backups-${var.github_org}"
              }
              
              volume_mount {
                name       = "backup-storage"
                mount_path = "/backup"
              }
            }
            
            volume {
              name = "backup-storage"
              persistent_volume_claim {
                claim_name = kubernetes_persistent_volume_claim.backup_storage[0].metadata[0].name
              }
            }
          }
        }
      }
    }
  }
}

# PVC for backup storage
resource "kubernetes_persistent_volume_claim" "backup_storage" {
  count = local.is_self_hosted && var.backup_enabled ? 1 : 0
  
  metadata {
    name      = "${var.self_hosted_cluster_name}-backup"
    namespace = kubernetes_namespace.nats[0].metadata[0].name
    labels    = local.common_labels
  }
  
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.jetstream_storage_class
    
    resources {
      requests = {
        storage = "50Gi"
      }
    }
  }
}

# =============================================================================
# Outputs
# =============================================================================

# Synadia Cloud outputs
output "synadia_cloud_account" {
  description = "Synadia Cloud account name"
  value       = local.is_synadia_cloud ? nats_account.github_org[0].name : null
}

output "synadia_cloud_team" {
  description = "Synadia Cloud team name"
  value       = local.is_synadia_cloud && var.synadia_team != "" ? nats_team.github_team[0].name : null
}

# Self-hosted outputs
output "self_hosted_namespace" {
  description = "Kubernetes namespace for self-hosted NATS"
  value       = local.is_self_hosted ? kubernetes_namespace.nats[0].metadata[0].name : null
}

output "self_hosted_service_name" {
  description = "Kubernetes service name for self-hosted NATS client access"
  value       = local.is_self_hosted ? kubernetes_service.nats_client[0].metadata[0].name : null
}

output "self_hosted_cluster_ip" {
  description = "Internal cluster IP for self-hosted NATS"
  value       = local.is_self_hosted ? kubernetes_service.nats_client[0].spec[0].cluster_ip : null
}

output "self_hosted_external_ip" {
  description = "External load balancer IP for self-hosted NATS"
  value       = local.is_self_hosted ? try(kubernetes_service.nats_client[0].status[0].load_balancer[0].ingress[0].ip, null) : null
}

# Common outputs
output "deployment_type" {
  description = "NATS deployment type used"
  value       = var.deployment_type
}

output "jetstream_enabled" {
  description = "Whether JetStream is enabled"
  value       = var.jetstream_enabled
}

output "monitoring_enabled" {
  description = "Whether monitoring is enabled"
  value       = var.monitoring_enabled
}

output "backup_enabled" {
  description = "Whether backups are enabled"
  value       = var.backup_enabled
}

# Connection strings for different deployment types
output "nats_connection_url" {
  description = "NATS connection URL based on deployment type"
  value = local.is_synadia_cloud ? "connect.ngs.global" : (
    local.is_self_hosted ? "${kubernetes_service.nats_client[0].metadata[0].name}.${kubernetes_namespace.nats[0].metadata[0].name}.svc.cluster.local:4222" : null
  )
  sensitive = false
}

output "nats_monitoring_url" {
  description = "NATS monitoring URL"
  value = local.is_self_hosted && var.monitoring_enabled ? "http://${kubernetes_service.nats_client[0].metadata[0].name}.${kubernetes_namespace.nats[0].metadata[0].name}.svc.cluster.local:8222" : null
  sensitive = false
}
