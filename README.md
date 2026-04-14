# Terraform CI/CD Demo Project

A comprehensive demonstration of Infrastructure as Code (IaC) with Terraform, featuring:
- **Templated environments** with shared configuration
- **Local development** defaults to dev environment
- **CI/CD automation** for staging and production
- Reusable Terraform modules
- S3 buckets with Lambda event processing
- Remote state management (S3 + DynamoDB)
- Automated deployments with GitHub Actions

## Quick Start for Local Development

```bash
# 1. Set up AWS credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-token"  # if using temporary credentials

# 2. Set up backend (one-time)
./setup-backend.sh

# 3. Deploy to dev environment (defaults automatically)
cd environments
terraform init
terraform plan    # Defaults to dev environment
terraform apply   # Deploys dev resources

# 4. Test your deployment
BUCKET=$(terraform output -raw bucket_name)
echo "test" > test.txt
aws s3 cp test.txt s3://$BUCKET/uploads/test.txt

# Watch Lambda logs
aws logs tail /aws/lambda/$(terraform output -raw lambda_function_name) --follow
```

See [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md) for detailed local development workflow.

## Project Structure

```
terraform-cicd-demo/
├── modules/
│   ├── s3_bucket/              # Reusable S3 bucket module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── lambda_function/        # Reusable Lambda function module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── lambda_function.py
├── environments/
│   ├── main.tf                # Shared infrastructure template
│   ├── variables.tf           # Variable definitions (defaults to dev)
│   ├── outputs.tf             # Output definitions
│   ├── dev.tfvars            # Dev environment config
│   ├── staging.tfvars        # Staging environment config (used by CI/CD)
│   ├── production.tfvars     # Production environment config (used by CI/CD)
│   └── README.md             # Environment documentation
├── .github/workflows/
│   ├── terraform-cicd.yml    # Main CI/CD workflow
│   └── terraform-destroy.yml # Destruction workflow
├── backend-setup.tf          # Remote backend setup
├── setup-backend.sh          # Backend setup script
├── deploy.sh                 # Manual deployment script
├── LOCAL_DEVELOPMENT.md      # Local development guide
├── QUICKSTART.md             # Quick start guide
├── WORKFLOW.md               # CI/CD workflow documentation
└── README.md                 # This file
```

## Architecture

This project demonstrates a serverless architecture on AWS with three environments:

### Dev Environment (Local Development)
- **Trigger**: Manual `terraform apply`
- **S3 Bucket**: `cicd-demo-app-dev-XXXXXXXX` (tagged: dev)
- **Lambda Function**: `cicd-demo-s3-processor-dev`
- **Versioning**: Disabled (cost optimization)
- **Log Level**: INFO (default)
- **Purpose**: Local testing and development

### Staging Environment (CI/CD)
- **Trigger**: Merge to `staging` branch
- **S3 Bucket**: `cicd-demo-app-staging-XXXXXXXX` (tagged: staging)
- **Lambda Function**: `cicd-demo-s3-processor-staging`
- **Versioning**: Disabled (cost optimization)
- **Log Level**: INFO
- **Purpose**: Pre-production testing

### Production Environment (CI/CD)
- **Trigger**: Merge to `main` branch
- **S3 Bucket**: `cicd-demo-app-production-XXXXXXXX` (tagged: production)
- **Lambda Function**: `cicd-demo-s3-processor-production`
- **Versioning**: **Enabled** (data protection)
- **Log Level**: WARN (errors and warnings only)
- **Purpose**: Live production environment

