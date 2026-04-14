#!/bin/bash
set -e

echo "================================================"
echo "Setting up Terraform Remote Backend"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform is not installed. Please install it first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ AWS CLI and Terraform are installed${NC}"
echo ""

# Configure AWS credentials if not already configured
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo -e "${YELLOW}AWS credentials not found in environment variables${NC}"
    echo "Please enter your AWS credentials:"
    read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
    read -sp "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
    echo ""
    read -sp "AWS Session Token (optional, press Enter to skip): " AWS_SESSION_TOKEN
    echo ""

    export AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY
    if [ -n "$AWS_SESSION_TOKEN" ]; then
        export AWS_SESSION_TOKEN
    fi
fi

echo -e "${GREEN}✓ AWS credentials configured${NC}"
echo ""

# Initialize and apply backend setup
echo "Initializing Terraform for backend setup..."
terraform init

echo ""
echo "Planning backend infrastructure..."
terraform plan -out=backend.tfplan

echo ""
read -p "Do you want to create the backend resources? (yes/no): " confirm

if [ "$confirm" == "yes" ]; then
    echo ""
    echo "Creating backend resources..."
    terraform apply backend.tfplan

    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}Backend setup completed successfully!${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Note the S3 bucket and DynamoDB table names from the output above"
    echo "2. Update the backend configuration in your environment files if needed"
    echo "3. Navigate to environments/staging or environments/production"
    echo "4. Run 'terraform init' to initialize with the remote backend"
    echo ""
else
    echo -e "${YELLOW}Backend setup cancelled${NC}"
    rm -f backend.tfplan
fi
