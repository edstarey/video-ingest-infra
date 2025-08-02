# Variables for Monitoring Module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

# Alert Configuration
variable "alert_email_addresses" {
  description = "List of email addresses for alerts"
  type        = list(string)
  default     = []
}

# Log Configuration
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

# ECS Configuration
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
}

# ALB Configuration
variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  type        = string
}

# RDS Configuration
variable "rds_instance_id" {
  description = "ID of the RDS instance"
  type        = string
}

# S3 Configuration
variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

# CloudFront Configuration
variable "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  type        = string
  default     = null
}

# Alarm Thresholds
variable "error_rate_threshold" {
  description = "Error rate threshold for alarms"
  type        = number
  default     = 10

  validation {
    condition     = var.error_rate_threshold >= 0
    error_message = "Error rate threshold must be non-negative."
  }
}

variable "disk_space_threshold" {
  description = "Disk space utilization threshold (percentage)"
  type        = number
  default     = 80

  validation {
    condition     = var.disk_space_threshold >= 0 && var.disk_space_threshold <= 100
    error_message = "Disk space threshold must be between 0 and 100."
  }
}

# Monitoring Features
variable "enable_disk_space_monitoring" {
  description = "Enable disk space monitoring"
  type        = bool
  default     = false
}

variable "enable_anomaly_detection" {
  description = "Enable CloudWatch anomaly detection"
  type        = bool
  default     = false
}

variable "instance_id" {
  description = "EC2 instance ID for disk space monitoring"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
