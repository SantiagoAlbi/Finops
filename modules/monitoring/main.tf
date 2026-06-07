resource "aws_cloudwatch_log_group" "cost_anomaly_lambda" {
  name              = "/aws/lambda/${var.project_name}-cost-anomaly-detector"
  retention_in_days = var.retention_days

  tags = {
    Name        = "${var.project_name}-cost-anomaly-logs"
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "unused_resources_lambda" {
  name              = "/aws/lambda/${var.project_name}-unused-resources-scanner"
  retention_in_days = var.retention_days

  tags = {
    Name        = "${var.project_name}-unused-resources-logs"
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-errors"
  alarm_description   = "Alert when Lambda has more than 3 errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  actions_enabled     = true
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "missing"

  dimensions = {
    FunctionName = "${var.project_name}-cost-anomaly-detector"
  }

  tags = {
    Name        = "${var.project_name}-lambda-errors-alarm"
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_dashboard" "finops_dashboard" {
  dashboard_name = "${var.project_name}-cost-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = "# 💰 FinOps Platform - Cost Monitoring Dashboard\n\n**Last updated:** Auto-refresh every 5 minutes"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6
        properties = {
          title   = "Lambda Invocations"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-cost-anomaly-detector"],
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-unused-resources-scanner"]
          ]
          period = 300
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6
        properties = {
          title   = "Lambda Errors"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", "${var.project_name}-cost-anomaly-detector"],
            ["AWS/Lambda", "Errors", "FunctionName", "${var.project_name}-unused-resources-scanner"]
          ]
          period = 300
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6
        properties = {
          title   = "Lambda Duration (ms)"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", "${var.project_name}-cost-anomaly-detector", { stat = "Average" }],
            ["AWS/Lambda", "Duration", "FunctionName", "${var.project_name}-unused-resources-scanner", { stat = "Average" }]
          ]
          period = 300
          region = var.aws_region
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6
        properties = {
          title   = "DynamoDB Read/Write Capacity"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", "${var.project_name}-cost-history"],
            ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", "${var.project_name}-cost-history"]
          ]
          period = 300
          region = var.aws_region
        }
      }
    ]
  })
}
