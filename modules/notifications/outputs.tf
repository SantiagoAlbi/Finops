output "topic_arn" {
  value       = aws_sns_topic.cost_alerts.arn
  description = "ARN of the SNS cost alerts topic"
}
