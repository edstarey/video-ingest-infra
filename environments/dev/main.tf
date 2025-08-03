# Development Environment Configuration

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Terraform Cloud backend configuration
  cloud {
    organization = "edstarey-video-ingest"

    workspaces {
      name = "video-ingest-dev"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = var.common_tags
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # Environment-specific configurations
  enable_multi_az    = false # Single AZ for dev to save costs
  enable_nat_gateway = true
  single_nat_gateway = true # Use single NAT gateway for cost optimization
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name            = var.project_name
  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  availability_zones      = var.availability_zones
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  database_subnet_cidrs   = var.database_subnet_cidrs
  enable_nat_gateway      = local.enable_nat_gateway
  single_nat_gateway      = local.single_nat_gateway
  enable_vpc_flow_logs    = var.enable_vpc_flow_logs
  flow_log_retention_days = var.cloudwatch_log_retention_days
  common_tags             = var.common_tags
}

# S3 Module
module "s3" {
  source = "../../modules/s3"

  project_name              = var.project_name
  environment               = var.environment
  bucket_name               = var.s3_bucket_name
  enable_versioning         = var.enable_s3_versioning
  enable_encryption         = var.enable_s3_encryption
  enable_lifecycle          = var.s3_lifecycle_enabled
  lifecycle_rules           = var.s3_lifecycle_rules
  enable_notifications      = false # Disabled for dev
  enable_cors               = true
  cors_allowed_origins      = ["http://localhost:3000", "https://*.${var.domain_name}"]
  enable_cloudwatch_metrics = var.enable_detailed_monitoring
  common_tags               = var.common_tags
}

# Security Groups
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ecs" {
  name_prefix = "${var.project_name}-${var.environment}-ecs-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ecs-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = var.common_tags
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  project_name                 = var.project_name
  environment                  = var.environment
  db_name                      = var.rds_database_name
  db_username                  = var.rds_username
  engine_version               = var.rds_engine_version
  instance_class               = var.rds_instance_class
  allocated_storage            = var.rds_allocated_storage
  max_allocated_storage        = var.rds_max_allocated_storage
  storage_encrypted            = var.enable_s3_encryption
  db_subnet_group_name         = module.vpc.database_subnet_group_name
  security_group_ids           = [aws_security_group.rds.id]
  multi_az                     = var.enable_rds_multi_az
  backup_retention_period      = var.rds_backup_retention_period
  backup_window                = var.rds_backup_window
  maintenance_window           = var.rds_maintenance_window
  deletion_protection          = var.enable_rds_deletion_protection
  monitoring_interval          = var.enable_detailed_monitoring ? 60 : 0
  performance_insights_enabled = var.enable_detailed_monitoring
  create_cloudwatch_alarms     = var.enable_cloudwatch_alarms
  common_tags                  = var.common_tags
}

# ECS Module
module "ecs" {
  source = "../../modules/ecs"

  project_name                   = var.project_name
  environment                    = var.environment
  aws_region                     = var.aws_region
  aws_account_id                 = local.account_id
  cluster_name                   = var.ecs_cluster_name
  service_name                   = var.ecs_service_name
  task_cpu                       = var.ecs_task_cpu
  task_memory                    = var.ecs_task_memory
  desired_count                  = var.ecs_desired_count
  container_image                = "nginx:latest" # Placeholder - will be updated with actual app image
  container_port                 = 8080
  private_subnet_ids             = module.vpc.private_subnet_ids
  security_group_ids             = [aws_security_group.ecs.id]
  s3_bucket_arn                  = module.s3.bucket_arn
  target_group_arn               = module.alb.target_group_arn
  enable_autoscaling             = true
  autoscaling_min_capacity       = var.ecs_min_capacity
  autoscaling_max_capacity       = var.ecs_max_capacity
  autoscaling_cpu_target         = var.ecs_target_cpu_utilization
  autoscaling_memory_target      = var.ecs_target_memory_utilization
  autoscaling_scale_in_cooldown  = var.ecs_scale_down_cooldown
  autoscaling_scale_out_cooldown = var.ecs_scale_up_cooldown
  log_retention_days             = var.cloudwatch_log_retention_days
  create_cloudwatch_alarms       = var.enable_cloudwatch_alarms
  common_tags                    = var.common_tags

  # Environment variables for the application
  environment_variables = [
    {
      name  = "ENVIRONMENT"
      value = var.environment
    },
    {
      name  = "AWS_REGION"
      value = var.aws_region
    },
    {
      name  = "S3_BUCKET"
      value = module.s3.bucket_id
    }
  ]

  # Secrets from Parameter Store/Secrets Manager
  secrets_from_parameter_store = [
    {
      name      = "DATABASE_URL"
      valueFrom = module.rds.db_secret_arn
    }
  ]
}

