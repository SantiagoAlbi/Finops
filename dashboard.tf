# CloudWatch Dashboard para métricas de costos
resource "aws_cloudwatch_dashboard" "finops_dashboard" {
  dashboard_name = "${var.project_name}-cost-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Widget 1: Texto de bienvenida
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2
        properties = {
          markdown = <<-EOT
            # 💰 FinOps Platform - Cost Monitoring Dashboard
            
            **Last updated:** Auto-refresh every 5 minutes
            
            **Features:** Cost anomaly detection • Unused resources scanner • Automated alerts
          EOT
        }
      },

      # Widget 2: Métricas de Lambda - Cost Anomaly Detector
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Invocations" }],
            [".", "Errors", { stat = "Sum", label = "Errors" }],
            [".", "Duration", { stat = "Average", label = "Avg Duration (ms)" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "📊 Cost Anomaly Detector - Metrics"
          period  = 300
          yAxis = {
            left = {
              label = "Count"
            }
          }
        }
      },

      # Widget 3: Métricas de Lambda - Unused Resources Scanner
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", label = "Invocations" }],
            [".", "Errors", { stat = "Sum", label = "Errors" }],
            [".", "Duration", { stat = "Average", label = "Avg Duration (ms)" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "🔍 Unused Resources Scanner - Metrics"
          period  = 300
        }
      },

      # Widget 4: DynamoDB - Operaciones
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", { stat = "Sum" }],
            [".", "ConsumedWriteCapacityUnits", { stat = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "💾 DynamoDB Operations"
          period  = 300
        }
      },

      # Widget 5: SNS - Notificaciones enviadas
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/SNS", "NumberOfMessagesPublished", { stat = "Sum", label = "Messages Sent" }],
            [".", "NumberOfNotificationsFailed", { stat = "Sum", label = "Failed" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "📧 SNS Notifications"
          period  = 300
        }
      },

      # Widget 6: Lambda Logs Insights - Anomalías detectadas
      {
        type   = "log"
        x      = 0
        y      = 14
        width  = 24
        height = 6
        properties = {
          query  = <<-EOT
            SOURCE '${aws_cloudwatch_log_group.cost_anomaly_lambda.name}'
            | fields @timestamp, @message
            | filter @message like /anomalías detectadas/
            | sort @timestamp desc
            | limit 20
          EOT
          region = var.aws_region
          title  = "⚠️  Recent Cost Anomaly Alerts"
        }
      },

      # Widget 7: Lambda Logs Insights - Recursos sin usar
      {
        type   = "log"
        x      = 0
        y      = 20
        width  = 24
        height = 6
        properties = {
          query  = <<-EOT
            SOURCE '${aws_cloudwatch_log_group.unused_resources_lambda.name}'
            | fields @timestamp, @message
            | filter @message like /recursos sin usar/
            | sort @timestamp desc
            | limit 20
          EOT
          region = var.aws_region
          title  = "🗑️  Unused Resources Detection Log"
        }
      }
    ]
  })
}

# Output del dashboard URL
output "dashboard_url" {
  description = "URL del CloudWatch Dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.finops_dashboard.dashboard_name}"
}
