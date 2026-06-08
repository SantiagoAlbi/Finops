variable "project_name" {
  type        = string
  description = "Project name prefix for all resources"
  default     = "finops-platform"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "alert_email" {
  type        = string
  description = "Email address to receive cost alerts"
}

variable "retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 7
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

variable "github_repo" {
  type        = string
  description = "GitHub repository in format owner/repo"
  default     = "SantiagoAlbi/Finops"
}

variable "cost_anomaly_threshold" {   #ver si sobra
  type        = string
  description = "Cost anomaly threshold percentage"
  default     = "30"
}
