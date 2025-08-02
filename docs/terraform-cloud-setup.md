# Terraform Cloud Setup Guide

## 🚀 Complete Setup for Video Ingest Infrastructure

This guide will walk you through setting up Terraform Cloud to manage your video ingest infrastructure with GitHub integration.

## 📋 Prerequisites

- ✅ GitHub repository: `https://github.com/edstarey/video-ingest-infra`
- ✅ AWS Account: `205930623532`
- ✅ Terraform Cloud account (we'll create this)

## Step 1: Create Terraform Cloud Account (5 minutes)

### 1.1 Sign Up for Terraform Cloud

1. **Go to**: https://app.terraform.io/signup
2. **Sign up with GitHub** (recommended for integration)
3. **Choose the Free tier** (sufficient for this project)
4. **Verify your email** address

### 1.2 Create Organization

1. **Organization name**: `edstarey-video-ingest`
2. **Email**: Your email address
3. **Choose**: "Start from scratch"

## Step 2: Create Workspaces (10 minutes)

### 2.1 Development Workspace

1. **Click**: "New workspace"
2. **Choose**: "Version control workflow"
3. **Connect to GitHub**: Authorize Terraform Cloud
4. **Select repository**: `edstarey/video-ingest-infra`
5. **Workspace settings**:
   - **Name**: `video-ingest-dev`
   - **Description**: "Development environment for video ingest infrastructure"
   - **Working directory**: `environments/dev`
   - **Terraform version**: `1.5.0`

### 2.2 Staging Workspace

1. **Click**: "New workspace"
2. **Choose**: "Version control workflow"
3. **Select repository**: `edstarey/video-ingest-infra`
4. **Workspace settings**:
   - **Name**: `video-ingest-staging`
   - **Description**: "Staging environment for video ingest infrastructure"
   - **Working directory**: `environments/staging`
   - **Terraform version**: `1.5.0`

## Step 3: Configure Environment Variables (15 minutes)

### 3.1 AWS Credentials (Both Workspaces)

For each workspace (`video-ingest-dev` and `video-ingest-staging`):

1. **Go to**: Workspace → Variables
2. **Add Environment Variables**:

```bash
# AWS Credentials (Environment Variables - Sensitive)
AWS_ACCESS_KEY_ID = your-aws-access-key-id
AWS_SECRET_ACCESS_KEY = your-aws-secret-access-key
AWS_DEFAULT_REGION = us-east-1

# Terraform Variables (Terraform Variables)
aws_region = "us-east-1"
project_name = "video-ingest"
```

### 3.2 Development Environment Variables

**Workspace**: `video-ingest-dev`

```hcl
# Terraform Variables
environment = "dev"
s3_bucket_name = "video-ingest-storage-dev-205930623532"
domain_name = "api.video-ingest-dev.yourdomain.com"
certificate_arn = ""
enable_detailed_monitoring = true
cloudwatch_log_retention_days = 14

# RDS Configuration
rds_instance_class = "db.t3.micro"
rds_allocated_storage = 20
enable_rds_multi_az = false
enable_rds_deletion_protection = false

# ECS Configuration
ecs_task_cpu = 256
ecs_task_memory = 512
ecs_desired_count = 1
ecs_max_capacity = 3
```

### 3.3 Staging Environment Variables

**Workspace**: `video-ingest-staging`

```hcl
# Terraform Variables
environment = "staging"
s3_bucket_name = "video-ingest-storage-staging-205930623532"
domain_name = "api.video-ingest-staging.yourdomain.com"
certificate_arn = ""
enable_detailed_monitoring = true
cloudwatch_log_retention_days = 30

# RDS Configuration
rds_instance_class = "db.t3.small"
rds_allocated_storage = 50
enable_rds_multi_az = true
enable_rds_deletion_protection = true

# ECS Configuration
ecs_task_cpu = 512
ecs_task_memory = 1024
ecs_desired_count = 2
ecs_max_capacity = 5
```

## Step 4: Configure GitHub Integration (10 minutes)

### 4.1 Generate Terraform Cloud API Token

1. **Go to**: User Settings → Tokens
2. **Create API token**:
   - **Description**: "GitHub Actions Integration"
   - **Copy the token** (you'll need it for GitHub)

### 4.2 Add GitHub Secrets

1. **Go to**: GitHub repository → Settings → Secrets and variables → Actions
2. **Add repository secrets**:

```bash
TF_API_TOKEN = your-terraform-cloud-api-token
AWS_ACCESS_KEY_ID = your-aws-access-key-id
AWS_SECRET_ACCESS_KEY = your-aws-secret-access-key
INFRACOST_API_KEY = your-infracost-api-key (optional)
```

### 4.3 Configure Workspace Settings

For each workspace:

1. **Go to**: Workspace → Settings → General
2. **Execution Mode**: "Remote"
3. **Apply Method**: "Auto apply" (for main branch) or "Manual apply" (for safety)
4. **VCS Settings**:
   - **Automatic speculative plans**: ✅ Enabled
   - **Automatic apply**: ✅ Enabled (for main branch only)

## Step 5: Configure Notifications (5 minutes)

### 5.1 Slack Integration (Optional)

1. **Go to**: Organization → Settings → Notification Configuration
2. **Add Slack webhook** for deployment notifications

### 5.2 Email Notifications

1. **Go to**: Workspace → Settings → Notifications
2. **Add email notifications** for:
   - ✅ Run state changes
   - ✅ Run errors
   - ✅ Policy check failures

## Step 6: Test the Integration (10 minutes)

### 6.1 Trigger First Plan

1. **Create a test branch**:
   ```bash
   git checkout -b test-terraform-cloud
   echo "# Test change" >> README.md
   git add README.md
   git commit -m "Test Terraform Cloud integration"
   git push origin test-terraform-cloud
   ```

2. **Create Pull Request** on GitHub
3. **Verify**: Terraform Cloud automatically runs speculative plan
4. **Check**: GitHub PR shows plan results

### 6.2 Test Deployment

1. **Merge the PR** to main branch
2. **Verify**: Terraform Cloud automatically runs apply
3. **Monitor**: Deployment progress in Terraform Cloud UI

## 🎯 Terraform Cloud Benefits

### **State Management**
- ✅ **Remote state** storage and locking
- ✅ **State versioning** and rollback capability
- ✅ **Team collaboration** with shared state

### **Security**
- ✅ **Encrypted state** storage
- ✅ **Secure variable** management
- ✅ **Audit logs** for all operations
- ✅ **RBAC** (Role-Based Access Control)

### **Workflow Automation**
- ✅ **GitHub integration** with automatic plans/applies
- ✅ **Policy as Code** with Sentinel (paid plans)
- ✅ **Cost estimation** for infrastructure changes
- ✅ **Drift detection** and remediation

### **Monitoring & Observability**
- ✅ **Web UI** for deployment tracking
- ✅ **Run history** and logs
- ✅ **Notifications** via Slack/email
- ✅ **Resource visualization**

## 📊 Workspace URLs

After setup, you'll have:

- **Development**: https://app.terraform.io/app/edstarey-video-ingest/workspaces/video-ingest-dev
- **Staging**: https://app.terraform.io/app/edstarey-video-ingest/workspaces/video-ingest-staging

## 🔧 CLI Configuration (Optional)

For local development:

```bash
# Install Terraform Cloud CLI
terraform login

# Configure workspace
terraform workspace select video-ingest-dev
```

## 🚨 Troubleshooting

### Common Issues:

1. **Authentication errors**: Check API token in GitHub secrets
2. **Permission denied**: Verify AWS credentials in workspace variables
3. **Plan failures**: Check Terraform syntax and variable configuration
4. **Apply timeouts**: Monitor AWS service limits and quotas

### Getting Help:

- **Terraform Cloud Docs**: https://developer.hashicorp.com/terraform/cloud-docs
- **GitHub Integration**: https://developer.hashicorp.com/terraform/cloud-docs/vcs/github
- **Support**: https://support.hashicorp.com/

## 🎉 Next Steps

After successful setup:

1. **Deploy development environment** via GitHub
2. **Monitor deployment** in Terraform Cloud UI
3. **Set up staging environment** promotion workflow
4. **Configure production workspace** (when ready)
5. **Implement policy as code** (paid plans)

Your infrastructure is now managed by Terraform Cloud with full GitHub integration! 🚀
