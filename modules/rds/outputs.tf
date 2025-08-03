# Outputs for RDS Module

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_hosted_zone_id" {
  description = "RDS instance hosted zone ID"
  value       = aws_db_instance.main.hosted_zone_id
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_instance_name" {
  description = "RDS instance database name"
  value       = aws_db_instance.main.db_name
}

output "db_instance_username" {
  description = "RDS instance username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_instance_address" {
  description = "RDS instance address"
  value       = aws_db_instance.main.address
}

output "db_instance_availability_zone" {
  description = "RDS instance availability zone"
  value       = aws_db_instance.main.availability_zone
}

output "db_instance_backup_retention_period" {
  description = "RDS instance backup retention period"
  value       = aws_db_instance.main.backup_retention_period
}

output "db_instance_backup_window" {
  description = "RDS instance backup window"
  value       = aws_db_instance.main.backup_window
}

output "db_instance_maintenance_window" {
  description = "RDS instance maintenance window"
  value       = aws_db_instance.main.maintenance_window
}

output "db_instance_multi_az" {
  description = "RDS instance Multi-AZ status"
  value       = aws_db_instance.main.multi_az
}

output "db_instance_storage_encrypted" {
  description = "RDS instance storage encryption status"
  value       = aws_db_instance.main.storage_encrypted
}

output "db_parameter_group_id" {
  description = "DB parameter group ID"
  value       = aws_db_parameter_group.main.id
}

output "db_parameter_group_arn" {
  description = "DB parameter group ARN"
  value       = aws_db_parameter_group.main.arn
}

output "db_option_group_id" {
  description = "DB option group ID"
  value       = aws_db_option_group.main.id
}

output "db_option_group_arn" {
  description = "DB option group ARN"
  value       = aws_db_option_group.main.arn
}

output "db_secret_arn" {
  description = "ARN of the database password secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_secret_name" {
  description = "Name of the database password secret"
  value       = aws_secretsmanager_secret.db_password.name
}

output "read_replica_id" {
  description = "Read replica instance ID"
  value       = var.create_read_replica ? aws_db_instance.read_replica[0].id : null
}

output "read_replica_endpoint" {
  description = "Read replica endpoint"
  value       = var.create_read_replica ? aws_db_instance.read_replica[0].endpoint : null
}

output "enhanced_monitoring_iam_role_arn" {
  description = "Enhanced monitoring IAM role ARN"
  value       = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
}

# Connection information for applications
output "connection_info" {
  description = "Database connection information"
  value = {
    host       = aws_db_instance.main.address
    port       = aws_db_instance.main.port
    database   = aws_db_instance.main.db_name
    username   = aws_db_instance.main.username
    secret_arn = aws_secretsmanager_secret.db_password.arn
  }
  sensitive = true
}
