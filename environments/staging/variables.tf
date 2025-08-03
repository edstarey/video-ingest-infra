# Variables for Staging Environment
# Copy from dev/variables.tf and modify staging-specific defaults

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "video-ingest"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = null
}

# Networking Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16" # Different CIDR for staging
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
}

variable "database_subnet_cidrs" {
  description = "List of database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]
}

# S3 Configuration
variable "s3_bucket_name" {
  description = "Name of the S3 bucket for video storage"
  type        = string
}

variable "enable_s3_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "enable_s3_encryption" {
  description = "Enable S3 bucket encryption"
  type        = bool
  default     = true
}

variable "s3_lifecycle_enabled" {
  description = "Enable S3 lifecycle management"
  type        = bool
  default     = true
}

variable "s3_lifecycle_rules" {
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
    expiration_days              = 2555
  }
}

# RDS Configuration (staging-optimized)
variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small" # Larger than dev
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 50 # More storage for staging
}

variable "rds_max_allocated_storage" {
  description = "RDS maximum allocated storage in GB"
  type        = number
  default     = 200
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "rds_database_name" {
  description = "Name of the database"
  type        = string
  default     = "video_ingest"
}

variable "rds_username" {
  description = "Database username"
  type        = string
  default     = "postgres"
}

variable "enable_rds_multi_az" {
  description = "Enable RDS Multi-AZ deployment"
  type        = bool
  default     = true # Multi-AZ for staging
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 14 # Longer retention for staging
}

variable "rds_backup_window" {
  description = "RDS backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "rds_maintenance_window" {
  description = "RDS maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "enable_rds_deletion_protection" {
  description = "Enable RDS deletion protection"
  type        = bool
  default     = true # Protection enabled for staging
}

# ECS Configuration (staging-optimized)
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "video-ingest-cluster"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "video-ingest-api"
}

variable "ecs_task_cpu" {
  description = "CPU units for ECS task"
  type        = number
  default     = 512 # More CPU for staging
}

variable "ecs_task_memory" {
  description = "Memory for ECS task in MB"
  type        = number
  default     = 1024 # More memory for staging
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 2 # Multiple tasks for staging
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 5
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 2
}

variable "ecs_target_cpu_utilization" {
  description = "Target CPU utilization for auto scaling"
  type        = number
  default     = 70
}

variable "ecs_target_memory_utilization" {
  description = "Target memory utilization for auto scaling"
  type        = number
  default     = 80
}

variable "ecs_scale_up_cooldown" {
  description = "Scale up cooldown period in seconds"
  type        = number
  default     = 300
}

variable "ecs_scale_down_cooldown" {
  description = "Scale down cooldown period in seconds"
  type        = number
  default     = 300
}

# Load Balancer Configuration
variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "video-ingest-alb"
}

variable "alb_internal" {
  description = "Whether the ALB is internal"
  type        = bool
  default     = false
}

variable "enable_alb_deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = true # Protection enabled for staging
}

variable "alb_idle_timeout" {
  description = "ALB idle timeout in seconds"
  type        = number
  default     = 60
}

variable "enable_http2" {
  description = "Enable HTTP/2 on the ALB"
  type        = bool
  default     = true
}

# SSL/TLS Configuration
variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "api.video-ingest-staging.example.com"
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
  default     = ""
}

variable "enable_ssl_redirect" {
  description = "Enable HTTP to HTTPS redirect"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 30 # Longer retention for staging
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "video-ingest"
    Environment = "staging"
    Terraform   = "true"
  }
}
