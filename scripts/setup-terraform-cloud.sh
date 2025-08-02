#!/bin/bash

# Terraform Cloud Setup Script for Video Ingest Infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ORG_NAME="edstarey-video-ingest"
AWS_ACCOUNT_ID="205930623532"
GITHUB_REPO="edstarey/video-ingest-infra"

echo -e "${BLUE}🚀 Terraform Cloud Setup for Video Ingest Infrastructure${NC}"
echo -e "${BLUE}Organization: ${ORG_NAME}${NC}"
echo -e "${BLUE}AWS Account: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${BLUE}GitHub Repo: ${GITHUB_REPO}${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check if terraform CLI is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform CLI not found. Please install Terraform.${NC}"
    exit 1
fi

# Check if jq is installed (for JSON processing)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq not found. Installing jq for JSON processing...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install jq
    else
        echo -e "${RED}❌ Please install jq manually: https://stedolan.github.io/jq/download/${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo ""

# Step 1: Terraform Cloud Login
echo -e "${BLUE}🔐 Step 1: Terraform Cloud Authentication${NC}"
echo "Please log in to Terraform Cloud..."
echo "This will open a browser window for authentication."
echo ""
read -p "Press Enter to continue..."

terraform login

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Terraform Cloud login failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Successfully authenticated with Terraform Cloud${NC}"
echo ""

# Step 2: Get API Token
echo -e "${BLUE}🔑 Step 2: API Token Configuration${NC}"
echo "We need your Terraform Cloud API token for GitHub Actions integration."
echo ""
echo "To get your API token:"
echo "1. Go to: https://app.terraform.io/app/settings/tokens"
echo "2. Create a new token with description: 'GitHub Actions Integration'"
echo "3. Copy the token value"
echo ""
read -p "Enter your Terraform Cloud API token: " TF_API_TOKEN

if [ -z "$TF_API_TOKEN" ]; then
    echo -e "${RED}❌ API token is required${NC}"
    exit 1
fi

echo -e "${GREEN}✅ API token configured${NC}"
echo ""

# Step 3: AWS Credentials
echo -e "${BLUE}🔐 Step 3: AWS Credentials${NC}"
echo "Please provide your AWS credentials for infrastructure deployment."
echo ""
read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -s -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo ""

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo -e "${RED}❌ AWS credentials are required${NC}"
    exit 1
fi

echo -e "${GREEN}✅ AWS credentials configured${NC}"
echo ""

# Step 4: Domain Configuration
echo -e "${BLUE}🌐 Step 4: Domain Configuration${NC}"
echo "Do you have a custom domain for this deployment? (y/n)"
read -r HAS_DOMAIN

if [ "$HAS_DOMAIN" = "y" ] || [ "$HAS_DOMAIN" = "Y" ]; then
    echo "Enter your domain name (e.g., yourdomain.com):"
    read -r DOMAIN_NAME
    DEV_DOMAIN="api.video-ingest-dev.${DOMAIN_NAME}"
    STAGING_DOMAIN="api.video-ingest-staging.${DOMAIN_NAME}"
else
    DEV_DOMAIN="api.video-ingest-dev.example.com"
    STAGING_DOMAIN="api.video-ingest-staging.example.com"
    echo -e "${YELLOW}⚠️  Using example domains. Update these later in Terraform Cloud.${NC}"
fi

echo -e "${GREEN}✅ Domain configuration set${NC}"
echo -e "   Dev: ${DEV_DOMAIN}"
echo -e "   Staging: ${STAGING_DOMAIN}"
echo ""

# Step 5: Create workspace configuration files
echo -e "${BLUE}📝 Step 5: Creating workspace configurations...${NC}"

# Create dev workspace variables
cat > /tmp/dev-variables.json << EOF
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "aws_region",
      "value": "us-east-1",
      "category": "terraform",
      "hcl": false,
      "sensitive": false
    }
  }
}
EOF

# Create staging workspace variables
cat > /tmp/staging-variables.json << EOF
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "aws_region",
      "value": "us-east-1",
      "category": "terraform",
      "hcl": false,
      "sensitive": false
    }
  }
}
EOF

echo -e "${GREEN}✅ Workspace configurations created${NC}"
echo ""

# Step 6: GitHub Secrets Setup
echo -e "${BLUE}🔐 Step 6: GitHub Secrets Configuration${NC}"
echo "Setting up GitHub repository secrets..."

