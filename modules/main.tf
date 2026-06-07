module "notifications" {
  source = "./modules/notifications"

  project_name = var.project_name
  environment  = var.environment
  alert_email  = var.alert_email
}

module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
}

module "iam" {
  source = "./modules/iam"

  project_name       = var.project_name
  environment        = var.environment
  dynamodb_table_arn = module.storage.table_arn
  sns_topic_arn      = module.notifications.topic_arn
}

module "monitoring" {
  source = "./modules/monitoring"

  project_name   = var.project_name
  environment    = var.environment
  retention_days = var.retention_days
  sns_topic_arn  = module.notifications.topic_arn
  aws_region     = var.aws_region
}

module "lambda" {
  source = "./modules/lambda"

  project_name               = var.project_name
  environment                = var.environment
  lambda_role_arn            = module.iam.lambda_role_arn
  sns_topic_arn              = module.notifications.topic_arn
  dynamodb_table_name        = module.storage.table_name
  anomaly_threshold          = var.anomaly_threshold
  historical_days            = var.historical_days
  snapshot_age_days          = var.snapshot_age_days
  cost_anomaly_log_group     = module.monitoring.cost_anomaly_log_group
  unused_resources_log_group = module.monitoring.unused_resources_log_group
}
