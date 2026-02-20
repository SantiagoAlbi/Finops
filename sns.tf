# SNS Topic para alertas de costos
resource "aws_sns_topic" "cost_alerts" {
  name              = "${var.project_name}-cost-alerts"
  display_name      = "FinOps Platform Cost Alerts"
  kms_master_key_id = "alias/aws/sns" # Encriptación gratuita con managed key

  tags = {
    Name = "${var.project_name}-cost-alerts"
  }
}

# SNS Topic Policy - permite a las Lambdas publicar mensajes
resource "aws_sns_topic_policy" "cost_alerts_policy" {
  arn = aws_sns_topic.cost_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaPublish"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.cost_alerts.arn
      }
    ]
  })
}

# Email subscription (opcional, solo si email está configurado)
resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
