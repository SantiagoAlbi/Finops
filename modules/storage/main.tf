resource "aws_dynamodb_table" "cost_history" {
  name         = "${var.project_name}-cost-history"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "service"
  range_key    = "date"

  attribute {
    name = "service"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-cost-history"
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}