# Security Module
module "security" {
  source = "../../modules/security"

  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  aws_account_id     = local.account_id
  s3_bucket_arn      = module.s3.bucket_arn
  s3_bucket_name     = module.s3.bucket_id
  vpc_id             = module.vpc.vpc_id
  create_lambda_role = false # Set to true if Lambda functions are needed
  common_tags        = var.common_tags
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  project_name               = var.project_name
  environment                = var.environment
  alb_name                   = var.alb_name
  internal                   = var.alb_internal
  security_group_ids         = [aws_security_group.alb.id]
  subnet_ids                 = module.vpc.public_subnet_ids
  vpc_id                     = module.vpc.vpc_id
  enable_deletion_protection = var.enable_alb_deletion_protection
  idle_timeout               = var.alb_idle_timeout
  enable_http2               = var.enable_http2
  target_port                = 8080
  health_check_path          = "/health"
  ssl_certificate_arn        = var.certificate_arn != "" ? var.certificate_arn : null
  enable_ssl_redirect        = var.enable_ssl_redirect
  domain_name                = var.domain_name
  create_cloudwatch_alarms   = var.enable_cloudwatch_alarms
  common_tags                = var.common_tags
}



# API Gateway Module
module "api_gateway" {
  source = "../../modules/api-gateway"

  project_name             = var.project_name
  environment              = var.environment
  api_name                 = "${var.project_name}-${var.environment}-api"
  stage_name               = "v1"
  alb_dns_name             = module.alb.alb_dns_name
  authorization_type       = "NONE"
  api_key_required         = false
  throttling_rate_limit    = 1000
  throttling_burst_limit   = 2000
  enable_access_logging    = var.enable_detailed_monitoring
  enable_xray_tracing      = var.enable_detailed_monitoring
  log_retention_days       = var.cloudwatch_log_retention_days
  domain_name              = var.domain_name != "" ? "api.${var.domain_name}" : null
  certificate_arn          = var.certificate_arn != "" ? var.certificate_arn : null
  create_cloudwatch_alarms = var.enable_cloudwatch_alarms
  common_tags              = var.common_tags
}

# CloudFront Module
module "cloudfront" {
  source = "../../modules/cloudfront"

  project_name             = var.project_name
  environment              = var.environment
  s3_bucket_id             = module.s3.bucket_id
  s3_bucket_arn            = module.s3.bucket_arn
  s3_bucket_domain_name    = module.s3.bucket_domain_name
  alb_dns_name             = module.alb.alb_dns_name
  distribution_comment     = "CDN for ${var.project_name} ${var.environment}"
  aliases                  = var.domain_name != "" ? [var.domain_name] : []
  ssl_certificate_arn      = var.certificate_arn != "" ? var.certificate_arn : null
  price_class              = "PriceClass_100" # US and Europe only for dev
  enable_compression       = true
  default_ttl              = 86400
  video_default_ttl        = 86400
  create_cloudwatch_alarms = var.enable_cloudwatch_alarms
  common_tags              = var.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  project_name                 = var.project_name
  environment                  = var.environment
  aws_region                   = var.aws_region
  aws_account_id               = local.account_id
  alert_email_addresses        = [] # Add email addresses for alerts
  log_retention_days           = var.cloudwatch_log_retention_days
  ecs_cluster_name             = module.ecs.cluster_name
  ecs_service_name             = module.ecs.service_name
  alb_arn_suffix               = module.alb.alb_arn_suffix
  rds_instance_id              = module.rds.db_instance_id
  s3_bucket_name               = module.s3.bucket_id
  cloudfront_distribution_id   = module.cloudfront.distribution_id
  error_rate_threshold         = 10
  enable_disk_space_monitoring = false
  enable_anomaly_detection     = false
  common_tags                  = var.common_tags
}

# Placeholder outputs for modules that will be added later
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = module.api_gateway.stage_invoke_url
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.distribution_domain_name
}

output "monitoring_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = module.monitoring.dashboard_url
}

output "kms_key_id" {
  description = "KMS key ID"
  value       = module.security.kms_key_id
}

output "security_group_ids" {
  description = "Security group IDs"
  value = {
    alb = aws_security_group.alb.id
    ecs = aws_security_group.ecs.id
    rds = aws_security_group.rds.id
  }
}

# Complete infrastructure information
output "infrastructure_info" {
  description = "Complete infrastructure information"
  value = {
    vpc_id                   = module.vpc.vpc_id
    s3_bucket_name           = module.s3.bucket_id
    rds_endpoint             = module.rds.db_instance_endpoint
    ecs_cluster_name         = module.ecs.cluster_name
    alb_dns_name             = module.alb.alb_dns_name
    api_gateway_url          = module.api_gateway.stage_invoke_url
    cloudfront_domain_name   = module.cloudfront.distribution_domain_name
    monitoring_dashboard_url = module.monitoring.dashboard_url
  }
  sensitive = true
}
