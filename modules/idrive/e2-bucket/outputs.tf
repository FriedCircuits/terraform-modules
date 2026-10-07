output "bucket_name" {
  description = "Bucket name for backup clients."
  value       = aws_s3_bucket.this.id
}
