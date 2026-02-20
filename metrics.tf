# Custom Metric: Anomalías detectadas
# (esto lo agregaremos al código Python después)

# Metric Alarm: alertar si hay demasiados errores en Lambda
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Alert when Lambda has more than 3 errors"
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.cost_anomaly_detector.function_name
  }

  tags = {
    Name = "${var.project_name}-lambda-errors-alarm"
  }
}
