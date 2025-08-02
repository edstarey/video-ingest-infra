# Variables for API Gateway Module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# API Gateway Configuration
variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "api_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = "API Gateway for video ingest service"
}

variable "endpoint_type" {
  description = "Type of API Gateway endpoint"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["EDGE", "REGIONAL", "PRIVATE"], var.endpoint_type)
    error_message = "Endpoint type must be EDGE, REGIONAL, or PRIVATE."
  }
}

variable "binary_media_types" {
  description = "List of binary media types supported by the API"
  type        = list(string)
  default     = ["*/*"]
}

# Stage Configuration
variable "stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "v1"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.stage_name))
    error_message = "Stage name must contain only alphanumeric characters, underscores, and hyphens."
  }
}

# Integration Configuration
variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "integration_timeout" {
  description = "Integration timeout in milliseconds"
  type        = number
  default     = 29000

  validation {
    condition     = var.integration_timeout >= 50 && var.integration_timeout <= 29000
    error_message = "Integration timeout must be between 50 and 29000 milliseconds."
  }
}

# Authorization Configuration
variable "authorization_type" {
  description = "Type of authorization for API methods"
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["NONE", "AWS_IAM", "CUSTOM", "COGNITO_USER_POOLS"], var.authorization_type)
    error_message = "Authorization type must be NONE, AWS_IAM, CUSTOM, or COGNITO_USER_POOLS."
  }
}

variable "api_key_required" {
  description = "Whether API key is required for requests"
  type        = bool
  default     = false
}

# Throttling Configuration
variable "throttling_rate_limit" {
  description = "API Gateway throttling rate limit (requests per second)"
  type        = number
  default     = 1000

  validation {
    condition     = var.throttling_rate_limit >= 0
    error_message = "Throttling rate limit must be non-negative."
  }
}

variable "throttling_burst_limit" {
  description = "API Gateway throttling burst limit"
  type        = number
  default     = 2000

  validation {
    condition     = var.throttling_burst_limit >= 0
    error_message = "Throttling burst limit must be non-negative."
  }
}

# Caching Configuration
variable "enable_caching" {
  description = "Enable API Gateway caching"
  type        = bool
  default     = false
}

variable "cache_ttl_in_seconds" {
  description = "Cache TTL in seconds"
  type        = number
  default     = 300

  validation {
    condition     = var.cache_ttl_in_seconds >= 0 && var.cache_ttl_in_seconds <= 3600
    error_message = "Cache TTL must be between 0 and 3600 seconds."
  }
}

variable "cache_key_parameters" {
  description = "List of cache key parameters"
  type        = list(string)
  default     = []
}

# Logging Configuration
variable "enable_access_logging" {
  description = "Enable API Gateway access logging"
  type        = bool
  default     = true
}

variable "enable_data_trace" {
  description = "Enable data trace logging"
  type        = bool
  default     = false
}

variable "enable_metrics" {
  description = "Enable detailed CloudWatch metrics"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch log retention period."
  }
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = true
}

# Usage Plan Configuration
variable "create_usage_plan" {
  description = "Create a usage plan for the API"
  type        = bool
  default     = true
}

variable "quota_limit" {
  description = "Maximum number of requests per quota period"
  type        = number
  default     = 10000

  validation {
    condition     = var.quota_limit >= 0
    error_message = "Quota limit must be non-negative."
  }
}

variable "quota_period" {
  description = "Quota period (DAY, WEEK, MONTH)"
  type        = string
  default     = "DAY"

  validation {
    condition     = contains(["DAY", "WEEK", "MONTH"], var.quota_period)
    error_message = "Quota period must be DAY, WEEK, or MONTH."
  }
}

# API Key Configuration
variable "create_api_key" {
  description = "Create an API key"
  type        = bool
  default     = false
}

# Custom Domain Configuration
variable "domain_name" {
  description = "Custom domain name for the API"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for custom domain"
  type        = string
  default     = null
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID for custom domain"
  type        = string
  default     = null
}

variable "base_path" {
  description = "Base path for API Gateway mapping"
  type        = string
  default     = null
}

variable "security_policy" {
  description = "Security policy for custom domain"
  type        = string
  default     = "TLS_1_2"

  validation {
    condition     = contains(["TLS_1_0", "TLS_1_2"], var.security_policy)
    error_message = "Security policy must be TLS_1_0 or TLS_1_2."
  }
}

# CloudWatch Alarms Configuration
variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for API Gateway metrics"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

variable "error_4xx_threshold" {
  description = "4XX error threshold for CloudWatch alarm"
  type        = number
  default     = 50
}

variable "error_5xx_threshold" {
  description = "5XX error threshold for CloudWatch alarm"
  type        = number
  default     = 10
}

variable "latency_threshold" {
  description = "Latency threshold for CloudWatch alarm (milliseconds)"
  type        = number
  default     = 5000
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
