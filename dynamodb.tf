# DynamoDB table para almacenar histórico de costos
resource "aws_dynamodb_table" "cost_history" {
  name         = "${var.project_name}-cost-history"
  billing_mode = "PAY_PER_REQUEST" # On-demand: pagas solo por uso
  hash_key     = "date_service"    # Partition key: fecha + servicio
  range_key    = "timestamp"       # Sort key: timestamp exacto

  attribute {
    name = "date_service"
    type = "S" # String: formato "2024-12-15#EC2"
  }

  attribute {
    name = "timestamp"
    type = "N" # Number: Unix timestamp
  }

  # TTL: elimina automáticamente registros antiguos (ahorro de costos)
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  # Habilitar point-in-time recovery (backups automáticos)
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-cost-history"
  }
}
