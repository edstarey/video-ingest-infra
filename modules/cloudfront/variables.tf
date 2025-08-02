# Variables for CloudFront Module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# S3 Origin Configuration
variable "s3_bucket_id" {
  description = "ID of the S3 bucket"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  type        = string
}

variable "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  type        = string
}

# ALB Origin Configuration
variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
  default     = null
}

variable "alb_origin_protocol_policy" {
  description = "Origin protocol policy for ALB"
  type        = string
  default     = "https-only"

  validation {
    condition     = contains(["http-only", "https-only", "match-viewer"], var.alb_origin_protocol_policy)
    error_message = "ALB origin protocol policy must be http-only, https-only, or match-viewer."
  }
}

variable "custom_headers" {
  description = "Custom headers to add to origin requests"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Distribution Configuration
variable "distribution_comment" {
  description = "Comment for the CloudFront distribution"
  type        = string
  default     = "CloudFront distribution for video content"
}

variable "default_root_object" {
  description = "Default root object for the distribution"
  type        = string
  default     = "index.html"
}

variable "enable_ipv6" {
  description = "Enable IPv6 for the distribution"
  type        = bool
  default     = true
}

variable "aliases" {
  description = "List of custom domain names (CNAMEs) for the distribution"
  type        = list(string)
  default     = []
}

# Cache Behavior Configuration
variable "viewer_protocol_policy" {
  description = "Viewer protocol policy"
  type        = string
  default     = "redirect-to-https"

  validation {
    condition     = contains(["allow-all", "https-only", "redirect-to-https"], var.viewer_protocol_policy)
    error_message = "Viewer protocol policy must be allow-all, https-only, or redirect-to-https."
  }
}

variable "forward_query_string" {
  description = "Forward query strings to the origin"
  type        = bool
  default     = false
}

variable "forward_headers" {
  description = "List of headers to forward to the origin"
  type        = list(string)
  default     = []
}

variable "forward_cookies" {
  description = "Cookie forwarding policy"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "all"], var.forward_cookies)
    error_message = "Forward cookies must be none, whitelist, or all."
  }
}

variable "enable_compression" {
  description = "Enable compression for the distribution"
  type        = bool
  default     = true
}

# TTL Configuration
variable "min_ttl" {
  description = "Minimum TTL for objects in seconds"
  type        = number
  default     = 0

  validation {
    condition     = var.min_ttl >= 0
    error_message = "Minimum TTL must be non-negative."
  }
}

variable "default_ttl" {
  description = "Default TTL for objects in seconds"
  type        = number
  default     = 86400

  validation {
    condition     = var.default_ttl >= 0
    error_message = "Default TTL must be non-negative."
  }
}

variable "max_ttl" {
  description = "Maximum TTL for objects in seconds"
  type        = number
  default     = 31536000

  validation {
    condition     = var.max_ttl >= 0
    error_message = "Maximum TTL must be non-negative."
  }
}

# Video-specific TTL Configuration
variable "video_min_ttl" {
  description = "Minimum TTL for video files in seconds"
  type        = number
  default     = 0
}

variable "video_default_ttl" {
  description = "Default TTL for video files in seconds"
  type        = number
  default     = 86400
}

variable "video_max_ttl" {
  description = "Maximum TTL for video files in seconds"
  type        = number
  default     = 31536000
}

# Price Class
variable "price_class" {
  description = "Price class for the distribution"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Price class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

# Geographic Restrictions
variable "geo_restriction_type" {
  description = "Type of geographic restriction"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "Geo restriction type must be none, whitelist, or blacklist."
  }
}

variable "geo_restriction_locations" {
  description = "List of country codes for geographic restrictions"
  type        = list(string)
  default     = []
}

# SSL Certificate Configuration
variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
  default     = null
}

variable "minimum_protocol_version" {
  description = "Minimum SSL protocol version"
  type        = string
  default     = "TLSv1.2_2021"

  validation {
    condition = contains([
      "SSLv3", "TLSv1", "TLSv1_2016", "TLSv1.1_2016", "TLSv1.2_2018", "TLSv1.2_2019", "TLSv1.2_2021"
    ], var.minimum_protocol_version)
    error_message = "Minimum protocol version must be a valid SSL/TLS version."
  }
}

# Custom Error Responses
variable "custom_error_responses" {
  description = "List of custom error response configurations"
  type = list(object({
    error_code            = number
    response_code         = number
    response_page_path    = string
    error_caching_min_ttl = number
  }))
  default = [
    {
      error_code            = 404
      response_code         = 404
      response_page_path    = "/404.html"
      error_caching_min_ttl = 300
    }
  ]
}

# Lambda@Edge Configuration
variable "lambda_function_associations" {
  description = "List of Lambda@Edge function associations"
  type = list(object({
    event_type   = string
    lambda_arn   = string
    include_body = bool
  }))
  default = []
}

# Logging Configuration
variable "enable_logging" {
  description = "Enable access logging for the distribution"
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "S3 bucket for access logs"
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "Prefix for access log files"
  type        = string
  default     = "cloudfront-access-logs/"
}

variable "logging_include_cookies" {
  description = "Include cookies in access logs"
  type        = bool
  default     = false
}

# WAF Configuration
variable "web_acl_id" {
  description = "ID of the WAF Web ACL"
  type        = string
  default     = null
}

# Route 53 Configuration
variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for custom domains"
  type        = string
  default     = null
}

# CloudWatch Monitoring
variable "enable_real_time_metrics" {
  description = "Enable real-time metrics for the distribution"
  type        = bool
  default     = false
}

variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for CloudFront metrics"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

variable "origin_latency_threshold" {
  description = "Origin latency threshold for CloudWatch alarm (milliseconds)"
  type        = number
  default     = 5000
}

variable "error_4xx_threshold" {
  description = "4XX error rate threshold for CloudWatch alarm (percentage)"
  type        = number
  default     = 5
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
