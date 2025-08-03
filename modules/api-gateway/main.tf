# API Gateway Module

# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = var.api_name
  description = var.api_description

  endpoint_configuration {
    types = [var.endpoint_type]
  }

  # Binary media types for video uploads
  binary_media_types = var.binary_media_types

  tags = merge(var.common_tags, {
    Name = var.api_name
  })
}

# API Gateway Resource for proxy integration
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# API Gateway Method for proxy integration
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = var.authorization_type

  # API Key required if specified
  api_key_required = var.api_key_required

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# API Gateway Integration with ALB
resource "aws_api_gateway_integration" "alb" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.alb_dns_name}/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  timeout_milliseconds = var.integration_timeout
}

# API Gateway Method for root resource
resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = "ANY"
  authorization = var.authorization_type

  api_key_required = var.api_key_required
}

# API Gateway Integration for root resource
resource "aws_api_gateway_integration" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root.http_method

  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  uri                     = "http://${var.alb_dns_name}/"

  timeout_milliseconds = var.integration_timeout
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_integration.alb,
    aws_api_gateway_integration.root,
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_integration.alb.id,
      aws_api_gateway_method.root.id,
      aws_api_gateway_integration.root.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.stage_name

  # Note: Access logging configuration removed for compatibility
  # Can be added later via aws_api_gateway_method_settings

  # X-Ray tracing
  xray_tracing_enabled = var.enable_xray_tracing

  tags = var.common_tags
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  count = var.enable_access_logging ? 1 : 0

  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

# API Gateway Method Settings
resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    # Throttling
    throttling_rate_limit  = var.throttling_rate_limit
    throttling_burst_limit = var.throttling_burst_limit

    # Logging
    logging_level      = var.enable_access_logging ? "INFO" : "OFF"
    data_trace_enabled = var.enable_data_trace
    metrics_enabled    = var.enable_metrics

    # Caching
    caching_enabled      = var.enable_caching
    cache_ttl_in_seconds = var.cache_ttl_in_seconds
    # cache_key_parameters not supported in this context
  }
}

# API Gateway Usage Plan
resource "aws_api_gateway_usage_plan" "main" {
  count = var.create_usage_plan ? 1 : 0

  name        = "${var.project_name}-${var.environment}-usage-plan"
  description = "Usage plan for ${var.project_name} ${var.environment}"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  quota_settings {
    limit  = var.quota_limit
    period = var.quota_period
  }

  throttle_settings {
    rate_limit  = var.throttling_rate_limit
    burst_limit = var.throttling_burst_limit
  }

  tags = var.common_tags
}

# API Gateway API Key
resource "aws_api_gateway_api_key" "main" {
  count = var.create_api_key ? 1 : 0

  name        = "${var.project_name}-${var.environment}-api-key"
  description = "API key for ${var.project_name} ${var.environment}"
  enabled     = true

  tags = var.common_tags
}

# API Gateway Usage Plan Key
resource "aws_api_gateway_usage_plan_key" "main" {
  count = var.create_usage_plan && var.create_api_key ? 1 : 0

  key_id        = aws_api_gateway_api_key.main[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main[0].id
}

# Custom Domain Name (if provided)
resource "aws_api_gateway_domain_name" "main" {
  count = var.domain_name != null && var.certificate_arn != null ? 1 : 0

  domain_name              = var.domain_name
  regional_certificate_arn = var.certificate_arn
  security_policy          = var.security_policy

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.common_tags
}

# API Gateway Base Path Mapping
resource "aws_api_gateway_base_path_mapping" "main" {
  count = var.domain_name != null && var.certificate_arn != null ? 1 : 0

  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = aws_api_gateway_domain_name.main[0].domain_name
  base_path   = var.base_path
}

# Route 53 Record for Custom Domain
resource "aws_route53_record" "api" {
  count = var.domain_name != null && var.hosted_zone_id != null && var.certificate_arn != null ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.main[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.main[0].regional_zone_id
    evaluate_target_health = true
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "api_gateway_4xx_errors" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-api-gateway-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_4xx_threshold
  alarm_description   = "This metric monitors API Gateway 4XX errors"
  alarm_actions       = var.alarm_actions

  dimensions = {
    ApiName = aws_api_gateway_rest_api.main.name
    Stage   = aws_api_gateway_stage.main.stage_name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_errors" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-api-gateway-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_5xx_threshold
  alarm_description   = "This metric monitors API Gateway 5XX errors"
  alarm_actions       = var.alarm_actions

  dimensions = {
    ApiName = aws_api_gateway_rest_api.main.name
    Stage   = aws_api_gateway_stage.main.stage_name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_latency" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-api-gateway-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Average"
  threshold           = var.latency_threshold
  alarm_description   = "This metric monitors API Gateway latency"
  alarm_actions       = var.alarm_actions

  dimensions = {
    ApiName = aws_api_gateway_rest_api.main.name
    Stage   = aws_api_gateway_stage.main.stage_name
  }

  tags = var.common_tags
}
