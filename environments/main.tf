# Shared Environment Configuration Template
# This file is used by both staging and production environments

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "s3" {
    bucket         = "terraform-cicd-demo-state-bucket"
    key            = "env/${var.environment}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-cicd-demo-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CICD Demo"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Local variables
locals {
  environment = var.environment
  common_tags = {
    Project     = "CICD Demo"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Random suffix for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket Module
module "app_bucket" {
  source = "../modules/s3_bucket"

  bucket_name        = "cicd-demo-app-${local.environment}-${random_id.bucket_suffix.hex}"
  environment        = local.environment
  enable_versioning  = var.enable_bucket_versioning
  tags               = local.common_tags
  lambda_function_arn = module.s3_processor.lambda_function_arn
  notification_prefix = "uploads/"
}

# Lambda Function Module
module "s3_processor" {
  source = "../modules/lambda_function"

  function_name = "cicd-demo-s3-processor-${local.environment}"
  environment   = local.environment
  log_level     = var.lambda_log_level
  tags          = local.common_tags
}

# Grant Lambda permission to be invoked by S3
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = module.s3_processor.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.app_bucket.bucket_arn
}
