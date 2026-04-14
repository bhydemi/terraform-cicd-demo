#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 <environment> [action]"
    echo ""
    echo "Arguments:"
    echo "  environment    dev, staging, or production"
    echo "  action         plan, apply, or destroy (default: plan)"
    echo ""
    echo "Examples:"
    echo "  $0 dev plan"
    echo "  $0 staging plan"
    echo "  $0 production apply"
    echo "  $0 staging destroy"
    exit 1
}

# Check arguments
if [ $# -lt 1 ]; then
    usage
fi

ENVIRONMENT=$1
ACTION=${2:-plan}

# Validate environment
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
    echo -e "${RED}Error: Environment must be 'dev', 'staging', or 'production'${NC}"
    usage
fi

# Validate action
if [ "$ACTION" != "plan" ] && [ "$ACTION" != "apply" ] && [ "$ACTION" != "destroy" ]; then
    echo -e "${RED}Error: Action must be 'plan', 'apply', or 'destroy'${NC}"
    usage
fi

# Change to environments directory (shared template)
cd "environments"

# Set the tfvars file for the environment
TFVARS_FILE="${ENVIRONMENT}.tfvars"

if [ ! -f "$TFVARS_FILE" ]; then
    echo -e "${RED}Error: Configuration file not found: $TFVARS_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Terraform $ACTION for $ENVIRONMENT${NC}"
echo -e "${BLUE}Using: $TFVARS_FILE${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Initialize Terraform
echo -e "${YELLOW}Initializing Terraform...${NC}"
terraform init

# Run the specified action
case "$ACTION" in
    plan)
        echo -e "${YELLOW}Running terraform plan...${NC}"
        terraform plan -var-file="$TFVARS_FILE"
        ;;
    apply)
        echo -e "${YELLOW}Running terraform plan...${NC}"
        terraform plan -var-file="$TFVARS_FILE" -out=tfplan
        echo ""
        read -p "Do you want to apply these changes? (yes/no): " confirm
        if [ "$confirm" == "yes" ]; then
            echo -e "${YELLOW}Applying changes...${NC}"
            terraform apply tfplan
            rm -f tfplan
            echo ""
            echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
            echo ""
            echo "Outputs:"
            terraform output
        else
            echo -e "${YELLOW}Apply cancelled${NC}"
            rm -f tfplan
        fi
        ;;
    destroy)
        echo -e "${RED}WARNING: This will destroy all resources in $ENVIRONMENT${NC}"
        read -p "Type 'destroy' to confirm: " confirm
        if [ "$confirm" == "destroy" ]; then
            echo -e "${RED}Destroying resources...${NC}"
            terraform destroy -var-file="$TFVARS_FILE" -auto-approve
            echo -e "${GREEN}✓ Resources destroyed${NC}"
        else
            echo -e "${YELLOW}Destroy cancelled${NC}"
        fi
        ;;
esac

cd ..
