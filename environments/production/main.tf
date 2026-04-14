terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "terraform-cicd-demo-state-bucket"
    key            = "env/production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-cicd-demo-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  environment = "production"
  common_tags = {
    Project     = "CICD Demo"
    Environment = local.environment
    ManagedBy   = "Terraform"
    Workspace   = terraform.workspace
  }
}

# Lambda function for processing S3 events
module "s3_processor_lambda" {
  source = "../../modules/lambda_function"

  function_name = "cicd-demo-s3-processor-${local.environment}"
  environment   = local.environment

  environment_variables = {
    LOG_LEVEL = "WARN"
  }

  tags = local.common_tags
}

# S3 bucket with Lambda notification
module "app_bucket" {
  source = "../../modules/s3_bucket"

  bucket_name         = "cicd-demo-app-${local.environment}-${random_id.bucket_suffix.hex}"
  environment         = local.environment
  enable_versioning   = true
  lambda_function_arn = module.s3_processor_lambda.function_arn
  notification_prefix = "uploads/"

  tags = local.common_tags

  depends_on = [module.s3_processor_lambda]
}

# Random suffix for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Update Lambda permissions after bucket is created
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.s3_processor_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.app_bucket.bucket_arn
}
