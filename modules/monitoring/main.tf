# Monitoring Module for CloudWatch, Alarms, and Dashboards

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name         = "${var.project_name}-${var.environment}-alerts"
  display_name = "${var.project_name} ${var.environment} Alerts"

  tags = var.common_tags
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.aws_account_id
          }
        }
      }
    ]
  })
}

# SNS Topic Subscription for email alerts
resource "aws_sns_topic_subscription" "email_alerts" {
  count = length(var.alert_email_addresses)

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_addresses[count.index]
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.ecs_service_name, "ClusterName", var.ecs_cluster_name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Service Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Load Balancer Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id],
            [".", "DatabaseConnections", ".", "."],
            [".", "FreeStorageSpace", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "RDS Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", var.s3_bucket_name, "StorageType", "StandardStorage"],
            [".", "NumberOfObjects", ".", ".", ".", "AllStorageTypes"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "S3 Metrics"
          period  = 86400
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 24
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", var.cloudfront_distribution_id],
            [".", "BytesDownloaded", ".", "."],
            [".", "4xxErrorRate", ".", "."],
            [".", "5xxErrorRate", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"  # CloudFront metrics are always in us-east-1
          title   = "CloudFront Metrics"
          period  = 300
        }
      }
    ]
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/application/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

# CloudWatch Metric Filters
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${var.project_name}-${var.environment}-error-count"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[timestamp, request_id, level=\"ERROR\", ...]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "warning_count" {
  name           = "${var.project_name}-${var.environment}-warning-count"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[timestamp, request_id, level=\"WARN\", ...]"

  metric_transformation {
    name      = "WarningCount"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1"
  }
}

# Custom CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.project_name}-${var.environment}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorCount"
  namespace           = "${var.project_name}/${var.environment}"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_rate_threshold
  alarm_description   = "This metric monitors application error rate"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "disk_space_low" {
  count = var.enable_disk_space_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-disk-space-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DiskSpaceUtilization"
  namespace           = "CWAgent"
  period              = "300"
  statistic           = "Average"
  threshold           = var.disk_space_threshold
  alarm_description   = "This metric monitors disk space utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_id
    device     = "/dev/xvda1"
    fstype     = "ext4"
    path       = "/"
  }

  tags = var.common_tags
}

# CloudWatch Composite Alarm for overall system health
resource "aws_cloudwatch_composite_alarm" "system_health" {
  alarm_name        = "${var.project_name}-${var.environment}-system-health"
  alarm_description = "Composite alarm for overall system health"

  alarm_rule = join(" OR ", [
    "ALARM(${var.project_name}-${var.environment}-ecs-cpu-high)",
    "ALARM(${var.project_name}-${var.environment}-ecs-memory-high)",
    "ALARM(${var.project_name}-${var.environment}-rds-cpu-utilization)",
    "ALARM(${var.project_name}-${var.environment}-alb-5xx-errors)",
    "ALARM(${var.project_name}-${var.environment}-high-error-rate)"
  ])

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = var.common_tags
}

# CloudWatch Insights Queries
resource "aws_cloudwatch_query_definition" "error_analysis" {
  name = "${var.project_name}-${var.environment}-error-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.application.name,
    "/ecs/${var.project_name}-${var.environment}"
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
EOF
}

resource "aws_cloudwatch_query_definition" "performance_analysis" {
  name = "${var.project_name}-${var.environment}-performance-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.application.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /response_time/
| stats avg(response_time) by bin(5m)
| sort @timestamp desc
EOF
}

# CloudWatch Anomaly Detector
resource "aws_cloudwatch_anomaly_detector" "request_count" {
  count = var.enable_anomaly_detection ? 1 : 0

  metric_math_anomaly_detector {
    metric_data_queries {
      id = "m1"
      metric_stat {
        metric {
          metric_name = "RequestCount"
          namespace   = "AWS/ApplicationELB"
          dimensions = {
            LoadBalancer = var.alb_arn_suffix
          }
        }
        period = 300
        stat   = "Sum"
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "request_count_anomaly" {
  count = var.enable_anomaly_detection ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-request-count-anomaly"
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  evaluation_periods  = "2"
  threshold_metric_id = "ad1"
  alarm_description   = "This metric monitors request count anomalies"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  metric_query {
    id = "ad1"
    anomaly_detector {
      metric_math_anomaly_detector {
        metric_data_queries {
          id = "m1"
          metric_stat {
            metric {
              metric_name = "RequestCount"
              namespace   = "AWS/ApplicationELB"
              dimensions = {
                LoadBalancer = var.alb_arn_suffix
              }
            }
            period = 300
            stat   = "Sum"
          }
        }
      }
    }
  }

  metric_query {
    id = "m1"
    metric_stat {
      metric {
        metric_name = "RequestCount"
        namespace   = "AWS/ApplicationELB"
        dimensions = {
          LoadBalancer = var.alb_arn_suffix
        }
      }
      period = 300
      stat   = "Sum"
    }
  }

  tags = var.common_tags
}
