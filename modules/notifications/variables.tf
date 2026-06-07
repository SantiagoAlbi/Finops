variable "project_name" {
  type        = string
  description = "Project name prefix for all resources"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "alert_email" {
  type        = string
  description = "Email address to receive cost alerts"
}
