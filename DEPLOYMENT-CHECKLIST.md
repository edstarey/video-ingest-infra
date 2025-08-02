# 🚀 Video Ingest Infrastructure - Deployment Checklist

## AWS Account: 205930623532

### ✅ Pre-Deployment Checklist

- [ ] **AWS CLI configured** with account 205930623532
- [ ] **Terraform installed** (>= 1.5.0)
- [ ] **Make installed**
- [ ] **Go installed** (>= 1.19, for testing)
- [ ] **Repository cloned** to `/Users/edwardstarey/Documents/video-ingrest-infra`

### 🎯 Quick Deployment Options

#### Option 1: Automated Script (Recommended)
```bash
# Run the automated deployment script
./scripts/quick-deploy.sh
```

#### Option 2: Manual Step-by-Step
```bash
# 1. Deploy backend (5 minutes)
cd shared
terraform init && terraform apply

# 2. Configure dev environment (2 minutes)
cd ../environments/dev
# Edit terraform.tfvars with your domain

# 3. Deploy dev environment (15-20 minutes)
make init ENV=dev
make plan ENV=dev
make apply ENV=dev
```

### 📋 Configuration Updates Needed

#### Required Updates in `environments/dev/terraform.tfvars`:

```hcl
# Update these values:
domain_name = "api.video-ingest-dev.YOURDOMAIN.com"  # Replace YOURDOMAIN
certificate_arn = ""  # Leave empty initially, add later if you have SSL cert

# Already configured for your account:
s3_bucket_name = "video-ingest-storage-dev-205930623532"
aws_region = "us-east-1"
```

### 🎯 Expected Deployment Results

#### Resources Created (~40+ AWS resources):
- [x] **VPC** with 9 subnets across 3 AZs
- [x] **S3 bucket**: `video-ingest-storage-dev-205930623532`
- [x] **RDS PostgreSQL** instance (db.t3.micro)
- [x] **ECS Fargate** cluster with auto-scaling
- [x] **Application Load Balancer** with health checks
- [x] **API Gateway** with rate limiting
- [x] **CloudFront CDN** for global delivery
- [x] **CloudWatch** monitoring and dashboards
- [x] **IAM roles** and security groups
- [x] **KMS encryption** and Secrets Manager

#### Expected Outputs:
```
vpc_id = "vpc-xxxxxxxxx"
s3_bucket_name = "video-ingest-storage-dev-205930623532"
alb_dns_name = "video-ingest-alb-xxxxxxxxx.us-east-1.elb.amazonaws.com"
api_gateway_url = "https://xxxxxxxxx.execute-api.us-east-1.amazonaws.com/v1"
cloudfront_domain_name = "xxxxxxxxx.cloudfront.net"
```

### 🔍 Post-Deployment Verification

#### Test Commands:
```bash
# 1. Verify infrastructure status
make status ENV=dev

# 2. View all outputs
make outputs ENV=dev

# 3. Run integration tests
make test ENV=dev

# 4. Test API endpoints
curl https://YOUR-API-GATEWAY-URL/health
curl http://YOUR-ALB-DNS-NAME/health

# 5. Verify S3 bucket
aws s3 ls s3://video-ingest-storage-dev-205930623532/
```

#### Monitoring Dashboard:
```
https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=video-ingest-dev-dashboard
```

### 💰 Cost Monitoring

#### Daily Cost Estimate: $15-25
- **RDS**: ~$0.50/day (db.t3.micro)
- **ECS**: ~$2-5/day (Fargate tasks)
- **ALB**: ~$0.60/day
- **NAT Gateway**: ~$1.50/day
- **S3/CloudFront**: ~$0.10-2/day

#### Monthly Estimate: $450-750

```bash
# Get detailed cost breakdown
make cost ENV=dev
```

### 🚨 Troubleshooting

#### Common Issues:
1. **AWS Credentials**: Run `aws sts get-caller-identity`
2. **Terraform Version**: Run `terraform version`
3. **Backend Conflicts**: Check existing S3 buckets
4. **Resource Limits**: Check AWS service quotas

#### Get Help:
- **Logs**: Check CloudWatch logs
- **Validation**: Run `make validate`
- **Security**: Run `make security-scan`
- **Documentation**: See `docs/troubleshooting.md`

### 🎯 Success Criteria

✅ **Deployment Successful When:**
- All Terraform resources created without errors
- ECS service shows "RUNNING" status with healthy targets
- RDS instance status is "available"
- S3 bucket is accessible
- API Gateway returns 200 responses
- CloudWatch dashboard shows metrics
- No critical alarms triggered

### 📋 Next Steps After Deployment

#### Immediate (Day 1):
- [ ] **Test all endpoints** and verify functionality
- [ ] **Configure monitoring alerts** with email notifications
- [ ] **Set up SSL certificates** (if using custom domain)
- [ ] **Configure DNS records** (if using custom domain)

#### Short Term (Week 1):
- [ ] **Deploy video-ingest API** to ECS cluster
- [ ] **Deploy video-ingest-UI** frontend
- [ ] **Set up CI/CD pipelines** for application deployment
- [ ] **Configure application secrets** in Secrets Manager

#### Medium Term (Month 1):
- [ ] **Deploy staging environment**
- [ ] **Set up backup procedures**
- [ ] **Implement disaster recovery**
- [ ] **Security audit and penetration testing**
- [ ] **Performance optimization**

### 🔐 Security Checklist

- [x] **Encryption at rest** (S3, RDS, EBS)
- [x] **Encryption in transit** (HTTPS, SSL)
- [x] **IAM least privilege** roles and policies
- [x] **VPC security groups** with minimal access
- [x] **Secrets Manager** for credential management
- [x] **KMS key rotation** enabled
- [x] **VPC Flow Logs** enabled
- [x] **CloudTrail** logging (optional, can be enabled)

### 📞 Support

#### Documentation:
- **Setup Guide**: `docs/setup.md`
- **Troubleshooting**: `docs/troubleshooting.md`
- **Architecture**: `augment.md`
- **Implementation Summary**: `docs/implementation-summary.md`

#### Commands Reference:
```bash
# Environment management
make init ENV=dev
make plan ENV=dev
make apply ENV=dev
make destroy ENV=dev

# Validation and testing
make validate
make test ENV=dev
make security-scan

# Monitoring
make status ENV=dev
make outputs ENV=dev
make cost ENV=dev
```

---

**🎉 Ready to Deploy!**

Your video ingest infrastructure is configured for AWS account **205930623532** and ready for deployment. The entire process should take approximately **25-30 minutes**.

**Start with**: `./scripts/quick-deploy.sh`
