# Complete Setup Instructions

Follow these steps to set up and demo the Terraform CI/CD project.

## Prerequisites Checklist

- [ ] Terraform >= 1.0 installed
- [ ] AWS CLI installed and configured
- [ ] Git installed
- [ ] GitHub account created
- [ ] AWS account with appropriate permissions

## Part 1: Local Setup (15 minutes)

### Step 1: Configure AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-aws-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-aws-secret-access-key"
export AWS_SESSION_TOKEN="your-aws-session-token"  # If using temporary credentials
export AWS_REGION="us-east-1"
```

> **Important:** Replace the placeholder values above with your actual AWS credentials.

### Step 2: Verify AWS Access

```bash
aws sts get-caller-identity
```

Expected output should show your AWS account details.

### Step 3: Set Up Remote Backend

```bash
cd /Users/abdulhakeemoyaqoob/CICD/terraform-cicd-demo

# Run the automated setup script
./setup-backend.sh
```

When prompted:
1. Review the plan
2. Type `yes` to confirm
3. Note the S3 bucket and DynamoDB table names

**Expected Resources Created:**
- S3 bucket: `terraform-cicd-demo-state-bucket`
- DynamoDB table: `terraform-cicd-demo-locks`

### Step 4: Deploy to Staging Environment

```bash
# Plan the staging deployment
./deploy.sh staging plan

# Apply the staging deployment
./deploy.sh staging apply
```

When prompted, type `yes` to confirm.

**Expected Resources Created:**
- S3 bucket: `cicd-demo-app-staging-XXXXXXXX`
- Lambda function: `cicd-demo-s3-processor-staging`
- IAM role for Lambda
- Lambda permissions

### Step 5: Test Staging Deployment

```bash
cd environments/staging

# Get the bucket name
BUCKET_NAME=$(terraform output -raw bucket_name)
echo "Bucket: $BUCKET_NAME"

# Get the Lambda function name
FUNCTION_NAME=$(terraform output -raw lambda_function_name)
echo "Function: $FUNCTION_NAME"

# Create and upload a test file
echo "Test file uploaded at $(date)" > test-upload.txt
aws s3 cp test-upload.txt s3://$BUCKET_NAME/uploads/test-upload.txt

# Check Lambda logs (wait a few seconds first)
sleep 5
aws logs tail /aws/lambda/$FUNCTION_NAME --since 2m

cd ../..
```

**Expected Log Output:**
```
Processing S3 event in staging environment
Event: ObjectCreated:Put
Bucket: cicd-demo-app-staging-XXXXXXXX
Key: uploads/test-upload.txt
Size: XX bytes
```

### Step 6: Deploy to Production Environment

```bash
# Plan the production deployment
./deploy.sh production plan

# Apply the production deployment
./deploy.sh production apply
```

**Expected Resources Created:**
- S3 bucket: `cicd-demo-app-production-XXXXXXXX` (with versioning enabled)
- Lambda function: `cicd-demo-s3-processor-production`
- IAM role for Lambda
- Lambda permissions

### Step 7: Verify Both Environments

```bash
# List all S3 buckets
aws s3 ls | grep cicd-demo

# List all Lambda functions
aws lambda list-functions --query 'Functions[?contains(FunctionName, `cicd-demo`)].FunctionName'

# Check DynamoDB locks table
aws dynamodb describe-table --table-name terraform-cicd-demo-locks
```

## Part 2: GitHub Setup (10 minutes)

### Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `terraform-cicd-demo`
3. Make it public or private
4. Do NOT initialize with README
5. Click "Create repository"

### Step 2: Push Code to GitHub

```bash
cd /Users/abdulhakeemoyaqoob/CICD/terraform-cicd-demo

# Add GitHub remote
git remote add origin https://github.com/YOUR_USERNAME/terraform-cicd-demo.git

