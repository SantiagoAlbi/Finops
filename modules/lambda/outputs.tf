output "cost_anomaly_function_name" {
  value       = aws_lambda_function.cost_anomaly_detector.function_name
  description = "Name of the cost anomaly detector Lambda function"
}

output "unused_resources_function_name" {
  value       = aws_lambda_function.unused_resources_scanner.function_name
  description = "Name of the unused resources scanner Lambda function"
}

output "cost_anomaly_function_arn" {
  value       = aws_lambda_function.cost_anomaly_detector.arn
  description = "ARN of the cost anomaly detector Lambda function"
}

output "unused_resources_function_arn" {
  value       = aws_lambda_function.unused_resources_scanner.arn
  description = "ARN of the unused resources scanner Lambda function"
}
