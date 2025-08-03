# Deployment Strategy - Branch-Based Environments

## 🚀 Branch-Based Deployment Strategy

Your video ingest infrastructure uses a **branch-based deployment strategy** with Terraform Cloud integration for automated, environment-specific deployments.

## 🌿 Branch Strategy

### **`develop` Branch → Development Environment**
- **Purpose**: Active development and testing
- **Terraform Workspace**: `video-ingest-dev`
- **AWS Environment**: Development (cost-optimized)
- **Auto-Deploy**: ✅ Enabled on push to `develop`
- **Resources**: Single AZ, smaller instances, minimal retention

### **`main` Branch → Staging Environment**
- **Purpose**: Pre-production testing and validation
- **Terraform Workspace**: `video-ingest-staging`
- **AWS Environment**: Staging (production-like)
- **Auto-Deploy**: ✅ Enabled on push to `main`
- **Resources**: Multi-AZ, production-sized instances, extended retention

### **`production` Branch → Production Environment** (Future)
- **Purpose**: Live production workloads
- **Terraform Workspace**: `video-ingest-production`
- **AWS Environment**: Production
- **Auto-Deploy**: 🔒 Manual approval required
- **Resources**: Full HA, large instances, long retention

## 🔄 Deployment Workflow

### **Development Workflow**
```bash
# 1. Work on feature branch
git checkout -b feature/new-feature
# Make changes...

# 2. Create PR to develop
git push origin feature/new-feature
# Open PR to develop branch

# 3. Review and merge
# Terraform Cloud runs speculative plan
# Review plan in PR comments
# Merge → Auto-deploy to development environment
```

### **Staging Promotion**
```bash
# 1. Create PR from develop to main
git checkout develop
git pull origin develop
git checkout main
git pull origin main
git checkout -b promote-to-staging
git merge develop

# 2. Create PR to main
git push origin promote-to-staging
# Open PR to main branch

# 3. Review and deploy to staging
# Terraform Cloud runs staging plan
# Review changes and approve
# Merge → Auto-deploy to staging environment
```

## 📋 Current Configuration

### **GitHub Actions Triggers**

#### **Pull Requests**
- **Target**: `develop` or `main` branches
- **Action**: Run Terraform Cloud **speculative plans**
- **Result**: Plan results commented on PR
- **Purpose**: Review infrastructure changes before merge

#### **Push to `develop`**
- **Trigger**: Direct push or PR merge to `develop`
- **Action**: Auto-deploy to **Development** environment
- **Workspace**: `video-ingest-dev`
- **Approval**: None required (auto-apply)

#### **Push to `main`**
- **Trigger**: Direct push or PR merge to `main`
- **Action**: Auto-deploy to **Staging** environment
- **Workspace**: `video-ingest-staging`
- **Approval**: None required (auto-apply)

## 🎯 Environment Configurations

### **Development Environment** (`develop` branch)
```hcl
# Cost-optimized configuration
environment = "dev"
s3_bucket_name = "video-ingest-storage-dev-205930623532"
domain_name = "api.video-ingest-dev.yourdomain.com"

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

# Monitoring
cloudwatch_log_retention_days = 14
enable_detailed_monitoring = true
```

### **Staging Environment** (`main` branch)
```hcl
# Production-like configuration
environment = "staging"
s3_bucket_name = "video-ingest-storage-staging-205930623532"
domain_name = "api.video-ingest-staging.yourdomain.com"

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

# Monitoring
cloudwatch_log_retention_days = 30
enable_detailed_monitoring = true
```

## 🚀 Quick Start - Deploy to Development

### **Option 1: Direct Push to Develop**
```bash
# Switch to develop branch
git checkout develop

# Make your changes
# Edit terraform files, add features, etc.

# Commit and push
git add .
git commit -m "Add new infrastructure feature"
git push origin develop

# 🚀 Automatic deployment to development environment!
```

### **Option 2: Feature Branch Workflow**
```bash
# Create feature branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/add-monitoring

# Make your changes
# Edit terraform files...

# Push feature branch
git add .
git commit -m "Add enhanced monitoring"
git push origin feature/add-monitoring

# Create PR to develop branch
# Review Terraform plan in PR
# Merge PR → Auto-deploy to development
```

## 📊 Terraform Cloud Workspaces

### **Development Workspace**
- **URL**: https://app.terraform.io/app/edstarey-video-ingest/workspaces/video-ingest-dev
- **Branch**: `develop`
- **Directory**: `environments/dev`
- **Auto-Apply**: ✅ Enabled
- **Notifications**: Slack/Email on failures

### **Staging Workspace**
- **URL**: https://app.terraform.io/app/edstarey-video-ingest/workspaces/video-ingest-staging
- **Branch**: `main`
- **Directory**: `environments/staging`
- **Auto-Apply**: ✅ Enabled
- **Notifications**: Slack/Email on all runs

## 🔐 Security & Approvals

### **Development Environment**
- **Approval**: None required
- **Auto-Apply**: ✅ Enabled
- **Rationale**: Fast iteration for development

### **Staging Environment**
- **Approval**: None required (but can be enabled)
- **Auto-Apply**: ✅ Enabled
- **Rationale**: Automated testing environment

### **Production Environment** (Future)
- **Approval**: ✅ Required
- **Auto-Apply**: ❌ Disabled
- **Rationale**: Manual oversight for production changes

## 🎯 Best Practices

### **Development**
1. **Always work on feature branches**
2. **Create PRs to develop** for code review
3. **Test in development** before promoting
4. **Keep develop branch stable**

### **Staging Promotion**
1. **Only promote tested features** from develop
2. **Create PRs from develop to main**
3. **Review staging plans carefully**
4. **Test thoroughly in staging**

### **Rollback Strategy**
```bash
# Rollback development
git checkout develop
git revert <commit-hash>
git push origin develop

# Rollback staging
git checkout main
git revert <commit-hash>
git push origin main
```

## 📈 Monitoring & Observability

### **Development Environment**
- **CloudWatch Dashboard**: Basic metrics
- **Log Retention**: 14 days
- **Alerts**: Critical errors only
- **Cost Monitoring**: Daily estimates

### **Staging Environment**
- **CloudWatch Dashboard**: Comprehensive metrics
- **Log Retention**: 30 days
- **Alerts**: All errors and performance issues
- **Cost Monitoring**: Weekly reports

## 💰 Cost Management

### **Development** (~$15-25/day)
- Single AZ deployment
- Smaller instance sizes
- Shorter log retention
- Basic monitoring

### **Staging** (~$30-50/day)
- Multi-AZ deployment
- Production-sized instances
- Extended log retention
- Enhanced monitoring

## 🚨 Troubleshooting

### **Deployment Failures**
1. **Check Terraform Cloud workspace** for detailed logs
2. **Review GitHub Actions** for workflow issues
3. **Verify branch configuration** in workflow file
4. **Check environment variables** in Terraform Cloud

### **Branch Issues**
```bash
# Sync develop with main
git checkout develop
git pull origin main
git push origin develop

# Reset develop to main (if needed)
git checkout develop
git reset --hard origin/main
git push --force-with-lease origin develop
```

## 🎉 You're Ready!

Your infrastructure is now configured for **branch-based deployments**:

- **`develop` branch** → Development environment
- **`main` branch** → Staging environment
- **Terraform Cloud** manages state and deployments
- **GitHub Actions** automates the workflow

**Start developing**: Push to the `develop` branch and watch your infrastructure deploy automatically! 🚀
