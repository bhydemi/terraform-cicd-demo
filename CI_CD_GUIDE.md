# CI/CD Guide - Super Simple!

## The Workflow (In Plain English)

### For Staging

```
PR to staging → Runs terraform plan → Shows plan in comment
      ↓
Merge PR → Runs terraform apply → Deploys to staging
```

### For Production

```
PR to main → Runs terraform plan → Shows plan in comment
      ↓
Merge PR → Runs terraform apply → Deploys to production
```

That's it! No complex dependencies, no multiple jobs, just simple automation.

## The Complete Workflow File

Here's the entire workflow (just 150 lines!):

```yaml
name: Terraform CI/CD

on:
  pull_request:
    branches: [staging, main]
  push:
    branches: [staging, main]

jobs:
  staging:
    # Runs on PRs to staging or pushes to staging
    # - On PR: shows terraform plan
    # - On push: deploys to staging

  production:
    # Runs on PRs to main or pushes to main
    # - On PR: shows terraform plan
    # - On push: deploys to production
```

## How Each Job Works

### Staging Job

1. **Checkout code**
2. **Setup Terraform**
3. **Configure AWS credentials**
4. **Run `terraform init`**
5. **Run `terraform plan -var-file="staging.tfvars"`**
6. **If PR**: Post plan as comment
7. **If Merge**: Run `terraform apply -var-file="staging.tfvars"`
8. **If Merge**: Show deployment summary

### Production Job

Exact same steps, but uses `production.tfvars` instead.

## What Happens When...

### You Open a PR to Staging

```bash
git checkout -b my-feature
git commit -am "Add cool feature"
git push origin my-feature
# Open PR to staging on GitHub
```

**GitHub Actions will:**
- Run terraform plan with staging.tfvars
- Post the plan output as a comment on your PR
- You can review what will be deployed

### You Merge to Staging

Click "Merge" button on GitHub

**GitHub Actions will:**
- Run terraform apply with staging.tfvars
- Deploy to staging environment
- Post summary with bucket and lambda names

### You Open a PR to Main (Production)

```bash
# From staging branch
# Create PR to main on GitHub
```

**GitHub Actions will:**
- Run terraform plan with production.tfvars
- Post the plan with ⚠️ WARNING
- You can review production changes

### You Merge to Main

Click "Merge" button on GitHub

**GitHub Actions will:**
- Run terraform apply with production.tfvars
- Deploy to production environment
- Post summary with bucket and lambda names

## No Manual Steps Required!

The workflow automatically:
- ✅ Detects which branch you're working with
- ✅ Uses the correct .tfvars file
- ✅ Plans on PRs, applies on merges
- ✅ Posts helpful comments and summaries

## Example PR Comment (Staging)

```
### Staging Plan

```
Terraform will perform the following actions:

  # module.app_bucket.aws_s3_bucket.this will be created
  + resource "aws_s3_bucket" "this" {
      + bucket = "cicd-demo-app-staging-a1b2c3d4"
      ...
    }

Plan: 5 to add, 0 to change, 0 to destroy.
```

Merge to deploy to staging.
```

## Example Deployment Summary (Production)

```
## Production Deployed 🚀
- Bucket: `cicd-demo-app-production-x1y2z3w4`
- Lambda: `cicd-demo-s3-processor-production`
```

## Manual Destroy (If Needed)

Go to GitHub → Actions → "Destroy Environment" → Run workflow

1. Select environment (staging or production)
2. Type "destroy" to confirm
3. Click "Run workflow"

The workflow will destroy all resources for that environment.

## Troubleshooting

### Workflow Not Running?

Check:
- Did you push to `staging` or `main` branch?
- Did you modify files in `environments/` or `modules/`?
- Are GitHub secrets configured?

### Plan Shows Errors?

- Check AWS credentials in GitHub secrets
- Verify AWS credentials haven't expired
- Check Terraform syntax in your code

### Apply Failed?

- Check AWS permissions
- Verify backend resources exist (S3 bucket, DynamoDB table)
- Check CloudWatch logs for errors

## GitHub Secrets Required

Go to Settings → Secrets and variables → Actions

Add these secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN` (if using temporary credentials)

## Quick Reference

| Action | Trigger | What Runs |
|--------|---------|-----------|
| Open PR to staging | Pull request | `terraform plan` (staging.tfvars) |
| Merge to staging | Push to staging | `terraform apply` (staging.tfvars) |
| Open PR to main | Pull request | `terraform plan` (production.tfvars) |
| Merge to main | Push to main | `terraform apply` (production.tfvars) |

## Tips

💡 **Always review the plan** in the PR comment before merging

💡 **Test in staging first** before promoting to production

💡 **Check deployment summaries** to verify correct resources were created

💡 **Monitor AWS console** after deployments to confirm everything works

---

**That's it!** The CI/CD is intentionally simple so you can understand and modify it easily. 🚀
