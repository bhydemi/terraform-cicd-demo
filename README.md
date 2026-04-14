# Terraform CI/CD Demo Project

A comprehensive demonstration of Infrastructure as Code (IaC) with Terraform, featuring:
- Reusable Terraform modules
- S3 buckets with Lambda event processing
- Remote state management (S3 + DynamoDB)
- Separate staging and production environments
- Automated CI/CD with GitHub Actions

## Project Structure

```
terraform-cicd-demo/
├── modules/
│   ├── s3_bucket/           # Reusable S3 bucket module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── lambda_function/     # Reusable Lambda function module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── lambda_function.py
├── environments/
│   ├── staging/             # Staging environment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── production/          # Production environment
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── .github/workflows/
│   ├── terraform-cicd.yml   # Main CI/CD workflow
│   └── terraform-destroy.yml # Destruction workflow
├── backend-setup.tf         # Remote backend setup
├── setup-backend.sh         # Backend setup script
├── deploy.sh                # Manual deployment script
└── README.md
```

## Architecture

This project demonstrates a serverless architecture on AWS:

**Staging Environment:**
- S3 bucket (tagged: staging)
- Lambda function for S3 event processing
- No versioning (cost optimization)
- INFO log level

**Production Environment:**
- S3 bucket (tagged: production)
- Lambda function for S3 event processing
- Versioning enabled (data protection)
- WARN log level

Both environments store Terraform state remotely in S3 with DynamoDB state locking.

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

## Quick Start

### Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd terraform-cicd-demo
```

### Step 2: Set Up AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-session-token"  # If using temporary credentials
export AWS_REGION="us-east-1"
```

### Step 3: Set Up Remote Backend

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
- S3 bucket: `terraform-cicd-demo-state-bucket`
- DynamoDB table: `terraform-cicd-demo-locks`

### Step 4: Deploy to Staging

```bash
# Using the deployment script
./deploy.sh staging plan
./deploy.sh staging apply

# Or manually
cd environments/staging
terraform init
terraform plan
terraform apply
```

### Step 5: Deploy to Production

```bash
# Using the deployment script
./deploy.sh production plan
./deploy.sh production apply

# Or manually
cd environments/production
terraform init
terraform plan
terraform apply
```

## GitHub Actions CI/CD Setup

### 1. Add GitHub Secrets

Go to your repository Settings → Secrets and variables → Actions, and add:

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `AWS_SESSION_TOKEN`: Your AWS session token (if using temporary credentials)

### 2. CI/CD Workflow

The pipeline automatically:

**On Pull Request:**
- Runs `terraform fmt` check
- Runs `terraform validate`
- Runs `terraform plan` for both environments
- Comments the plan output on the PR

**On Push to Main:**
- Runs all checks
- Applies changes to staging first
- Then applies to production
- Updates GitHub deployment status

### 3. Manual Workflows

**Deploy Manually:**
```bash
# Go to Actions → Terraform CI/CD Pipeline → Run workflow
# Select environment and trigger
```

**Destroy Resources:**
```bash
# Go to Actions → Terraform Destroy → Run workflow
# Select environment and type "destroy" to confirm
```

## Testing the Demo

### 1. Verify Infrastructure

```bash
# Check staging outputs
cd environments/staging
terraform output

# Check production outputs
cd environments/production
terraform output
```

### 2. Test S3 Lambda Integration

```bash
# Get bucket name from output
BUCKET_NAME=$(terraform output -raw bucket_name)

# Upload a test file
echo "Hello from Terraform CI/CD Demo!" > test.txt
aws s3 cp test.txt s3://$BUCKET_NAME/uploads/test.txt

# Check Lambda logs
FUNCTION_NAME=$(terraform output -raw lambda_function_name)
aws logs tail /aws/lambda/$FUNCTION_NAME --follow
```

### 3. Verify S3 Event Triggers

Upload files to the S3 bucket and check Lambda CloudWatch logs to see the processing.

## Environment Differences

| Feature | Staging | Production |
|---------|---------|------------|
| S3 Versioning | Disabled | Enabled |
| Lambda Log Level | INFO | WARN |
| Tags | Environment=staging | Environment=production |
| State File | env/staging/terraform.tfstate | env/production/terraform.tfstate |

## Terraform Modules

### S3 Bucket Module

Creates an S3 bucket with:
- Server-side encryption (AES256)
- Public access blocking
- Optional versioning
- S3 event notifications to Lambda

**Usage:**
```hcl
module "app_bucket" {
  source = "../../modules/s3_bucket"

  bucket_name         = "my-app-bucket"
  environment         = "staging"
  enable_versioning   = false
  lambda_function_arn = module.lambda.function_arn
}
```

### Lambda Function Module

Creates a Lambda function with:
- IAM role and policies
- S3 read permissions
- CloudWatch Logs integration
- S3 invoke permissions

**Usage:**
```hcl
module "s3_processor" {
  source = "../../modules/lambda_function"

  function_name = "s3-event-processor"
  environment   = "staging"

  environment_variables = {
    LOG_LEVEL = "INFO"
  }
}
```

## State Management

Terraform state is stored remotely with the following structure:

```
S3 Bucket: terraform-cicd-demo-state-bucket
├── env/
│   ├── staging/
│   │   └── terraform.tfstate
│   └── production/
│       └── terraform.tfstate

DynamoDB Table: terraform-cicd-demo-locks
- Prevents concurrent modifications
- Automatic locking/unlocking
```

## Troubleshooting

### Backend Already Exists

If the S3 bucket or DynamoDB table already exists:

```bash
# Import existing resources
terraform import aws_s3_bucket.terraform_state terraform-cicd-demo-state-bucket
terraform import aws_dynamodb_table.terraform_locks terraform-cicd-demo-locks
```

### State Lock Errors

If state is locked:

```bash
# List locks
aws dynamodb scan --table-name terraform-cicd-demo-locks

# Force unlock (use carefully!)
terraform force-unlock <LOCK_ID>
```

### Lambda Permission Issues

If Lambda can't be triggered by S3:

```bash
# Check Lambda permissions
aws lambda get-policy --function-name <function-name>

# Re-apply to fix permissions
terraform apply
```

## Cleanup

### Destroy Staging

```bash
./deploy.sh staging destroy
```

### Destroy Production

```bash
./deploy.sh production destroy
```

### Destroy Backend

```bash
# This will remove state storage - do this last!
terraform destroy
```

## Best Practices Demonstrated

1. **Module Reusability**: Common infrastructure patterns in reusable modules
2. **Environment Separation**: Isolated state files for staging/production
3. **Remote State**: Centralized state storage with locking
4. **CI/CD Integration**: Automated testing and deployment
5. **Security**: Encrypted state, IAM roles, public access blocking
6. **Tagging**: Consistent resource tagging for cost tracking
7. **Documentation**: Comprehensive README and inline comments

## Learning Objectives

This demo covers concepts from Day 3 and Day 4:

**Day 3:**
- Infrastructure as Code fundamentals
- Terraform providers and resources
- State management
- Variables and outputs
- Lifecycle operations (init, plan, apply, destroy)

**Day 4:**
- Terraform modules
- Remote backend (S3 + DynamoDB)
- Multi-environment management
- GitHub Actions integration
- Secrets management

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is for educational purposes.

## Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)

---

Built with ❤️ for learning Terraform and CI/CD
