terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "finops-platform-terraform-state-975049900198"
    key            = "finops/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "finops-platform-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
