output "bucket_region" {
  description = "In which region S3 bucket will create"
  value       = var.region
}

output "state_bucket_name" {
  description = "bucket name with id"
  value       = module.s3_bucket.s3_bucket_id
}

output "dynamodb_table_name" {
  description = "dynamodb table name"
  value       = aws_dynamodb_table.dynamodb_table.id
}