# Push both branches
git push -u origin staging
git checkout main
git merge staging
git push -u origin main
```

### Step 3: Configure GitHub Secrets

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

Add these three secrets:

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key ID |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret access key |
| `AWS_SESSION_TOKEN` | Your AWS session token (if using temporary credentials) |

### Step 4: Configure GitHub Environments (Optional)

1. Go to **Settings** → **Environments**
2. Click **New environment**
3. Name: `staging` → Click **Configure environment**
4. (Optional) Add protection rules
5. Repeat for `production` environment

**Recommended for Production:**
- Enable "Required reviewers"
- Add yourself or team members as reviewers

## Part 3: Test CI/CD Pipeline (15 minutes)

### Test 1: Feature Branch → Staging

```bash
# Create a feature branch
git checkout staging
git checkout -b feature/test-cicd

# Make a small change
echo "# CI/CD Test" >> README.md
git add README.md
git commit -m "test: Trigger CI/CD pipeline"

# Push to GitHub
git push origin feature/test-cicd
```

**Then on GitHub:**
1. Go to Pull Requests
2. Click "New pull request"
3. Base: `staging` ← Compare: `feature/test-cicd`
4. Click "Create pull request"

**Expected GitHub Actions:**
- ✅ Terraform validate runs
- ✅ Terraform plan for staging runs
- 💬 Plan output posted as comment
- ✅ All checks pass

**After Review:**
- Click "Merge pull request"
- Click "Confirm merge"

**Expected After Merge:**
- 🚀 Automatic deployment to staging
- 📊 Deployment summary in Actions tab

### Test 2: Staging → Production

```bash
# Create release branch
git checkout staging
git pull origin staging
git checkout -b release/v1.0.0

# Push to GitHub
git push origin release/v1.0.0
```

**Then on GitHub:**
1. Create Pull Request
2. Base: `main` ← Compare: `staging` (or `release/v1.0.0`)
3. Click "Create pull request"

**Expected GitHub Actions:**
- ✅ Terraform validate runs
- ✅ Terraform plan for production runs
- 💬 Plan output with ⚠️ production warning
- ✅ All checks pass

**After Review:**
- Click "Merge pull request"
- Click "Confirm merge"

**Expected After Merge:**
- 🚀 Automatic deployment to production
- 📊 Production deployment summary

### Test 3: Verify Deployments in AWS

```bash
# Check S3 buckets
aws s3 ls | grep cicd-demo

# Expected output:
# cicd-demo-app-staging-XXXXXXXX
# cicd-demo-app-production-XXXXXXXX
# terraform-cicd-demo-state-bucket

# Check Lambda functions
aws lambda list-functions \
  --query 'Functions[?contains(FunctionName, `cicd-demo`)].{Name:FunctionName, Runtime:Runtime}' \
  --output table

# Expected output:
# +-----------------------------------------+-------------+
# |              Name                       |   Runtime   |
# +-----------------------------------------+-------------+
# | cicd-demo-s3-processor-staging         | python3.11  |
# | cicd-demo-s3-processor-production      | python3.11  |
# +-----------------------------------------+-------------+

# Check tags on staging bucket
STAGING_BUCKET=$(aws s3 ls | grep "cicd-demo-app-staging" | awk '{print $3}')
aws s3api get-bucket-tagging --bucket $STAGING_BUCKET

# Expected output:
# "Environment": "staging"
# "ManagedBy": "Terraform"
# "Project": "CICD Demo"
```

## Part 4: Demonstration Scenarios

### Scenario 1: Show IaC Lifecycle

```bash
cd environments/staging

# Show current state
terraform show

# Show all resources
terraform state list

# Show specific resource
terraform state show module.app_bucket.aws_s3_bucket.this

# Refresh state
terraform refresh

# Show outputs
terraform output
```

### Scenario 2: Show Module Reusability

```bash
# Show S3 module used in both environments
cat modules/s3_bucket/main.tf

# Show Lambda module used in both environments
cat modules/lambda_function/main.tf

# Show how environments use the modules
cat environments/staging/main.tf
cat environments/production/main.tf
```

### Scenario 3: Show Remote State

```bash
# List state files in S3
aws s3 ls s3://terraform-cicd-demo-state-bucket/env/ --recursive

