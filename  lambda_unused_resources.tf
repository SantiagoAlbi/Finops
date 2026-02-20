# Lambda Function: Unused Resources Scanner
resource "aws_lambda_function" "unused_resources_scanner" {
  filename      = "unused_resources_scanner.zip"
  function_name = "${var.project_name}-unused-resources-scanner"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_unused_resources.lambda_handler"
  runtime       = "python3.11"
  timeout       = 120 # 2 minutos (escanear múltiples servicios)
  memory_size   = 256

  environment {
    variables = {
      SNS_TOPIC_ARN     = aws_sns_topic.cost_alerts.arn
      SNAPSHOT_AGE_DAYS = 30
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.unused_resources_lambda,
    aws_iam_role_policy_attachment.lambda_logs
  ]

  tags = {
    Name = "${var.project_name}-unused-resources-scanner"
  }
}

# EventBridge Rule: ejecutar diario a las 9am UTC
resource "aws_cloudwatch_event_rule" "unused_resources_schedule" {
  name                = "${var.project_name}-unused-resources-schedule"
  description         = "Trigger unused resources scanner daily at 9am UTC"
  schedule_expression = "cron(0 9 * * ? *)"

  tags = {
    Name = "${var.project_name}-unused-resources-schedule"
  }
}

# EventBridge Target: apunta a la Lambda
resource "aws_cloudwatch_event_target" "unused_resources_lambda_target" {
  rule      = aws_cloudwatch_event_rule.unused_resources_schedule.name
  target_id = "UnusedResourcesScanner"
  arn       = aws_lambda_function.unused_resources_scanner.arn
}

# Permiso para que EventBridge invoque la Lambda
resource "aws_lambda_permission" "allow_eventbridge_unused_resources" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.unused_resources_scanner.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.unused_resources_schedule.arn
}
