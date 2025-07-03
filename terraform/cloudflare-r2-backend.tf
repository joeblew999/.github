# Cloudflare R2 Backend Configuration for Terraform State Storage
# This configuration enables using Cloudflare R2 as an S3-compatible backend for Terraform state

terraform {
  # Example backend configuration for Cloudflare R2
  # Uncomment and configure when ready to migrate from local state
  # 
  # backend "s3" {
  #   bucket                      = "terraform-state-joeblew999"
  #   key                         = "nats-infrastructure/terraform.tfstate"
  #   region                      = "auto"  # R2 uses "auto" for region
  #   endpoint                    = "https://<account-id>.r2.cloudflarestorage.com"
  #   access_key                  = var.cloudflare_r2_access_key
  #   secret_key                  = var.cloudflare_r2_secret_key
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  #   skip_region_validation      = true
  #   use_path_style              = true
  #   use_lockfile               = true  # Enable state locking
  # }
}

# Variables for Cloudflare R2 configuration
variable "cloudflare_r2_access_key" {
  description = "Cloudflare R2 access key ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_r2_secret_key" {
  description = "Cloudflare R2 secret access key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID for R2 endpoint"
  type        = string
  sensitive   = true
  default     = ""
}

# Local values for R2 configuration
locals {
  # Cloudflare R2 endpoint URL
  r2_endpoint = var.cloudflare_account_id != "" ? "https://${var.cloudflare_account_id}.r2.cloudflarestorage.com" : ""
  
  # State bucket configuration
  state_bucket_name = "terraform-state-joeblew999"
  state_key_prefix  = "nats-infrastructure"
}

# Output R2 configuration for reference
output "cloudflare_r2_config" {
  description = "Cloudflare R2 backend configuration reference"
  value = {
    bucket   = local.state_bucket_name
    endpoint = local.r2_endpoint
    region   = "auto"
    features = [
      "S3-compatible API",
      "Zero egress fees",
      "Global edge storage",
      "Built-in state locking",
      "Cost-effective at $0.015/GB/month"
    ]
  }
  sensitive = false
}

# Example R2 bucket creation (when not using backend)
# This creates the bucket if we're not using R2 as backend yet
resource "aws_s3_bucket" "terraform_state" {
  count = var.cloudflare_account_id != "" ? 1 : 0
  
  bucket = local.state_bucket_name
  
  # Use Cloudflare R2 endpoint
  provider = aws.cloudflare_r2
  
  tags = {
    Name        = "Terraform State Storage"
    Environment = "Infrastructure"
    Purpose     = "NATS Infrastructure State"
    Provider    = "Cloudflare R2"
  }
}

# Bucket versioning for state recovery
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  count = var.cloudflare_account_id != "" ? 1 : 0
  
  bucket = aws_s3_bucket.terraform_state[0].id
  provider = aws.cloudflare_r2
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  count = var.cloudflare_account_id != "" ? 1 : 0
  
  bucket = aws_s3_bucket.terraform_state[0].id
  provider = aws.cloudflare_r2

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Provider configuration for Cloudflare R2
provider "aws" {
  alias = "cloudflare_r2"
  
  # Use Cloudflare R2 S3-compatible endpoint
  endpoints {
    s3 = local.r2_endpoint
  }
  
  # R2 credentials
  access_key = var.cloudflare_r2_access_key
  secret_key = var.cloudflare_r2_secret_key
  
  # R2-specific settings
  region                      = "auto"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  
  # Required for R2 compatibility
  s3_use_path_style = true
}
