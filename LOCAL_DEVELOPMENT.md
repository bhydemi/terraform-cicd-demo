# Local Development Guide

## Quick Start for Local Development

The project defaults to the **dev** environment for local development. You can work directly without specifying environment variables.

### Simple Local Workflow

```bash
# Navigate to environments directory
cd environments

# Initialize Terraform (first time only)
terraform init

# Plan your changes (defaults to dev environment)
terraform plan

# Apply your changes
terraform apply

# View outputs
terraform output

# Destroy when done
terraform destroy
```

That's it! No need to specify `-var-file` or environment flags for local development.

## What Gets Created Locally

When you run `terraform apply` locally, it creates:

- **S3 Bucket**: `cicd-demo-app-dev-XXXXXXXX`
  - Tagged with `Environment=dev`
  - No versioning (cost optimization)

- **Lambda Function**: `cicd-demo-s3-processor-dev`
  - Log level: DEBUG (maximum verbosity)
  - Tagged with `Environment=dev`

## Testing Locally

After deployment:

```bash
# Get the bucket name
BUCKET_NAME=$(terraform output -raw bucket_name)

# Upload a test file
echo "Test at $(date)" > test.txt
aws s3 cp test.txt s3://$BUCKET_NAME/uploads/test.txt

# Watch Lambda logs
FUNCTION_NAME=$(terraform output -raw lambda_function_name)
aws logs tail /aws/lambda/$FUNCTION_NAME --follow
```

## Default Configuration

The dev environment uses these defaults (from `variables.tf`):

```hcl
environment              = "dev"           # Automatically set
aws_region              = "us-east-1"      # Default region
enable_bucket_versioning = false           # No versioning needed locally
lambda_log_level        = "INFO"           # Default log level
```

### Override Defaults

You can override any default when planning:

```bash
# Use different region
terraform plan -var="aws_region=us-west-2"

# Enable versioning for testing
terraform plan -var="enable_bucket_versioning=true"

# Increase log verbosity
terraform plan -var="lambda_log_level=DEBUG"
```

## CI/CD vs Local Development

### Local Development (You)
- **Environment**: Always `dev` by default
- **Control**: Manual `terraform apply`
- **Purpose**: Testing changes before pushing to GitHub
- **Command**:
  ```bash
  cd environments && terraform plan
  ```

### CI/CD (GitHub Actions)
- **Environment**: `staging` or `production` (explicit)
- **Control**: Automatic on merge to branches
- **Purpose**: Controlled deployments to staging/production
- **Trigger**:
  - Merge to `staging` branch → deploys to staging
  - Merge to `main` branch → deploys to production

## Workflow: Local → Staging → Production

### Step 1: Develop Locally

```bash
cd environments

# Make changes to main.tf or modules
vim main.tf

# Test locally with dev environment
terraform plan
terraform apply

# Upload test file and verify Lambda works
aws s3 cp test.txt s3://$(terraform output -raw bucket_name)/uploads/test.txt

# Check logs
aws logs tail /aws/lambda/$(terraform output -raw lambda_function_name) --follow
```

### Step 2: Push to Staging

```bash
# Commit your changes
git add .
git commit -m "feat: Add new feature"

# Push to staging branch
git checkout staging
git push origin staging

# GitHub Actions automatically:
# 1. Runs terraform plan for staging
# 2. Deploys to staging environment (on merge)
```

### Step 3: Promote to Production

```bash
# Create PR from staging to main on GitHub
# Review the production plan
# Merge to deploy to production
```

## Environment Comparison

| Aspect | Local Dev | CI/CD Staging | CI/CD Production |
|--------|-----------|---------------|------------------|
| **Trigger** | Manual `terraform apply` | Merge to `staging` branch | Merge to `main` branch |
| **Environment Tag** | `dev` | `staging` | `production` |
| **S3 Versioning** | Disabled | Disabled | **Enabled** |
| **Lambda Log Level** | INFO (default) | INFO | WARN |
| **Approval** | None | None | Optional (can add in GitHub) |
| **tfvars File** | Not needed (uses defaults) | `staging.tfvars` | `production.tfvars` |

## Cleaning Up Local Resources

When you're done testing locally:

```bash
cd environments
terraform destroy

# Confirm with: yes
```

This removes all dev-tagged resources from AWS.

## Advanced: Using Custom tfvars Locally

If you want to use a custom configuration file locally:

```bash
# Create a custom tfvars file
cat > my-local.tfvars <<EOF
environment              = "dev"
aws_region              = "us-west-2"
enable_bucket_versioning = true
lambda_log_level        = "DEBUG"
EOF

# Use it
terraform plan -var-file="my-local.tfvars"
terraform apply -var-file="my-local.tfvars"
```

## Troubleshooting

### "Error: No backend configuration"

If you see backend errors, you need to set up the backend first:

```bash
cd /Users/abdulhakeemoyaqoob/CICD/terraform-cicd-demo
./setup-backend.sh
```

### "Error: ExpiredToken"

Your AWS credentials have expired. Export fresh ones:

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_SESSION_TOKEN="your-token"
```

### "Error: Bucket already exists"

The bucket names include random suffixes, but if you get this error:

```bash
# Check what exists
aws s3 ls | grep cicd-demo

# Destroy existing resources
terraform destroy
```

### State Lock Issues

```bash
# Check locks
aws dynamodb scan --table-name terraform-cicd-demo-locks

# Force unlock if stuck
terraform force-unlock <LOCK_ID>
```

## Best Practices

1. ✅ **Always test locally first** before pushing to staging
2. ✅ **Use dev environment** for experimentation
3. ✅ **Clean up dev resources** when done to avoid costs
4. ✅ **Never manually apply** to staging/production (use CI/CD)
5. ✅ **Check terraform plan output** before applying

## Next Steps

Once you've tested locally and are satisfied:

1. Commit your changes
2. Push to `staging` branch
3. Create PR to verify staging deployment
4. Merge to `staging` to deploy
5. Create PR from `staging` to `main` for production
6. Review production plan carefully
7. Merge to deploy to production

---

**Happy coding! 🚀**

Remember: Local dev environment is your playground. Break things, test things, learn things!
