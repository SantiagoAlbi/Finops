resource "aws_sns_topic" "cost_alerts" {
  name = "${var.project_name}-cost-alerts"

  tags = {
    Name        = "${var.project_name}-cost-alerts"
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
