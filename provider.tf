terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend local por ahora, luego puedes cambiar a S3
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "FinOps-Platform"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
