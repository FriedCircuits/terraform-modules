terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
  }
}

variable "endpoint" {
  description = "Your IDrive e2 region's S3 endpoint URL."
  type        = string
}

variable "region" {
  description = "Signing region for the endpoint (Oregon: us-west-1)."
  type        = string
  default     = "us-west-1"
}

variable "bucket_name" {
  type = string
}

# Credentials come from AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.
provider "aws" {
  region                      = var.region
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true

  endpoints {
    s3 = var.endpoint
  }
}

module "bucket" {
  source = "../.."

  bucket_name       = var.bucket_name
  versioning_status = "Enabled"
  cleanup_rules = {
    version-cleanup = {
      prefix          = "data/"
      noncurrent_days = 2
    }
  }
}
