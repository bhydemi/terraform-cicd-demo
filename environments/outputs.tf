# Shared Outputs for All Environments

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.app_bucket.bucket_id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.app_bucket.bucket_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.s3_processor.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.s3_processor.lambda_function_arn
}

output "test_upload_command" {
  description = "Command to test S3 upload"
  value       = "aws s3 cp test.txt s3://${module.app_bucket.bucket_id}/uploads/test.txt"
}

output "view_logs_command" {
  description = "Command to view Lambda logs"
  value       = "aws logs tail /aws/lambda/${module.s3_processor.lambda_function_name} --follow"
}
