output "state_bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}

output "lock_table_name" {
  value = aws_dynamodb_table.tf_locks.name
}

output "kms_key_arn" {
  value = aws_kms_key.tf_state.arn
}
