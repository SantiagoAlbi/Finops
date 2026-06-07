output "sns_topic_arn" {
  value       = module.notifications.topic_arn
  description = "ARN of the SNS cost alerts topic"
}

output "dynamodb_table_name" {
  value       = module.storage.table_name
  description = "Name of the DynamoDB cost history table"
}

output "cost_anomaly_function_name" {
  value       = module.lambda.cost_anomaly_function_name
  description = "Name of the cost anomaly detector Lambda function"
}

output "unused_resources_function_name" {
  value       = module.lambda.unused_resources_function_name
  description = "Name of the unused resources scanner Lambda function"
}

output "dashboard_name" {
  value       = module.monitoring.dashboard_name
  description = "Name of the CloudWatch dashboard"
}

output "github_actions_role_arn" {
  value       = module.iam.github_actions_role_arn
  description = "ARN of the GitHub Actions OIDC role"
}
