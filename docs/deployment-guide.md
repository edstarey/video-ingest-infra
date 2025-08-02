# Video Ingest Infrastructure - Deployment Guide

## 🚀 Quick Deployment for AWS Account: 205930623532

This guide will walk you through deploying the video ingest infrastructure to your AWS account.

## Prerequisites Checklist

### ✅ AWS Configuration
```bash
# Verify AWS CLI is configured
aws sts get-caller-identity

# Expected output should show:
# "Account": "205930623532"
```

### ✅ Required Tools
- [x] Terraform >= 1.5.0
- [x] AWS CLI >= 2.0
- [x] Make
- [x] Go >= 1.19 (for testing)

## Step-by-Step Deployment

### Step 1: Configure Environment Variables (2 minutes)

```bash
# Navigate to the project directory
cd /Users/edwardstarey/Documents/video-ingrest-infra

# Copy the example configuration
cp terraform.tfvars.example environments/dev/terraform.tfvars

# Edit the configuration file
nano environments/dev/terraform.tfvars
```

**Key configurations to update:**

```hcl
# Update these values in environments/dev/terraform.tfvars:

# Domain Configuration (update with your domain)
domain_name = "api.video-ingest-dev.yourdomain.com"

# SSL Certificate (leave empty to create new, or provide existing ARN)
certificate_arn = ""

# S3 bucket name (already configured with your account ID)
s3_bucket_name = "video-ingest-storage-dev-205930623532"

# AWS Region (verify this matches your preference)
aws_region = "us-east-1"
```

### Step 2: Deploy Backend Infrastructure (5 minutes)

```bash
# Navigate to shared directory
cd shared

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the backend infrastructure
terraform apply
```

**Expected Output:**
```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:
terraform_state_bucket_name = "video-ingest-terraform-state-us-east-1-xxxxxxxx"
terraform_locks_table_name = "video-ingest-terraform-locks"
```

**Important:** Note the bucket name from the output - you'll need it for the next step.

### Step 3: Configure Backend for Development Environment (2 minutes)

```bash
# Return to project root
cd ..

# Create backend configuration file for dev environment
cat > environments/dev/backend.conf << EOF
bucket         = "video-ingest-terraform-state-us-east-1-xxxxxxxx"
key            = "environments/dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "video-ingest-terraform-locks"
encrypt        = true
EOF
```

**Replace `xxxxxxxx` with the actual suffix from Step 2 output.**

### Step 4: Deploy Development Environment (15-20 minutes)

```bash
# Initialize development environment
make init ENV=dev

# Generate and review the plan
make plan ENV=dev

# Apply the infrastructure (this will take 15-20 minutes)
make apply ENV=dev
```

**Expected Resources Created:**
- VPC with 9 subnets across 3 AZs
- RDS PostgreSQL instance
- ECS Fargate cluster
- Application Load Balancer
- S3 bucket for video storage
- CloudFront distribution
- API Gateway
- CloudWatch monitoring
- Security groups and IAM roles

### Step 5: Verify Deployment (2 minutes)

```bash
# Check infrastructure status
make status ENV=dev

# View all outputs
make outputs ENV=dev

# Run integration tests
make test ENV=dev
```

**Expected Outputs:**
```
vpc_id = "vpc-xxxxxxxxx"
s3_bucket_name = "video-ingest-storage-dev-205930623532"
alb_dns_name = "video-ingest-alb-xxxxxxxxx.us-east-1.elb.amazonaws.com"
api_gateway_url = "https://xxxxxxxxx.execute-api.us-east-1.amazonaws.com/v1"
cloudfront_domain_name = "xxxxxxxxx.cloudfront.net"
```

## 🎯 Post-Deployment Configuration

### SSL Certificate Setup (Optional)

If you have a custom domain, create an SSL certificate:

```bash
# Request SSL certificate (replace with your domain)
aws acm request-certificate \
  --domain-name "*.yourdomain.com" \
  --validation-method DNS \
  --region us-east-1

# Note the certificate ARN and update terraform.tfvars
certificate_arn = "arn:aws:acm:us-east-1:205930623532:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Re-apply to use the certificate
make apply ENV=dev
```

### DNS Configuration (Optional)

If you have a Route 53 hosted zone:

```bash
# Create CNAME records pointing to:
# ALB DNS name: video-ingest-alb-xxxxxxxxx.us-east-1.elb.amazonaws.com
# CloudFront domain: xxxxxxxxx.cloudfront.net
```

## 🔍 Monitoring and Verification

### CloudWatch Dashboard
Access your monitoring dashboard:
```
https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=video-ingest-dev-dashboard
```

### Test API Endpoint
```bash
# Test the API Gateway endpoint
curl https://xxxxxxxxx.execute-api.us-east-1.amazonaws.com/v1/health

# Test the ALB endpoint
curl http://video-ingest-alb-xxxxxxxxx.us-east-1.elb.amazonaws.com/health
```

### S3 Bucket Verification
```bash
# List your S3 bucket
aws s3 ls s3://video-ingest-storage-dev-205930623532/

# Test upload (optional)
echo "test" > test.txt
aws s3 cp test.txt s3://video-ingest-storage-dev-205930623532/
```

## 🚨 Troubleshooting

### Common Issues

1. **Backend bucket already exists**
   ```bash
   # If you get bucket already exists error, check existing buckets
   aws s3 ls | grep video-ingest-terraform-state
   ```

2. **Permission denied errors**
   ```bash
   # Verify your AWS credentials
   aws sts get-caller-identity
   
   # Check IAM permissions
   aws iam get-user
   ```

3. **Resource limit errors**
   ```bash
   # Check service quotas
   aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A
   ```

### Getting Help

1. **Check logs**: `terraform show` and CloudWatch logs
2. **Validate configuration**: `make validate`
3. **Run security scan**: `make security-scan`
4. **Review troubleshooting guide**: `docs/troubleshooting.md`

## 🎉 Success Indicators

Your deployment is successful when you see:

✅ **All Terraform resources created** (approximately 40+ resources)
✅ **ECS service running** with healthy targets
✅ **RDS instance available**
✅ **S3 bucket accessible**
✅ **CloudFront distribution deployed**
✅ **API Gateway responding**
✅ **CloudWatch dashboard populated**

## 📋 Next Steps

After successful deployment:

1. **Deploy your video-ingest API** to the ECS cluster
2. **Deploy your video-ingest-UI** frontend
3. **Configure application-specific environment variables**
4. **Set up CI/CD pipelines** for application deployment
5. **Configure monitoring alerts** with email notifications

## 💰 Cost Estimation

**Development Environment Daily Cost**: ~$15-25/day
- RDS db.t3.micro: ~$0.50/day
- ECS Fargate: ~$2-5/day (depending on usage)
- ALB: ~$0.60/day
- NAT Gateway: ~$1.50/day
- S3/CloudFront: ~$0.10-2/day (depending on usage)

**Monthly Estimate**: ~$450-750/month for development environment

Use `make cost ENV=dev` for detailed cost breakdown.

---

**Account ID**: 205930623532  
**Region**: us-east-1  
**Environment**: Development  
**Deployment Time**: ~25-30 minutes total
