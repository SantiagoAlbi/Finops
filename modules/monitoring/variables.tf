variable "project_name" {
  type        = string
  description = "Project name prefix for all resources"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 7
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN of the SNS topic for alerts"
}

variable "aws_region" {
  type        = string
  description = "AWS region for dashboard metrics"
}
