# Outputs for ECS Module

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.app.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "service_arn" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.app.id
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "task_definition_family" {
  description = "Family of the task definition"
  value       = aws_ecs_task_definition.app.family
}

output "task_definition_revision" {
  description = "Revision of the task definition"
  value       = aws_ecs_task_definition.app.revision
}

output "task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "task_role_arn" {
  description = "ARN of the task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.arn
}

output "autoscaling_target_resource_id" {
  description = "Resource ID of the autoscaling target"
  value       = var.enable_autoscaling ? aws_appautoscaling_target.ecs_target[0].resource_id : null
}

output "autoscaling_policy_cpu_arn" {
  description = "ARN of the CPU autoscaling policy"
  value       = var.enable_autoscaling ? aws_appautoscaling_policy.ecs_policy_cpu[0].arn : null
}

output "autoscaling_policy_memory_arn" {
  description = "ARN of the memory autoscaling policy"
  value       = var.enable_autoscaling ? aws_appautoscaling_policy.ecs_policy_memory[0].arn : null
}

# Service information for other modules
output "service_info" {
  description = "ECS service information"
  value = {
    cluster_name    = aws_ecs_cluster.main.name
    service_name    = aws_ecs_service.app.name
    task_definition = aws_ecs_task_definition.app.arn
    container_name  = "app"
    container_port  = var.container_port
  }
}
