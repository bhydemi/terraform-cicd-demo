variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "environment" {
  description = "Environment name (staging/production)"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for Lambda function"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags for Lambda resources"
  type        = map(string)
  default     = {}
}

variable "source_bucket_arn" {
  description = "ARN of the S3 bucket that triggers this Lambda"
  type        = string
  default     = ""
}
