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
  value       = module.s3_processor_lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.s3_processor_lambda.function_arn
}

output "environment" {
  description = "Deployment environment"
  value       = "staging"
}
