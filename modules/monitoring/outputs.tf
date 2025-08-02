# Outputs for Monitoring Module

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.name
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "application_log_group_name" {
  description = "Name of the application log group"
  value       = aws_cloudwatch_log_group.application.name
}

output "application_log_group_arn" {
  description = "ARN of the application log group"
  value       = aws_cloudwatch_log_group.application.arn
}

output "error_count_metric_filter_name" {
  description = "Name of the error count metric filter"
  value       = aws_cloudwatch_log_metric_filter.error_count.name
}

output "warning_count_metric_filter_name" {
  description = "Name of the warning count metric filter"
  value       = aws_cloudwatch_log_metric_filter.warning_count.name
}

output "high_error_rate_alarm_name" {
  description = "Name of the high error rate alarm"
  value       = aws_cloudwatch_metric_alarm.high_error_rate.alarm_name
}

output "high_error_rate_alarm_arn" {
  description = "ARN of the high error rate alarm"
  value       = aws_cloudwatch_metric_alarm.high_error_rate.arn
}

output "system_health_alarm_name" {
  description = "Name of the system health composite alarm"
  value       = aws_cloudwatch_composite_alarm.system_health.alarm_name
}

output "system_health_alarm_arn" {
  description = "ARN of the system health composite alarm"
  value       = aws_cloudwatch_composite_alarm.system_health.arn
}

output "error_analysis_query_name" {
  description = "Name of the error analysis CloudWatch Insights query"
  value       = aws_cloudwatch_query_definition.error_analysis.name
}

output "performance_analysis_query_name" {
  description = "Name of the performance analysis CloudWatch Insights query"
  value       = aws_cloudwatch_query_definition.performance_analysis.name
}

# Monitoring information for other modules
output "monitoring_info" {
  description = "Monitoring configuration information"
  value = {
    sns_topic_arn           = aws_sns_topic.alerts.arn
    dashboard_name          = aws_cloudwatch_dashboard.main.dashboard_name
    application_log_group   = aws_cloudwatch_log_group.application.name
    error_rate_alarm        = aws_cloudwatch_metric_alarm.high_error_rate.alarm_name
    system_health_alarm     = aws_cloudwatch_composite_alarm.system_health.alarm_name
  }
}
