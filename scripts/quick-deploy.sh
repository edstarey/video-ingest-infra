#!/bin/bash

# Quick Deploy Script for Video Ingest Infrastructure
# AWS Account: 205930623532

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_ACCOUNT_ID="205930623532"
AWS_REGION="us-east-1"
PROJECT_NAME="video-ingest"

echo -e "${BLUE}🚀 Video Ingest Infrastructure Quick Deploy${NC}"
echo -e "${BLUE}AWS Account: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${BLUE}Region: ${AWS_REGION}${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install AWS CLI.${NC}"
    exit 1
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform not found. Please install Terraform >= 1.5.0.${NC}"
    exit 1
fi

# Check Make
if ! command -v make &> /dev/null; then
    echo -e "${RED}❌ Make not found. Please install Make.${NC}"
    exit 1
fi

# Verify AWS credentials
echo -e "${YELLOW}🔐 Verifying AWS credentials...${NC}"
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")

if [ "$CURRENT_ACCOUNT" != "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}❌ AWS credentials not configured or wrong account.${NC}"
    echo -e "${RED}   Expected: ${AWS_ACCOUNT_ID}${NC}"
    echo -e "${RED}   Current:  ${CURRENT_ACCOUNT}${NC}"
    echo -e "${YELLOW}   Please run: aws configure${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials verified${NC}"

# Check if we're in the right directory
if [ ! -f "Makefile" ] || [ ! -d "modules" ]; then
    echo -e "${RED}❌ Please run this script from the video-ingest-infra directory${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo ""

# Step 1: Configure environment
echo -e "${BLUE}📝 Step 1: Configuring environment...${NC}"

if [ ! -f "environments/dev/terraform.tfvars" ]; then
    echo -e "${YELLOW}Creating dev environment configuration...${NC}"
    cp terraform.tfvars.example environments/dev/terraform.tfvars
    
    # Update S3 bucket name with account ID (already done in the file)
    echo -e "${GREEN}✅ Configuration file created${NC}"
else
    echo -e "${GREEN}✅ Configuration file already exists${NC}"
fi

# Prompt for domain name
echo ""
echo -e "${YELLOW}🌐 Domain Configuration${NC}"
echo "Do you have a custom domain for this deployment? (y/n)"
read -r HAS_DOMAIN

if [ "$HAS_DOMAIN" = "y" ] || [ "$HAS_DOMAIN" = "Y" ]; then
    echo "Enter your domain name (e.g., yourdomain.com):"
    read -r DOMAIN_NAME
    
    # Update domain in terraform.tfvars
    sed -i.bak "s/api.video-ingest-dev.example.com/api.video-ingest-dev.${DOMAIN_NAME}/g" environments/dev/terraform.tfvars
    echo -e "${GREEN}✅ Domain configured: api.video-ingest-dev.${DOMAIN_NAME}${NC}"
else
    echo -e "${YELLOW}⚠️  Using default domain. You can update this later.${NC}"
fi

echo ""

# Step 2: Deploy backend
echo -e "${BLUE}🏗️  Step 2: Deploying backend infrastructure...${NC}"
echo "This will create the S3 bucket and DynamoDB table for Terraform state."
echo "Continue? (y/n)"
read -r CONTINUE

if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    exit 0
fi

cd shared

echo -e "${YELLOW}Initializing backend...${NC}"
terraform init

echo -e "${YELLOW}Planning backend deployment...${NC}"
terraform plan

echo -e "${YELLOW}Applying backend infrastructure...${NC}"
terraform apply -auto-approve

# Get backend configuration
BUCKET_NAME=$(terraform output -raw terraform_state_bucket_name)
TABLE_NAME=$(terraform output -raw terraform_locks_table_name)

echo -e "${GREEN}✅ Backend deployed successfully${NC}"
echo -e "${GREEN}   Bucket: ${BUCKET_NAME}${NC}"
echo -e "${GREEN}   Table:  ${TABLE_NAME}${NC}"

cd ..

# Step 3: Configure backend for dev environment
echo -e "${BLUE}⚙️  Step 3: Configuring backend for dev environment...${NC}"

cat > environments/dev/backend.conf << EOF
bucket         = "${BUCKET_NAME}"
key            = "environments/dev/terraform.tfstate"
region         = "${AWS_REGION}"
dynamodb_table = "${TABLE_NAME}"
encrypt        = true
EOF

echo -e "${GREEN}✅ Backend configuration created${NC}"

# Step 4: Deploy development environment
echo ""
echo -e "${BLUE}🚀 Step 4: Deploying development environment...${NC}"
echo -e "${YELLOW}This will take approximately 15-20 minutes.${NC}"
echo "Continue? (y/n)"
read -r CONTINUE

if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    exit 0
fi

echo -e "${YELLOW}Initializing development environment...${NC}"
make init ENV=dev

echo -e "${YELLOW}Planning development environment...${NC}"
make plan ENV=dev

echo -e "${YELLOW}Applying development environment...${NC}"
echo -e "${YELLOW}⏱️  This will take 15-20 minutes. Please be patient...${NC}"
make apply ENV=dev

# Step 5: Verify deployment
echo ""
echo -e "${BLUE}✅ Step 5: Verifying deployment...${NC}"

echo -e "${YELLOW}Running validation...${NC}"
make validate

echo -e "${YELLOW}Checking infrastructure status...${NC}"
make status ENV=dev

echo ""
echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}📊 Infrastructure Outputs:${NC}"
make outputs ENV=dev

echo ""
echo -e "${BLUE}📈 Monitoring Dashboard:${NC}"
echo "https://${AWS_REGION}.console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}#dashboards:name=${PROJECT_NAME}-dev-dashboard"

echo ""
echo -e "${BLUE}💰 Cost Estimation:${NC}"
echo "Run 'make cost ENV=dev' for detailed cost breakdown"
echo "Estimated daily cost: \$15-25 (~\$450-750/month)"

echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Deploy your video-ingest API to the ECS cluster"
echo "2. Deploy your video-ingest-UI frontend"
echo "3. Configure DNS (if using custom domain)"
echo "4. Set up SSL certificates"
echo "5. Configure monitoring alerts"

echo ""
echo -e "${GREEN}🚀 Your video ingest infrastructure is ready!${NC}"