# Expected output:
# env/staging/terraform.tfstate
# env/production/terraform.tfstate

# Show state locking table
aws dynamodb scan \
  --table-name terraform-cicd-demo-locks \
  --max-items 5

# Download and view state file
aws s3 cp s3://terraform-cicd-demo-state-bucket/env/staging/terraform.tfstate - | jq '.version'
```

### Scenario 4: Show Environment Differences

```bash
# Compare staging and production configs
diff environments/staging/main.tf environments/production/main.tf

# Key differences to point out:
# - Environment tag
# - Versioning enabled/disabled
# - Log levels (INFO vs WARN)
```

### Scenario 5: Show CI/CD Automation

1. **GitHub Actions Tab**
   - Show workflow runs
   - Show deployment logs
   - Show deployment summaries

2. **Pull Request Comments**
   - Show automated plan comments
   - Show deployment status checks

3. **Deployment Environments**
   - Show staging environment
   - Show production environment
   - Show deployment history

## Part 5: Cleanup (Optional)

```bash
# Destroy staging environment
./deploy.sh staging destroy

# Destroy production environment
./deploy.sh production destroy

# Destroy backend (do this last!)
terraform destroy

# Verify all resources are deleted
aws s3 ls | grep cicd-demo
aws lambda list-functions --query 'Functions[?contains(FunctionName, `cicd-demo`)]'
aws dynamodb list-tables --query 'TableNames[?contains(@, `terraform-cicd-demo`)]'
```

## Troubleshooting

### Issue: AWS Credentials Invalid

```bash
# Check credentials
aws sts get-caller-identity

# If expired, get new credentials and update:
export AWS_ACCESS_KEY_ID="new-key"
export AWS_SECRET_ACCESS_KEY="new-secret"
export AWS_SESSION_TOKEN="new-token"

# Update GitHub secrets
```

### Issue: State Lock Error

```bash
# Check locks
aws dynamodb scan --table-name terraform-cicd-demo-locks

# Force unlock (get ID from error message)
terraform force-unlock <LOCK_ID>
```

### Issue: GitHub Actions Failing

1. Check secrets are set correctly
2. Verify AWS credentials haven't expired
3. Check workflow file syntax
4. Review error logs in Actions tab

### Issue: Lambda Not Triggering

```bash
# Check Lambda permissions
FUNCTION_NAME=$(terraform output -raw lambda_function_name)
aws lambda get-policy --function-name $FUNCTION_NAME

# Check S3 event notifications
BUCKET_NAME=$(terraform output -raw bucket_name)
aws s3api get-bucket-notification-configuration --bucket $BUCKET_NAME
```

## Validation Checklist

- [ ] Backend S3 bucket created
- [ ] Backend DynamoDB table created
- [ ] Staging S3 bucket created with correct tags
- [ ] Staging Lambda function created
- [ ] Production S3 bucket created with versioning
- [ ] Production Lambda function created
- [ ] Test file upload triggers Lambda in staging
- [ ] GitHub repository created
- [ ] GitHub secrets configured
- [ ] PR to staging triggers plan
- [ ] Merge to staging deploys automatically
- [ ] PR to main triggers production plan
- [ ] Merge to main deploys to production
- [ ] Both environments verified in AWS Console

## Success Criteria

✅ All infrastructure deployed successfully
✅ CI/CD pipeline running automatically
✅ State management working correctly
✅ Modules reused across environments
✅ Tags applied correctly to all resources
✅ S3-Lambda integration working
✅ GitHub Actions workflows passing

## Time Estimates

- Local Setup: 15 minutes
- GitHub Setup: 10 minutes
- CI/CD Testing: 15 minutes
- Total: **~40 minutes**

---

**You're ready to demo!** 🎉

For more details, see:
- [README.md](README.md) - Complete project documentation
- [QUICKSTART.md](QUICKSTART.md) - Quick reference guide
- [WORKFLOW.md](WORKFLOW.md) - Detailed workflow explanations
- [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Project overview
