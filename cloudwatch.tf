# CloudWatch Log Group para Lambda de anomalías de costos
resource "aws_cloudwatch_log_group" "cost_anomaly_lambda" {
  name              = "/aws/lambda/${var.project_name}-cost-anomaly-detector"
  retention_in_days = var.retention_days

  tags = {
    Name = "${var.project_name}-cost-anomaly-logs"
  }
}

# CloudWatch Log Group para Lambda de recursos sin usar
resource "aws_cloudwatch_log_group" "unused_resources_lambda" {
  name              = "/aws/lambda/${var.project_name}-unused-resources-scanner"
  retention_in_days = var.retention_days

  tags = {
    Name = "${var.project_name}-unused-resources-logs"
  }
}
