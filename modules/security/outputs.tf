# Outputs for Security Module

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.main.arn
}

output "kms_alias_name" {
  description = "Name of the KMS alias"
  value       = aws_kms_alias.main.name
}

output "kms_alias_arn" {
  description = "ARN of the KMS alias"
  value       = aws_kms_alias.main.arn
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS execution role"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_execution_role_name" {
  description = "Name of the ECS execution role"
  value       = aws_iam_role.ecs_execution_role.name
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_task_role_name" {
  description = "Name of the ECS task role"
  value       = aws_iam_role.ecs_task_role.name
}

output "app_config_secret_arn" {
  description = "ARN of the application configuration secret"
  value       = aws_secretsmanager_secret.app_config.arn
}

output "app_config_secret_name" {
  description = "Name of the application configuration secret"
  value       = aws_secretsmanager_secret.app_config.name
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = var.create_lambda_role ? aws_iam_role.lambda_execution_role[0].arn : null
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution role"
  value       = var.create_lambda_role ? aws_iam_role.lambda_execution_role[0].name : null
}

output "lambda_security_group_id" {
  description = "ID of the Lambda security group"
  value       = var.create_lambda_role && var.lambda_needs_vpc_access ? aws_security_group.lambda[0].id : null
}

# SSM Parameter ARNs
output "ssm_parameter_arns" {
  description = "ARNs of SSM parameters"
  value = {
    app_environment = aws_ssm_parameter.app_environment.arn
    aws_region      = aws_ssm_parameter.aws_region.arn
    s3_bucket       = aws_ssm_parameter.s3_bucket.arn
  }
}

# Security information for other modules
output "security_info" {
  description = "Security configuration information"
  value = {
    kms_key_id             = aws_kms_key.main.key_id
    kms_key_arn            = aws_kms_key.main.arn
    ecs_execution_role_arn = aws_iam_role.ecs_execution_role.arn
    ecs_task_role_arn      = aws_iam_role.ecs_task_role.arn
    app_config_secret_arn  = aws_secretsmanager_secret.app_config.arn
  }
  sensitive = true
}
