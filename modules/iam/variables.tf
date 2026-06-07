variable "project_name" {
  type        = string
  description = "Project name prefix for all resources"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "dynamodb_table_arn" {
  type        = string
  description = "ARN of the DynamoDB cost history table"
}

variable "sns_topic_arn" {
  type        = string
  description = "ARN of the SNS cost alerts topic"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in format owner/repo"
}