All environments store Terraform state remotely in S3 with DynamoDB state locking.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/)
- AWS Account with appropriate permissions
- [Git](https://git-scm.com/)
- GitHub account (for CI/CD)

## AWS Credentials

You'll need the following AWS credentials:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN` (if using temporary credentials)

## Setup Guide

### Step 1: Clone the Repository

```bash
git clone https://github.com/bhydemi/terraform-cicd-demo.git
cd terraform-cicd-demo
```

### Step 2: Set Up AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"  # If using temporary credentials
export AWS_REGION="us-east-1"
```

### Step 3: Set Up Remote Backend (One-Time)

The remote backend stores Terraform state in S3 and uses DynamoDB for state locking.

```bash
# Run the automated setup script
./setup-backend.sh
```

Or manually:

```bash
# Initialize Terraform
terraform init

# Create backend resources
terraform plan -out=backend.tfplan
terraform apply backend.tfplan
```

This creates:
- **S3 bucket**: `terraform-cicd-demo-state-bucket`
  - Versioning enabled
  - Encryption enabled
  - Public access blocked
- **DynamoDB table**: `terraform-cicd-demo-locks`
  - Pay-per-request billing
  - Used for state locking

### Step 4: Local Development

The project defaults to **dev** environment for local work:

```bash
cd environments

# Initialize Terraform
terraform init

# Plan deployment (defaults to dev)
terraform plan

# Apply deployment
terraform apply

# View outputs
terraform output
```

**No need to specify `-var-file` for local development!**

See [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md) for full local development workflow.

### Step 5: Test Your Deployment

```bash
# Get bucket name
BUCKET_NAME=$(terraform output -raw bucket_name)

# Upload test file
echo "Testing S3 Lambda integration at $(date)" > test.txt
aws s3 cp test.txt s3://$BUCKET_NAME/uploads/test.txt

# Watch Lambda logs
FUNCTION_NAME=$(terraform output -raw lambda_function_name)
aws logs tail /aws/lambda/$FUNCTION_NAME --follow
```

Expected output in logs:
```
Processing S3 event in dev environment
Event: ObjectCreated:Put
Bucket: cicd-demo-app-dev-XXXXXXXX
Key: uploads/test.txt
Size: XX bytes
```

## Deployment Workflows

### Local Development Workflow

```
┌──────────────┐
│ Make Changes │
│  (in dev)    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│terraform plan│ ◄── Defaults to dev environment
└──────┬───────┘
       │
       ▼
┌───────────────┐
│terraform apply│ ◄── Deploy to dev
└──────┬────────┘
       │
       ▼
┌──────────────┐
│ Test Locally │
└──────────────┘
```

### CI/CD Workflow

```
┌──────────────┐
│Feature Branch│
└──────┬───────┘
       │
       ▼ (Create PR)
┌──────────────────┐
│ PR to staging    │ ──► Terraform plan (staging.tfvars)
└──────┬───────────┘
       │ (Merge)
       ▼
┌──────────────────┐
│ Staging Branch   │ ──► Auto-deploy to staging
└──────┬───────────┘
       │ (Test & Verify)
       ▼ (Create PR)
┌──────────────────┐
│ PR to main       │ ──► Terraform plan (production.tfvars)
└──────┬───────────┘
       │ (Merge)
       ▼
┌──────────────────┐
│ Main Branch      │ ──► Auto-deploy to production
└──────────────────┘
```

## CI/CD Setup

### Configure GitHub Secrets

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key ID |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret access key |
| `AWS_SESSION_TOKEN` | Your AWS session token (if using temporary credentials) |

### GitHub Actions Workflow

The workflow automatically:

**On Pull Request to `staging`:**
- Validates Terraform formatting
- Runs `terraform plan` with `staging.tfvars`
- Posts plan output as PR comment

**On Merge to `staging`:**
- Runs `terraform apply` with `staging.tfvars`
- Deploys to staging environment
- Posts deployment summary

**On Pull Request to `main`:**
- Validates Terraform formatting
- Runs `terraform plan` with `production.tfvars`
- Posts plan with production warning

**On Merge to `main`:**
- Runs `terraform apply` with `production.tfvars`
- Deploys to production environment
- Posts production deployment summary

## Environment Configuration

Each environment has different settings defined in `.tfvars` files:

### dev.tfvars (Local Development)
```hcl
environment              = "dev"
aws_region              = "us-east-1"
enable_bucket_versioning = false
lambda_log_level        = "INFO"
```

### staging.tfvars (CI/CD)
```hcl
environment              = "staging"
aws_region              = "us-east-1"
enable_bucket_versioning = false
lambda_log_level        = "INFO"
```

### production.tfvars (CI/CD)
```hcl
environment              = "production"
aws_region              = "us-east-1"
enable_bucket_versioning = true   # Data protection
lambda_log_level        = "WARN"  # Less verbose
```

## Module Usage

### S3 Bucket Module

```hcl
module "app_bucket" {
  source = "../modules/s3_bucket"

  bucket_name         = "my-bucket-name"
  environment         = "dev"
  enable_versioning   = false
  tags                = { Project = "Demo" }
  lambda_function_arn = module.my_lambda.lambda_function_arn
  notification_prefix = "uploads/"
}
```

### Lambda Function Module

```hcl
module "s3_processor" {
  source = "../modules/lambda_function"

  function_name = "my-lambda-function"
  environment   = "dev"
  log_level     = "INFO"
  tags          = { Project = "Demo" }
}
```

## Outputs

After deployment, Terraform provides useful outputs:

```bash
terraform output
```

Example output:
```
bucket_name = "cicd-demo-app-dev-a1b2c3d4"
lambda_function_name = "cicd-demo-s3-processor-dev"
test_upload_command = "aws s3 cp test.txt s3://cicd-demo-app-dev-a1b2c3d4/uploads/test.txt"
view_logs_command = "aws logs tail /aws/lambda/cicd-demo-s3-processor-dev --follow"
```

## Manual Deployment Script

For explicit environment control:

```bash
# Dev
./deploy.sh dev plan
./deploy.sh dev apply

# Staging
./deploy.sh staging plan
./deploy.sh staging apply

# Production
./deploy.sh production plan
./deploy.sh production apply
```

## Cleanup

### Destroy Dev Environment

```bash
cd environments
terraform destroy
```

### Destroy Staging/Production

```bash
./deploy.sh staging destroy
./deploy.sh production destroy
```

### Destroy Backend (Last!)

```bash
# From root directory
terraform destroy
```

## Troubleshooting

### AWS Credentials Expired

```bash
# Export fresh credentials
export AWS_ACCESS_KEY_ID="new-access-key"
export AWS_SECRET_ACCESS_KEY="new-secret-key"
export AWS_SESSION_TOKEN="new-token"

# Verify
aws sts get-caller-identity
```

### State Lock Issues

```bash
# Check current locks
aws dynamodb scan --table-name terraform-cicd-demo-locks

# Force unlock if stuck
terraform force-unlock <LOCK_ID>
```

### Wrong Environment Deployed

Check which `.tfvars` file was used or which environment variable was set.

For local development, it always defaults to dev unless you explicitly specify otherwise.

## Documentation

- [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md) - Detailed local development guide
- [QUICKSTART.md](QUICKSTART.md) - Quick setup and deployment
- [WORKFLOW.md](WORKFLOW.md) - CI/CD workflow details
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Project overview
- [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) - Complete setup guide
- [environments/README.md](environments/README.md) - Environment configuration

## Key Features

✅ **Templated Environments** - One template, multiple configurations
✅ **Local Development First** - Defaults to dev for quick iteration
✅ **CI/CD Automation** - Automatic deployments to staging and production
✅ **Reusable Modules** - DRY principle applied
✅ **Remote State Management** - S3 + DynamoDB locking
✅ **Security Best Practices** - Encryption, public access blocking, IAM roles
✅ **Cost Optimized** - AWS Free Tier eligible, <$1/month beyond free tier
✅ **Production Ready** - Versioning, logging, monitoring

## Contributing

1. Create a feature branch
2. Test locally in dev environment
3. Create PR to staging
4. Verify in staging
5. Create PR to main for production

## License

MIT License - Feel free to use this project for learning and demonstration purposes.

## Support

For issues or questions:
- Check the documentation files
- Review GitHub Issues
- Check GitHub Actions logs for CI/CD issues

---

**Built for learning DevOps, IaC, and CI/CD best practices** 🚀
