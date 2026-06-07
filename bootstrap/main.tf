terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# S3 bucket para almacenar el remote state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "finops-platform-terraform-state-975049900198"

  tags = {
    Name        = "finops-platform-terraform-state"
    Project     = "FinOps-Platform"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

# Versioning obligatorio: permite recuperar states anteriores
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Bloquear acceso público al bucket (el state tiene info sensible)
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encriptación server-side con AES256
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB table para state locking (evita applies simultáneos)
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "finops-platform-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "finops-platform-terraform-locks"
    Project     = "FinOps-Platform"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

output "locks_table_name" {
  value = aws_dynamodb_table.terraform_locks.id
}
