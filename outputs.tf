# Outputs que necesitaremos para las Lambdas
output "sns_topic_arn" {
  description = "ARN del SNS topic para alertas"
  value       = aws_sns_topic.cost_alerts.arn
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para histórico"
  value       = aws_dynamodb_table.cost_history.name
}

output "lambda_role_arn" {
  description = "ARN del IAM role para las Lambdas"
  value       = aws_iam_role.lambda_role.arn
}

output "cost_anomaly_log_group" {
  description = "CloudWatch Log Group para Lambda de anomalías"
  value       = aws_cloudwatch_log_group.cost_anomaly_lambda.name
}

output "unused_resources_log_group" {
  description = "CloudWatch Log Group para Lambda de recursos sin usar"
  value       = aws_cloudwatch_log_group.unused_resources_lambda.name
}

output "project_name" {
  description = "Nombre del proyecto"
  value       = var.project_name
}

output "aws_region" {
  description = "Región AWS"
  value       = var.aws_region
}

output "cost_anomaly_threshold" {
  description = "Umbral de anomalía de costos (%)"
  value       = var.cost_anomaly_threshold
}

output "historical_days" {
  description = "Días históricos para comparación"
  value       = var.historical_days
}

