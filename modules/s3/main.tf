# S3 Module for Video Storage

# S3 bucket for video storage
resource "aws_s3_bucket" "video_storage" {
  bucket = var.bucket_name

  tags = merge(var.common_tags, {
    Name        = var.bucket_name
    Purpose     = "video-storage"
    Environment = var.environment
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "video_storage" {
  bucket = aws_s3_bucket.video_storage.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "video_storage" {
  bucket = aws_s3_bucket.video_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null ? true : false
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "video_storage" {
  bucket = aws_s3_bucket.video_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "video_storage" {
  count = var.enable_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.video_storage.id

  rule {
    id     = "video_lifecycle"
    status = "Enabled"

    filter {
      prefix = "videos/"
    }

    # Transition to Standard-IA
    transition {
      days          = var.lifecycle_rules.standard_to_ia_days
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier
    transition {
      days          = var.lifecycle_rules.ia_to_glacier_days
      storage_class = "GLACIER"
    }

    # Transition to Deep Archive
    transition {
      days          = var.lifecycle_rules.glacier_to_deep_archive_days
      storage_class = "DEEP_ARCHIVE"
    }

    # Expiration
    dynamic "expiration" {
      for_each = var.lifecycle_rules.expiration_days > 0 ? [1] : []
      content {
        days = var.lifecycle_rules.expiration_days
      }
    }

    # Non-current version expiration
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Abort incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # Rule for cleaning up old multipart uploads
  rule {
    id     = "cleanup_multipart"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# S3 bucket notification configuration
resource "aws_s3_bucket_notification" "video_storage" {
  count = var.enable_notifications ? 1 : 0

  bucket = aws_s3_bucket.video_storage.id

  dynamic "lambda_function" {
    for_each = var.lambda_notifications
    content {
      lambda_function_arn = lambda_function.value.function_arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }

  dynamic "topic" {
    for_each = var.sns_notifications
    content {
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = topic.value.filter_prefix
      filter_suffix = topic.value.filter_suffix
    }
  }

  depends_on = [
    aws_lambda_permission.s3_invoke,
    aws_sns_topic_policy.s3_notification
  ]
}

# Lambda permission for S3 to invoke functions
resource "aws_lambda_permission" "s3_invoke" {
  for_each = var.enable_notifications ? { for idx, notif in var.lambda_notifications : idx => notif } : {}

  statement_id  = "AllowExecutionFromS3Bucket-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.video_storage.arn
}

# SNS topic policy for S3 notifications
resource "aws_sns_topic_policy" "s3_notification" {
  for_each = var.enable_notifications ? { for idx, notif in var.sns_notifications : idx => notif } : {}

  arn = each.value.topic_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = each.value.topic_arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = aws_s3_bucket.video_storage.arn
          }
        }
      }
    ]
  })
}

# S3 bucket CORS configuration
resource "aws_s3_bucket_cors_configuration" "video_storage" {
  count = var.enable_cors ? 1 : 0

  bucket = aws_s3_bucket.video_storage.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag", "x-amz-meta-custom-header"]
    max_age_seconds = 3000
  }
}

# S3 bucket logging
resource "aws_s3_bucket_logging" "video_storage" {
  count = var.access_log_bucket != null ? 1 : 0

  bucket = aws_s3_bucket.video_storage.id

  target_bucket = var.access_log_bucket
  target_prefix = "access-logs/${var.bucket_name}/"
}

# CloudWatch metric filters for S3 access logs (if logging is enabled)
resource "aws_cloudwatch_log_metric_filter" "s3_errors" {
  count = var.enable_cloudwatch_metrics ? 1 : 0

  name           = "${var.project_name}-${var.environment}-s3-errors"
  log_group_name = "/aws/s3/${var.bucket_name}"
  pattern        = "[timestamp, request_id, remote_ip, requester, request_id, operation, key, request_uri, http_status=4*, error_code, bytes_sent, object_size, total_time, turn_around_time, referrer, user_agent, version_id]"

  metric_transformation {
    name      = "S3Errors"
    namespace = "VideoIngest/S3"
    value     = "1"
  }
}
