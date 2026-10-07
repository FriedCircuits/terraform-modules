mock_provider "aws" {}

variables {
  bucket_name = "example-backups"
}

run "unversioned_bucket" {
  command = plan

  assert {
    condition     = length(aws_s3_bucket_versioning.this) == 0 && length(aws_s3_bucket_lifecycle_configuration.this) == 0 && !aws_s3_bucket.this.force_destroy
    error_message = "A plain bucket must not enable versioning, lifecycle cleanup, or forced destruction."
  }
}

run "backup_cleanup" {
  command = plan
  variables {
    versioning_status = "Enabled"
    cleanup_rules = {
      backups = { prefix = "backups/" }
    }
  }

  assert {
    condition = alltrue([
      for rule in aws_s3_bucket_lifecycle_configuration.this[0].rule :
      rule.filter[0].prefix == "backups/" &&
      rule.noncurrent_version_expiration[0].noncurrent_days == 2 &&
      rule.expiration[0].expired_object_delete_marker == true
    ])
    error_message = "Cleanup must target the chosen prefix, expire old versions after two days, and remove orphan markers."
  }
}

run "reject_short_retention" {
  command = plan
  variables {
    cleanup_rules = { backups = { noncurrent_days = 1 } }
  }
  expect_failures = [var.cleanup_rules]
}
