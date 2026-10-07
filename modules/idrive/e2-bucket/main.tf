resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = false
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.versioning_status == null ? 0 : 1
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_status
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.cleanup_rules) == 0 ? 0 : 1
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.cleanup_rules
    content {
      id     = rule.key
      status = "Enabled"

      filter {
        prefix = rule.value.prefix
      }

      noncurrent_version_expiration {
        noncurrent_days = rule.value.noncurrent_days
      }

      expiration {
        expired_object_delete_marker = true
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]

  lifecycle {
    # IDrive has no storage-class transitions and does not return this AWS default.
    ignore_changes = [transition_default_minimum_object_size]
  }
}
