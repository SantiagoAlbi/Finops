resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-lambda-role"
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "cost_explorer_policy" {
  name        = "${var.project_name}-cost-explorer-policy"
  description = "Allow Lambda to query Cost Explorer API"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ce:GetCostAndUsage", "ce:GetCostForecast"]
        Resource = "*"
      }
    ]
  })

  tags = {
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "lambda_cost_explorer" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.cost_explorer_policy.arn
}

resource "aws_iam_policy" "dynamodb_policy" {
  name        = "${var.project_name}-dynamodb-policy"
  description = "Allow Lambda to write to DynamoDB cost history table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = var.dynamodb_table_arn
      }
    ]
  })

  tags = {
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

resource "aws_iam_policy" "sns_policy" {
  name        = "${var.project_name}-sns-policy"
  description = "Allow Lambda to publish to SNS topic"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arn
      }
    ]
  })

  tags = {
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "lambda_sns" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.sns_policy.arn
}

resource "aws_iam_policy" "ec2_read_policy" {
  name        = "${var.project_name}-ec2-read-policy"
  description = "Allow Lambda to describe EC2 resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeAddresses",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "rds:DescribeDBSnapshots"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_read" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.ec2_read_policy.arn
}

resource "aws_iam_policy" "cloudwatch_metrics_policy" {
  name        = "${var.project_name}-cloudwatch-metrics-policy"
  description = "Allow Lambda to publish custom metrics"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["cloudwatch:PutMetricData"]
        Resource = "*"
      }
    ]
  })

  tags = {
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_metrics" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.cloudwatch_metrics_policy.arn
}
