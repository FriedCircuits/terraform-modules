terraform {
  required_version = ">= 1.0"

  required_providers {
    jumpcloud = {
      source  = "sagewave/jumpcloud"
      version = "~> 0.3"
    }
  }
}
