# CloudFront Module for CDN

# CloudFront Origin Access Identity for S3
resource "aws_cloudfront_origin_access_identity" "s3_oai" {
  comment = "OAI for ${var.project_name} ${var.environment} S3 bucket"
}

# S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = var.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.s3_oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${var.s3_bucket_arn}/*"
      }
    ]
  })
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  # S3 Origin for video content
  origin {
    domain_name = var.s3_bucket_domain_name
    origin_id   = "S3-${var.s3_bucket_id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_oai.cloudfront_access_identity_path
    }
  }

  # ALB Origin for API requests
  dynamic "origin" {
    for_each = var.alb_dns_name != null ? [1] : []
    content {
      domain_name = var.alb_dns_name
      origin_id   = "ALB-${var.project_name}-${var.environment}"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = var.alb_origin_protocol_policy
        origin_ssl_protocols   = ["TLSv1.2"]
      }

      # Custom headers for ALB origin
      dynamic "custom_header" {
        for_each = var.custom_headers
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = var.enable_ipv6
  comment             = var.distribution_comment
  default_root_object = var.default_root_object

  # Aliases (custom domain names)
  aliases = var.aliases

  # Default cache behavior for S3 content
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.s3_bucket_id}"

    forwarded_values {
      query_string = var.forward_query_string
      headers      = var.forward_headers

      cookies {
        forward = var.forward_cookies
      }
    }

    viewer_protocol_policy = var.viewer_protocol_policy
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
    compress               = var.enable_compression

    # Lambda@Edge functions
    dynamic "lambda_function_association" {
      for_each = var.lambda_function_associations
      content {
        event_type   = lambda_function_association.value.event_type
        lambda_arn   = lambda_function_association.value.lambda_arn
        include_body = lambda_function_association.value.include_body
      }
    }
  }

  # Cache behavior for API requests
  dynamic "ordered_cache_behavior" {
    for_each = var.alb_dns_name != null ? [1] : []
    content {
      path_pattern     = "/api/*"
      allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods   = ["GET", "HEAD", "OPTIONS"]
      target_origin_id = "ALB-${var.project_name}-${var.environment}"

      forwarded_values {
        query_string = true
        headers      = ["*"]

        cookies {
          forward = "all"
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
      compress               = true
    }
  }

  # Cache behavior for video files
  ordered_cache_behavior {
    path_pattern     = "*.mp4"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.s3_bucket_id}"

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = var.viewer_protocol_policy
    min_ttl                = var.video_min_ttl
    default_ttl            = var.video_default_ttl
    max_ttl                = var.video_max_ttl
    compress               = false
  }

  # Cache behavior for other video formats
  ordered_cache_behavior {
    path_pattern     = "*.{webm,avi,mov,wmv,flv,mkv}"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.s3_bucket_id}"

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = var.viewer_protocol_policy
    min_ttl                = var.video_min_ttl
    default_ttl            = var.video_default_ttl
    max_ttl                = var.video_max_ttl
    compress               = false
  }

  # Price class
  price_class = var.price_class

  # Restrictions
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  # SSL Certificate
  viewer_certificate {
    cloudfront_default_certificate = var.ssl_certificate_arn == null
    acm_certificate_arn           = var.ssl_certificate_arn
    ssl_support_method            = var.ssl_certificate_arn != null ? "sni-only" : null
    minimum_protocol_version      = var.ssl_certificate_arn != null ? var.minimum_protocol_version : null
  }

  # Custom error responses
  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code         = custom_error_response.value.error_code
      response_code      = custom_error_response.value.response_code
      response_page_path = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  # Logging
  dynamic "logging_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      include_cookies = var.logging_include_cookies
      bucket          = var.logging_bucket
      prefix          = var.logging_prefix
    }
  }

  # Web ACL
  web_acl_id = var.web_acl_id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-cloudfront"
  })
}

# Route 53 Records for custom domains
resource "aws_route53_record" "cloudfront" {
  count = length(var.aliases) > 0 && var.hosted_zone_id != null ? length(var.aliases) : 0

  zone_id = var.hosted_zone_id
  name    = var.aliases[count.index]
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cloudfront_origin_latency" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-cloudfront-origin-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "OriginLatency"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = var.origin_latency_threshold
  alarm_description   = "This metric monitors CloudFront origin latency"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_errors" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-cloudfront-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = var.error_4xx_threshold
  alarm_description   = "This metric monitors CloudFront 4XX error rate"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
  }

  tags = var.common_tags
}

resource "aws_cloudfront_monitoring_subscription" "main" {
  count = var.enable_real_time_metrics ? 1 : 0

  distribution_id = aws_cloudfront_distribution.main.id

  monitoring_subscription {
    realtime_metrics_subscription_config {
      realtime_metrics_subscription_status = "Enabled"
    }
  }
}
