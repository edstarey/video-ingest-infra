#!/bin/bash

# Git Setup Script for Video Ingest Infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Setting up Git repository for Video Ingest Infrastructure${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "Makefile" ] || [ ! -d "modules" ]; then
    echo -e "${RED}❌ Please run this script from the video-ingest-infra directory${NC}"
    exit 1
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git not found. Please install Git.${NC}"
    exit 1
fi

# Get GitHub repository URL
echo -e "${YELLOW}📝 Enter your GitHub repository URL:${NC}"
echo "Examples:"
echo "  HTTPS: https://github.com/YOUR-USERNAME/video-ingest-infra.git"
echo "  SSH:   git@github.com:YOUR-USERNAME/video-ingest-infra.git"
echo ""
read -p "Repository URL: " REPO_URL

if [ -z "$REPO_URL" ]; then
    echo -e "${RED}❌ Repository URL is required${NC}"
    exit 1
fi

# Initialize git if not already done
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}🔧 Initializing Git repository...${NC}"
    git init
    echo -e "${GREEN}✅ Git repository initialized${NC}"
else
    echo -e "${GREEN}✅ Git repository already exists${NC}"
fi

# Add remote origin
echo -e "${YELLOW}🔗 Adding remote origin...${NC}"
if git remote get-url origin &> /dev/null; then
    echo -e "${YELLOW}⚠️  Remote origin already exists. Updating...${NC}"
    git remote set-url origin "$REPO_URL"
else
    git remote add origin "$REPO_URL"
fi
echo -e "${GREEN}✅ Remote origin set to: $REPO_URL${NC}"

# Check if there are any files to commit
if [ -z "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️  No changes to commit${NC}"
else
    # Add all files
    echo -e "${YELLOW}📦 Adding all files...${NC}"
    git add .
    
    # Create commit
    echo -e "${YELLOW}💾 Creating initial commit...${NC}"
    git commit -m "Initial commit: Complete video ingest infrastructure

- 9 Terraform modules (VPC, S3, RDS, ECS, ALB, API Gateway, CloudFront, Security, Monitoring)
- Multi-environment support (dev/staging/prod)
- Comprehensive CI/CD with GitHub Actions
- Complete documentation and deployment guides
- Configured for AWS account 205930623532
- Automated deployment scripts and testing framework"
    
    echo -e "${GREEN}✅ Initial commit created${NC}"
fi

# Set main branch
echo -e "${YELLOW}🌿 Setting main branch...${NC}"
git branch -M main

# Check if remote repository has content
echo -e "${YELLOW}🔍 Checking remote repository...${NC}"
if git ls-remote --heads origin main | grep -q main; then
    echo -e "${YELLOW}⚠️  Remote repository has existing content${NC}"
    echo "Do you want to merge with existing content? (y/n)"
    read -r MERGE_EXISTING
    
    if [ "$MERGE_EXISTING" = "y" ] || [ "$MERGE_EXISTING" = "Y" ]; then
        echo -e "${YELLOW}🔄 Pulling existing content...${NC}"
        git pull origin main --allow-unrelated-histories
    fi
fi

# Push to GitHub
echo -e "${YELLOW}🚀 Pushing to GitHub...${NC}"
git push -u origin main

echo ""
echo -e "${GREEN}🎉 Successfully pushed to GitHub!${NC}"
echo ""
echo -e "${BLUE}📋 Repository Information:${NC}"
echo -e "Repository URL: $REPO_URL"
echo -e "Branch: main"
echo -e "Files pushed: $(git ls-files | wc -l) files"
echo ""
echo -e "${BLUE}🔗 Next Steps:${NC}"
echo "1. Visit your GitHub repository to verify the upload"
echo "2. Set up branch protection rules (recommended)"
echo "3. Configure GitHub Actions secrets for AWS deployment"
echo "4. Review and customize the CI/CD pipeline"
echo ""
echo -e "${BLUE}🔐 GitHub Actions Secrets to Configure:${NC}"
echo "- AWS_ACCESS_KEY_ID"
echo "- AWS_SECRET_ACCESS_KEY"
echo "- INFRACOST_API_KEY (optional, for cost estimation)"
echo ""
echo -e "${GREEN}✅ Your video ingest infrastructure is now on GitHub!${NC}"
