# Empaquetar código Python en ZIP antes de deployar
data "archive_file" "cost_anomaly_zip" {
  type        = "zip"
  source_file = "${path.root}/lambda_src/cost_anomaly/lambda_cost_anomaly.py"
  output_path = "${path.root}/lambda_src/cost_anomaly/cost_anomaly_detector.zip"
}

data "archive_file" "unused_resources_zip" {
  type        = "zip"
  source_file = "${path.root}/lambda_src/unused_resources/lambda_unused_resources.py"
  output_path = "${path.root}/lambda_src/unused_resources/unused_resources_scanner.zip"
}

# Lambda: Cost Anomaly Detector
resource "aws_lambda_function" "cost_anomaly_detector" {
  filename      = data.archive_file.cost_anomaly_zip.output_path
  function_name = "${var.project_name}-cost-anomaly-detector"
  role          = var.lambda_role_arn
  handler       = "lambda_cost_anomaly.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 256

  source_code_hash = data.archive_file.cost_anomaly_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN      = var.sns_topic_arn
      DYNAMODB_TABLE     = var.dynamodb_table_name
      ANOMALY_THRESHOLD  = var.anomaly_threshold
      HISTORICAL_DAYS    = var.historical_days
    }
  }

  depends_on = [var.cost_anomaly_log_group]

  tags = {
    Name        = "${var.project_name}-cost-anomaly-detector"
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

# EventBridge Rule: cada 6 horas
resource "aws_cloudwatch_event_rule" "cost_anomaly_schedule" {
  name                = "${var.project_name}-cost-anomaly-schedule"
  description         = "Trigger cost anomaly detector every 6 hours"
  schedule_expression = "rate(6 hours)"

  tags = {
    Name        = "${var.project_name}-cost-anomaly-schedule"
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_event_target" "cost_anomaly_lambda_target" {
  rule      = aws_cloudwatch_event_rule.cost_anomaly_schedule.name
  target_id = "CostAnomalyDetector"
  arn       = aws_lambda_function.cost_anomaly_detector.arn
}

resource "aws_lambda_permission" "allow_eventbridge_cost_anomaly" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_anomaly_detector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_anomaly_schedule.arn
}

# Lambda: Unused Resources Scanner
resource "aws_lambda_function" "unused_resources_scanner" {
  filename      = data.archive_file.unused_resources_zip.output_path
  function_name = "${var.project_name}-unused-resources-scanner"
  role          = var.lambda_role_arn
  handler       = "lambda_unused_resources.lambda_handler"
  runtime       = "python3.11"
  timeout       = 120
  memory_size   = 256

  source_code_hash = data.archive_file.unused_resources_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN     = var.sns_topic_arn
      SNAPSHOT_AGE_DAYS = var.snapshot_age_days
    }
  }

  depends_on = [var.unused_resources_log_group]

  tags = {
    Name        = "${var.project_name}-unused-resources-scanner"
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

# EventBridge Rule: diario a las 9am UTC
resource "aws_cloudwatch_event_rule" "unused_resources_schedule" {
  name                = "${var.project_name}-unused-resources-schedule"
  description         = "Trigger unused resources scanner daily at 9am UTC"
  schedule_expression = "cron(0 9 * * ? *)"

  tags = {
    Name        = "${var.project_name}-unused-resources-schedule"
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_event_target" "unused_resources_lambda_target" {
  rule      = aws_cloudwatch_event_rule.unused_resources_schedule.name
  target_id = "UnusedResourcesScanner"
  arn       = aws_lambda_function.unused_resources_scanner.arn
}

resource "aws_lambda_permission" "allow_eventbridge_unused_resources" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.unused_resources_scanner.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.unused_resources_schedule.arn
}
