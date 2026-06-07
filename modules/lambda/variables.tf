variable "project_name" {
  type        = string
  description = "Project name prefix for all resources"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "lambda_role_arn" {
  type        = string
  description = "ARN of the Lambda execution IAM role"
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN of the SNS cost alerts topic"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the DynamoDB cost history table"
}

variable "anomaly_threshold" {
  type        = string
  description = "Cost anomaly threshold percentage"
  default     = "30"
}

variable "historical_days" {
  type        = string
  description = "Number of historical days to analyze"
  default     = "7"
}

variable "snapshot_age_days" {
  type        = string
  description = "Age in days to flag snapshots as unused"
  default     = "30"
}

variable "cost_anomaly_log_group" {
  type        = string
  description = "Name of the cost anomaly Lambda log group (ensures log group exists before Lambda)"
}

variable "unused_resources_log_group" {
  type        = string
  description = "Name of the unused resources Lambda log group (ensures log group exists before Lambda)"
}
