# Self-similar NATS regional deployment
# This Terraform is called by NATS controllers to create more NATS infrastructure

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

variable "parent_account" {
  description = "Parent NATS account that triggered this deployment"
  type        = string
}

variable "region" {
  description = "AWS region for this regional deployment"
  type        = string
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "load_factor" {
  description = "Expected load factor (1.0 = normal, 2.0 = double capacity)"
  type        = number
  default     = 1.0
}

variable "synadia_account" {
  description = "Synadia Cloud account"
  type        = string
}

# Local NATS server for low-latency processing
resource "aws_instance" "nats_server" {
  count = ceil(var.load_factor)
  
  ami           = "ami-0c02fb55956c7d316"  # Amazon Linux 2
  instance_type = var.load_factor > 2.0 ? "m5.large" : "t3.medium"
  
  user_data = base64encode(templatefile("${path.module}/nats-server-setup.sh", {
    synadia_account = var.synadia_account
    github_org      = var.github_org
    region          = var.region
  }))
  
  tags = {
    Name         = "nats-regional-${var.region}-${count.index}"
    Organization = var.github_org
    Purpose      = "regional-nats-processing"
    LoadFactor   = var.load_factor
  }
}

# Regional stream for local processing
resource "nats_stream" "regional_processing" {
  name = "REGIONAL_PROCESSING_${upper(var.region)}"
  
  subjects = [
    "github.${var.github_org}.${var.region}.>",
    "terraform.${var.region}.>"
  ]
  
  retention = "workqueue"
  max_age   = "1h"  # Short retention for regional processing
  storage   = "memory"  # Fast processing
  replicas  = min(3, length(aws_instance.nats_server))
}

# Auto-scaling CloudWatch alarm
resource "aws_cloudwatch_metric_alarm" "high_message_rate" {
  alarm_name          = "nats-high-message-rate-${var.region}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MessagesPerSecond"
  namespace           = "NATS/Regional"
  period              = "60"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "This metric monitors NATS message rate"
  
  alarm_actions = [aws_sns_topic.nats_scaling.arn]
}

# SNS topic for triggering more infrastructure
resource "aws_sns_topic" "nats_scaling" {
  name = "nats-scaling-${var.region}"
}

# Lambda function to trigger more Terraform deployments
resource "aws_lambda_function" "terraform_trigger" {
  filename         = "terraform-trigger.zip"
  function_name    = "nats-terraform-trigger-${var.region}"
  role            = aws_iam_role.lambda_terraform.arn
  handler         = "index.handler"
  source_code_hash = filebase64sha256("terraform-trigger.zip")
  runtime         = "python3.9"
  
  environment {
    variables = {
      GITHUB_ORG = var.github_org
      REGION     = var.region
      NATS_URL   = "nats://connect.ngs.global"
    }
  }
}

# IAM role for Lambda to trigger Terraform
resource "aws_iam_role" "lambda_terraform" {
  name = "lambda-terraform-trigger-${var.region}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Output for connecting regional infrastructure to parent
output "regional_nats_servers" {
  description = "Regional NATS server endpoints"
  value = [
    for instance in aws_instance.nats_server : {
      id         = instance.id
      private_ip = instance.private_ip
      public_ip  = instance.public_ip
    }
  ]
}

output "regional_stream" {
  description = "Regional processing stream"
  value = nats_stream.regional_processing.name
}

output "scaling_topic" {
  description = "SNS topic for triggering more infrastructure"
  value = aws_sns_topic.nats_scaling.arn
}
