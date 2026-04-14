# Quick Start Guide

This guide will get you up and running in under 10 minutes!

## Prerequisites Check

```bash
# Check Terraform
terraform version  # Should be >= 1.0

# Check AWS CLI
aws --version

# Check Git
git --version
```

## 1. Configure AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-aws-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-aws-secret-access-key"
export AWS_SESSION_TOKEN="your-aws-session-token"  # If using temporary credentials
export AWS_REGION="us-east-1"
```

> **Note:** Replace the placeholder values with your actual AWS credentials.

## 2. Initialize Git Repository

```bash
git init
git add .
git commit -m "Initial commit: Terraform CI/CD demo project"
```

## 3. Set Up Backend (One-Time Setup)

```bash
# Run automated setup
./setup-backend.sh

# Enter 'yes' when prompted
```

This creates:
- S3 bucket for state storage
- DynamoDB table for state locking

## 4. Deploy to Staging

```bash
./deploy.sh staging apply
```

When prompted, type `yes` to confirm.

## 5. Test the Deployment

```bash
# Navigate to staging environment
cd environments/staging

# Get outputs
terraform output

# Get bucket name
BUCKET_NAME=$(terraform output -raw bucket_name)

# Create a test file
echo "Testing S3 Lambda integration at $(date)" > test-file.txt

# Upload to S3
aws s3 cp test-file.txt s3://$BUCKET_NAME/uploads/test-file.txt

# Check Lambda logs
FUNCTION_NAME=$(terraform output -raw lambda_function_name)
aws logs tail /aws/lambda/$FUNCTION_NAME --since 5m
```

## 6. Deploy to Production

```bash
cd ../..  # Return to root directory
./deploy.sh production apply
```

## 7. Set Up GitHub CI/CD

### A. Create GitHub Repository

```bash
# Create a new repo on GitHub, then:
git remote add origin https://github.com/YOUR_USERNAME/terraform-cicd-demo.git
git branch -M main
git push -u origin main
```

### B. Add GitHub Secrets

1. Go to your repo on GitHub
2. Click Settings → Secrets and variables → Actions
3. Add these secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN`

### C. Test the Pipeline

```bash
# Create a test branch
git checkout -b test-deployment

# Make a small change
echo "# Test Change" >> README.md
git add README.md
git commit -m "Test: Trigger CI/CD pipeline"

# Push and create PR
git push -u origin test-deployment
```

Then create a Pull Request on GitHub and watch the pipeline run!

## 8. View Your Infrastructure

### In AWS Console:

1. **S3 Buckets**:
   - Search for "cicd-demo-app"
   - You'll see two buckets (staging and production)

2. **Lambda Functions**:
   - Go to Lambda console
   - Find "cicd-demo-s3-processor" functions

3. **DynamoDB**:
   - Check the `terraform-cicd-demo-locks` table

4. **CloudWatch Logs**:
   - View Lambda execution logs

### Using CLI:

```bash
# List S3 buckets
aws s3 ls | grep cicd-demo

# List Lambda functions
aws lambda list-functions --query 'Functions[?contains(FunctionName, `cicd-demo`)].FunctionName'

# View state file
aws s3 ls s3://terraform-cicd-demo-state-bucket/env/ --recursive
```

## 9. Clean Up (When Done)

```bash
# Destroy staging
./deploy.sh staging destroy

# Destroy production
./deploy.sh production destroy

# Destroy backend (do this last!)
terraform destroy
```

## Common Commands

```bash
# View current state
terraform show

# List all resources
terraform state list

# Refresh state
terraform refresh

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Get outputs
terraform output
```

## Troubleshooting

### Issue: "Error acquiring state lock"

```bash
# Check locks
aws dynamodb scan --table-name terraform-cicd-demo-locks

# Force unlock (get ID from error message)
terraform force-unlock <LOCK_ID>
```

### Issue: "Bucket already exists"

The bucket names include a random suffix. If you still get this error:

```bash
# Check existing buckets
aws s3 ls | grep cicd-demo

# Update the bucket name in the terraform code or destroy the old one
```

### Issue: "AccessDenied"

Check that your AWS credentials are still valid:

```bash
aws sts get-caller-identity
```

## Next Steps

1. Modify the Lambda function to do something custom
2. Add more resources (e.g., DynamoDB table, API Gateway)
3. Implement terraform workspaces
4. Add automated testing
5. Set up different AWS regions

## Demo Checklist

- [ ] Backend set up (S3 + DynamoDB)
- [ ] Staging environment deployed
- [ ] Production environment deployed
- [ ] Test file uploaded to S3
- [ ] Lambda logs verified
- [ ] GitHub repo created
- [ ] GitHub secrets configured
- [ ] CI/CD pipeline tested
- [ ] Infrastructure verified in AWS Console

## Congratulations!

You've successfully:
- Set up Infrastructure as Code with Terraform
- Created reusable modules
- Implemented remote state management
- Deployed to multiple environments
- Set up automated CI/CD with GitHub Actions

Now you can modify and expand this project for your own use cases!
