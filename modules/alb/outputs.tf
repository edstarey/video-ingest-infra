# Outputs for ALB Module

output "alb_id" {
  description = "ID of the load balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the load balancer"
  value       = aws_lb.main.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "alb_hosted_zone_id" {
  description = "Hosted zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_id" {
  description = "ID of the target group"
  value       = aws_lb_target_group.app.id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app.arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group"
  value       = aws_lb_target_group.app.arn_suffix
}

output "target_group_name" {
  description = "Name of the target group"
  value       = aws_lb_target_group.app.name
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = var.ssl_certificate_arn != null ? aws_lb_listener.https[0].arn : null
}

output "route53_record_name" {
  description = "Name of the Route 53 record"
  value       = var.domain_name != null && var.hosted_zone_id != null ? aws_route53_record.alb[0].name : null
}

output "route53_record_fqdn" {
  description = "FQDN of the Route 53 record"
  value       = var.domain_name != null && var.hosted_zone_id != null ? aws_route53_record.alb[0].fqdn : null
}

# Load balancer information for other modules
output "load_balancer_info" {
  description = "Load balancer information"
  value = {
    dns_name         = aws_lb.main.dns_name
    zone_id          = aws_lb.main.zone_id
    target_group_arn = aws_lb_target_group.app.arn
    security_groups  = var.security_group_ids
  }
}
