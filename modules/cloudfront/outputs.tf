# Outputs for CloudFront Module

output "distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.id
}

output "distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.arn
}

output "distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "distribution_hosted_zone_id" {
  description = "Hosted zone ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "distribution_status" {
  description = "Status of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.status
}

output "distribution_etag" {
  description = "ETag of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.etag
}

output "origin_access_identity_id" {
  description = "ID of the CloudFront Origin Access Identity"
  value       = aws_cloudfront_origin_access_identity.s3_oai.id
}

output "origin_access_identity_iam_arn" {
  description = "IAM ARN of the CloudFront Origin Access Identity"
  value       = aws_cloudfront_origin_access_identity.s3_oai.iam_arn
}

output "origin_access_identity_cloudfront_access_identity_path" {
  description = "CloudFront access identity path"
  value       = aws_cloudfront_origin_access_identity.s3_oai.cloudfront_access_identity_path
}

output "route53_record_names" {
  description = "Names of the Route 53 records"
  value       = length(var.aliases) > 0 && var.hosted_zone_id != null ? aws_route53_record.cloudfront[*].name : []
}

output "route53_record_fqdns" {
  description = "FQDNs of the Route 53 records"
  value       = length(var.aliases) > 0 && var.hosted_zone_id != null ? aws_route53_record.cloudfront[*].fqdn : []
}

# CloudFront information for other modules
output "cloudfront_info" {
  description = "CloudFront distribution information"
  value = {
    distribution_id   = aws_cloudfront_distribution.main.id
    domain_name      = aws_cloudfront_distribution.main.domain_name
    hosted_zone_id   = aws_cloudfront_distribution.main.hosted_zone_id
    aliases          = var.aliases
  }
}
