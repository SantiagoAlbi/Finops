variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "finops-platform"
}

variable "alert_email" {
  description = "Email for cost anomaly alerts (leave empty to configure later)"
  type        = string
  default     = "example@mail.com"
}

variable "cost_anomaly_threshold" {
  description = "Percentage threshold for cost anomaly detection"
  type        = number
  default     = 30
}

variable "historical_days" {
  description = "Number of days to compare for anomaly detection"
  type        = number
  default     = 7
}

variable "retention_days" {
  description = "CloudWatch logs retention in days"
  type        = number
  default     = 7
}
