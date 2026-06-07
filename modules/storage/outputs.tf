output "table_name" {
  value       = aws_dynamodb_table.cost_history.name
  description = "Name of the DynamoDB cost history table"
}

output "table_arn" {
  value       = aws_dynamodb_table.cost_history.arn
  description = "ARN of the DynamoDB cost history table"
}
