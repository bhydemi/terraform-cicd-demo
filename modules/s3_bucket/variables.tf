variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment name (staging/production)"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for the S3 bucket"
  type        = map(string)
  default     = {}
}

variable "lambda_function_arn" {
  description = "ARN of Lambda function to trigger on S3 events"
  type        = string
  default     = ""
}

variable "notification_prefix" {
  description = "Prefix filter for S3 notifications"
  type        = string
  default     = ""
}
