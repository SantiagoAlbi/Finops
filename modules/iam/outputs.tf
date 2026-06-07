output "lambda_role_arn" {
  value       = aws_iam_role.lambda_role.arn
  description = "ARN of the Lambda execution role"
}

output "lambda_role_name" {
  value       = aws_iam_role.lambda_role.name
  description = "Name of the Lambda execution role"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "ARN of the GitHub Actions OIDC role"
}
