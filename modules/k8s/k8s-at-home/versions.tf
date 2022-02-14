terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 1.0"
    }
     helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
