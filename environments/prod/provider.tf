terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# ========================================
# Local Variables for Tags
# ========================================

locals {
  common_tags = {
    Project   = "CoolDelivery"
    ManagedBy = "Terraform"
    CreatedAt = "2026"
  }

  dev_tags = merge(
    local.common_tags,
    {
      Environment = "dev"
    }
  )

  staging_tags = merge(
    local.common_tags,
    {
      Environment = "staging"
    }
  )

  prod_tags = merge(
    local.common_tags,
    {
      Environment = "prod"
      Compliance  = "true"
      DataClass   = "sensitive"
    }
  )
}
