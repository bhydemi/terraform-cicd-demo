# Environment Configuration

This directory contains the shared Terraform template and environment-specific configuration files.

## Structure

```
environments/
├── main.tf              # Shared infrastructure template
├── variables.tf         # Variable definitions
├── outputs.tf           # Output definitions
├── dev.tfvars          # Development environment config
├── staging.tfvars      # Staging environment config
└── production.tfvars   # Production environment config
```

## How It Works

Instead of having separate directories for each environment, we use a **single template** (`main.tf`) with **environment-specific variable files** (`.tfvars`).

### Benefits

- **DRY Principle**: No code duplication across environments
- **Consistency**: All environments use the same template
- **Easy Updates**: Change once, applies to all environments
- **Clear Differences**: Environment-specific settings are in one place

## Environments

### Development (Local)
```bash
./deploy.sh dev plan
./deploy.sh dev apply
```

**Configuration** (`dev.tfvars`):
- Environment tag: `dev`
- S3 versioning: Disabled (cost optimization)
- Lambda log level: `DEBUG` (maximum verbosity)
- Use case: Local development and testing

### Staging (GitHub Staging Branch)
```bash
./deploy.sh staging plan
./deploy.sh staging apply
```

**Configuration** (`staging.tfvars`):
- Environment tag: `staging`
- S3 versioning: Disabled (cost optimization)
- Lambda log level: `INFO` (detailed logging)
- Use case: Pre-production testing

### Production (GitHub Main Branch)
```bash
./deploy.sh production plan
./deploy.sh production apply
```

**Configuration** (`production.tfvars`):
- Environment tag: `production`
- S3 versioning: Enabled (data protection)
- Lambda log level: `WARN` (errors and warnings only)
- Use case: Live production environment

## Environment-Specific Settings

Each `.tfvars` file contains:

```hcl
environment              = "dev|staging|production"
aws_region              = "us-east-1"
enable_bucket_versioning = true|false
lambda_log_level        = "DEBUG|INFO|WARN|ERROR"
```

## Deployment Workflow

### Local Development Flow
1. Work in `dev` environment locally
2. Test changes: `./deploy.sh dev plan`
3. Deploy: `./deploy.sh dev apply`

### CI/CD Flow
1. Create feature branch
2. Open PR to `staging` branch → triggers staging plan
3. Merge to `staging` → auto-deploys to staging environment
4. Test in staging
5. Open PR from `staging` to `main` → triggers production plan
6. Merge to `main` → auto-deploys to production environment

## Adding a New Environment

To add a new environment (e.g., `qa`):

1. Update `variables.tf` validation:
```hcl
validation {
  condition     = contains(["dev", "staging", "qa", "production"], var.environment)
  error_message = "Environment must be dev, staging, qa, or production."
}
```

2. Create `qa.tfvars`:
```hcl
environment              = "qa"
aws_region              = "us-east-1"
enable_bucket_versioning = false
lambda_log_level        = "INFO"
```

3. Deploy:
```bash
./deploy.sh qa apply
```

## Terraform State

Each environment has its own state file in S3:
- `env/dev/terraform.tfstate`
- `env/staging/terraform.tfstate`
- `env/production/terraform.tfstate`

This prevents state conflicts between environments.

## Best Practices

1. **Always plan first**: Run `plan` before `apply`
2. **Use correct environment**: Double-check which `.tfvars` file you're using
3. **Test in dev first**: Validate changes locally before pushing
4. **Stage before production**: Always deploy to staging first
5. **Review plans carefully**: Especially for production deployments

## Troubleshooting

### Wrong environment deployed?
Check which `.tfvars` file was used in the command.

### State lock issues?
```bash
aws dynamodb scan --table-name terraform-cicd-demo-locks
terraform force-unlock <LOCK_ID>
```

### Resources in wrong environment?
Check the `environment` tag on AWS resources to identify which environment they belong to.