# Check if GitHub CLI is available
if command -v gh &> /dev/null; then
    echo -e "${YELLOW}Setting up GitHub secrets using GitHub CLI...${NC}"
    
    # Set GitHub secrets
    echo "$TF_API_TOKEN" | gh secret set TF_API_TOKEN --repo "$GITHUB_REPO"
    echo "$AWS_ACCESS_KEY_ID" | gh secret set AWS_ACCESS_KEY_ID --repo "$GITHUB_REPO"
    echo "$AWS_SECRET_ACCESS_KEY" | gh secret set AWS_SECRET_ACCESS_KEY --repo "$GITHUB_REPO"
    
    echo -e "${GREEN}✅ GitHub secrets configured automatically${NC}"
else
    echo -e "${YELLOW}⚠️  GitHub CLI not found. Please set up secrets manually:${NC}"
    echo ""
    echo "Go to: https://github.com/${GITHUB_REPO}/settings/secrets/actions"
    echo "Add these repository secrets:"
    echo ""
    echo "TF_API_TOKEN = ${TF_API_TOKEN}"
    echo "AWS_ACCESS_KEY_ID = ${AWS_ACCESS_KEY_ID}"
    echo "AWS_SECRET_ACCESS_KEY = [your-secret-key]"
    echo ""
    read -p "Press Enter after setting up GitHub secrets..."
fi

echo ""

# Step 7: Instructions for manual setup
echo -e "${BLUE}📋 Step 7: Manual Setup Instructions${NC}"
echo ""
echo -e "${YELLOW}Please complete the following steps manually in Terraform Cloud:${NC}"
echo ""
echo "1. 🏢 Create Organization:"
echo "   - Go to: https://app.terraform.io/"
echo "   - Create organization: ${ORG_NAME}"
echo ""
echo "2. 🏗️  Create Workspaces:"
echo "   a) Development Workspace:"
echo "      - Name: video-ingest-dev"
echo "      - VCS: GitHub (${GITHUB_REPO})"
echo "      - Working directory: environments/dev"
echo "      - Terraform version: 1.5.0"
echo ""
echo "   b) Staging Workspace:"
echo "      - Name: video-ingest-staging"
echo "      - VCS: GitHub (${GITHUB_REPO})"
echo "      - Working directory: environments/staging"
echo "      - Terraform version: 1.5.0"
echo ""
echo "3. 🔐 Configure Environment Variables (for each workspace):"
echo "   Environment Variables (Sensitive):"
echo "   - AWS_ACCESS_KEY_ID = ${AWS_ACCESS_KEY_ID}"
echo "   - AWS_SECRET_ACCESS_KEY = [your-secret-key]"
echo "   - AWS_DEFAULT_REGION = us-east-1"
echo ""
echo "   Terraform Variables:"
echo "   - aws_region = \"us-east-1\""
echo "   - project_name = \"video-ingest\""
echo "   - domain_name = \"${DEV_DOMAIN}\" (for dev) / \"${STAGING_DOMAIN}\" (for staging)"
echo "   - s3_bucket_name = \"video-ingest-storage-dev-${AWS_ACCOUNT_ID}\" (for dev)"
echo "   - s3_bucket_name = \"video-ingest-storage-staging-${AWS_ACCOUNT_ID}\" (for staging)"
echo ""
echo "4. ⚙️  Configure Workspace Settings:"
echo "   - Execution Mode: Remote"
echo "   - Apply Method: Auto apply (for main branch)"
echo "   - Speculative Plans: Enabled"
echo ""

# Step 8: Verification
echo -e "${BLUE}🔍 Step 8: Verification${NC}"
echo ""
echo "After completing the manual setup, verify the integration:"
echo ""
echo "1. Create a test branch and PR"
echo "2. Check that Terraform Cloud runs speculative plans"
echo "3. Merge to main and verify auto-apply works"
echo ""

echo -e "${GREEN}🎉 Terraform Cloud setup preparation complete!${NC}"
echo ""
echo -e "${BLUE}📚 Next Steps:${NC}"
echo "1. Complete the manual setup steps above"
echo "2. Follow the detailed guide: docs/terraform-cloud-setup.md"
echo "3. Test the integration with a small change"
echo "4. Deploy your infrastructure!"
echo ""
echo -e "${BLUE}🔗 Useful Links:${NC}"
echo "- Terraform Cloud: https://app.terraform.io/"
echo "- GitHub Repository: https://github.com/${GITHUB_REPO}"
echo "- Setup Guide: docs/terraform-cloud-setup.md"
echo ""
echo -e "${GREEN}✅ Your video ingest infrastructure is ready for Terraform Cloud! 🚀${NC}"
