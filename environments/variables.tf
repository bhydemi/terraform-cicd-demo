# Shared Variables for All Environments

variable "environment" {
  description = "Environment name (dev, staging, or production)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be either 'dev', 'staging', or 'production'."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "enable_bucket_versioning" {
  description = "Enable versioning on S3 bucket"
  type        = bool
}

variable "lambda_log_level" {
  description = "Log level for Lambda function (INFO, WARN, ERROR)"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.lambda_log_level)
    error_message = "Log level must be DEBUG, INFO, WARN, or ERROR."
  }
}
