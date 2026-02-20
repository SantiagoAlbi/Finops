# Lambda Function: Cost Anomaly Detector
resource "aws_lambda_function" "cost_anomaly_detector" {
  filename      = "${path.module}/cost_anomaly_detector.zip" # con diferente carpeta "lambda_packages/cost_anomaly_detector.zip"
  function_name = "${var.project_name}-cost-anomaly-detector"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_cost_anomaly.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60 # 1 minuto (Cost Explorer puede ser lento)
  memory_size   = 256

  # Variables de entorno que usa la Lambda
  environment {
    variables = {
      DYNAMODB_TABLE    = aws_dynamodb_table.cost_history.name
      SNS_TOPIC_ARN     = aws_sns_topic.cost_alerts.arn
      ANOMALY_THRESHOLD = var.cost_anomaly_threshold
      HISTORICAL_DAYS   = var.historical_days
    }
  }

  # Depende de CloudWatch Log Group
  depends_on = [
    aws_cloudwatch_log_group.cost_anomaly_lambda,
    aws_iam_role_policy_attachment.lambda_logs
  ]

  tags = {
    Name = "${var.project_name}-cost-anomaly-detector"
  }
}

# EventBridge Rule: ejecutar cada 6 horas
resource "aws_cloudwatch_event_rule" "cost_anomaly_schedule" {
  name                = "${var.project_name}-cost-anomaly-schedule"
  description         = "Trigger cost anomaly detector every 6 hours"
  schedule_expression = "rate(6 hours)"

  tags = {
    Name = "${var.project_name}-cost-anomaly-schedule"
  }
}

# EventBridge Target: apunta a la Lambda
resource "aws_cloudwatch_event_target" "cost_anomaly_lambda_target" {
  rule      = aws_cloudwatch_event_rule.cost_anomaly_schedule.name
  target_id = "CostAnomalyDetector"
  arn       = aws_lambda_function.cost_anomaly_detector.arn
}

# Permiso para que EventBridge invoque la Lambda
resource "aws_lambda_permission" "allow_eventbridge_cost_anomaly" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_anomaly_detector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_anomaly_schedule.arn
}
