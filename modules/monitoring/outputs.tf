output "cost_anomaly_log_group" {
  value       = aws_cloudwatch_log_group.cost_anomaly_lambda.name
  description = "Name of the cost anomaly Lambda log group"
}

output "unused_resources_log_group" {
  value       = aws_cloudwatch_log_group.unused_resources_lambda.name
  description = "Name of the unused resources Lambda log group"
}

output "dashboard_name" {
  value       = aws_cloudwatch_dashboard.finops_dashboard.dashboard_name
  description = "Name of the CloudWatch dashboard"
}
