# Variables for S3 Module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be lowercase, start and end with alphanumeric characters, and can contain hyphens."
  }
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable S3 bucket encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for S3 bucket encryption (optional)"
  type        = string
  default     = null
}

variable "enable_lifecycle" {
  description = "Enable S3 lifecycle management"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "S3 lifecycle rules configuration"
  type = object({
    standard_to_ia_days          = number
    ia_to_glacier_days           = number
    glacier_to_deep_archive_days = number
    expiration_days              = number
  })
  default = {
    standard_to_ia_days          = 30
    ia_to_glacier_days           = 90
    glacier_to_deep_archive_days = 365
    expiration_days              = 2555 # 7 years
  }

  validation {
    condition = (
      var.lifecycle_rules.standard_to_ia_days > 0 &&
      var.lifecycle_rules.ia_to_glacier_days > var.lifecycle_rules.standard_to_ia_days &&
      var.lifecycle_rules.glacier_to_deep_archive_days > var.lifecycle_rules.ia_to_glacier_days
    )
    error_message = "Lifecycle transition days must be in ascending order and greater than 0."
  }
}

variable "enable_notifications" {
  description = "Enable S3 bucket notifications"
  type        = bool
  default     = false
}

variable "lambda_notifications" {
  description = "Lambda function notifications configuration"
  type = list(object({
    function_arn  = string
    function_name = string
    events        = list(string)
    filter_prefix = string
    filter_suffix = string
  }))
  default = []
}

variable "sns_notifications" {
  description = "SNS topic notifications configuration"
  type = list(object({
    topic_arn     = string
    events        = list(string)
    filter_prefix = string
    filter_suffix = string
  }))
  default = []
}

variable "enable_cors" {
  description = "Enable CORS configuration for the bucket"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "access_log_bucket" {
  description = "S3 bucket for access logs (optional)"
  type        = string
  default     = null
}

variable "enable_cloudwatch_metrics" {
  description = "Enable CloudWatch metrics for S3"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
