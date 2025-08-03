# Outputs for API Gateway Module

output "api_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_arn" {
  description = "ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.main.arn
}

output "api_name" {
  description = "Name of the API Gateway"
  value       = aws_api_gateway_rest_api.main.name
}

output "api_root_resource_id" {
  description = "Root resource ID of the API Gateway"
  value       = aws_api_gateway_rest_api.main.root_resource_id
}

output "api_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.main.stage_name
}

output "stage_arn" {
  description = "ARN of the API Gateway stage"
  value       = aws_api_gateway_stage.main.arn
}

output "stage_invoke_url" {
  description = "Invoke URL of the API Gateway stage"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "deployment_id" {
  description = "ID of the API Gateway deployment"
  value       = aws_api_gateway_deployment.main.id
}

output "usage_plan_id" {
  description = "ID of the usage plan"
  value       = var.create_usage_plan ? aws_api_gateway_usage_plan.main[0].id : null
}

output "usage_plan_arn" {
  description = "ARN of the usage plan"
  value       = var.create_usage_plan ? aws_api_gateway_usage_plan.main[0].arn : null
}

output "api_key_id" {
  description = "ID of the API key"
  value       = var.create_api_key ? aws_api_gateway_api_key.main[0].id : null
}

output "api_key_value" {
  description = "Value of the API key"
  value       = var.create_api_key ? aws_api_gateway_api_key.main[0].value : null
  sensitive   = true
}

output "custom_domain_name" {
  description = "Custom domain name"
  value       = var.domain_name != null && var.certificate_arn != null ? aws_api_gateway_domain_name.main[0].domain_name : null
}

output "custom_domain_regional_domain_name" {
  description = "Regional domain name for custom domain"
  value       = var.domain_name != null && var.certificate_arn != null ? aws_api_gateway_domain_name.main[0].regional_domain_name : null
}

output "custom_domain_regional_zone_id" {
  description = "Regional zone ID for custom domain"
  value       = var.domain_name != null && var.certificate_arn != null ? aws_api_gateway_domain_name.main[0].regional_zone_id : null
}

output "route53_record_name" {
  description = "Name of the Route 53 record"
  value       = var.domain_name != null && var.hosted_zone_id != null && var.certificate_arn != null ? aws_route53_record.api[0].name : null
}

output "route53_record_fqdn" {
  description = "FQDN of the Route 53 record"
  value       = var.domain_name != null && var.hosted_zone_id != null && var.certificate_arn != null ? aws_route53_record.api[0].fqdn : null
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.enable_access_logging ? aws_cloudwatch_log_group.api_gateway[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = var.enable_access_logging ? aws_cloudwatch_log_group.api_gateway[0].arn : null
}

# API Gateway information for other modules
output "api_gateway_info" {
  description = "API Gateway information"
  value = {
    api_id      = aws_api_gateway_rest_api.main.id
    stage_name  = aws_api_gateway_stage.main.stage_name
    invoke_url  = aws_api_gateway_stage.main.invoke_url
    domain_name = var.domain_name != null && var.certificate_arn != null ? aws_api_gateway_domain_name.main[0].domain_name : null
  }
}
