# Terraform configuration for NATS-powered GitHub organization management
# Called by NATS controllers for self-similar infrastructure deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    nats = {
      source  = "synadia-io/nats"
      version = "~> 0.1"
    }
  }
}

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

variable "synadia_account" {
  description = "Synadia Cloud account ID"
  type        = string
  sensitive   = true
}

variable "synadia_nkey" {
  description = "Synadia Cloud N-Key for authentication"
  type        = string
  sensitive   = true
}

# NATS Account for the GitHub organization
resource "nats_account" "github_org" {
  name = var.github_org
  
  limits {
    max_connections = 1000
    max_streams     = 100
    max_consumers   = 500
    max_data        = "10GB"
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

# Output values for connecting to NATS infrastructure
output "nats_account_id" {
  description = "NATS account ID for the GitHub organization"
  value       = nats_account.github_org.id
}

output "github_events_stream" {
  description = "JetStream name for GitHub events"
  value       = nats_stream.github_events.name
}

output "ecs_cluster_name" {
  description = "ECS cluster name for NATS controllers"
  value       = aws_ecs_cluster.nats_controllers.name
}

output "connection_info" {
  description = "NATS connection information"
  value = {
    url     = "nats://connect.ngs.global"
    account = nats_account.github_org.name
    stream  = nats_stream.github_events.name
  }
  sensitive = true
}
