# Video Ingest Infrastructure Setup Guide

This guide will walk you through setting up the Video Ingest infrastructure from scratch.

## Prerequisites

Before you begin, ensure you have the following installed and configured:

### Required Tools

1. **Terraform** (>= 1.5.0)
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
   unzip terraform_1.5.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **AWS CLI** (>= 2.0)
   ```bash
   # macOS
   brew install awscli
   
   # Linux
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

3. **Make**
   ```bash
   # macOS (usually pre-installed)
   xcode-select --install
   
   # Linux
   sudo apt-get install build-essential  # Ubuntu/Debian
   sudo yum groupinstall "Development Tools"  # RHEL/CentOS
   ```

4. **Go** (>= 1.19, for testing)
   ```bash
   # macOS
   brew install go
   
   # Linux
   wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
   export PATH=$PATH:/usr/local/go/bin
   ```

### AWS Configuration

1. **Configure AWS Credentials**
   ```bash
   aws configure
   ```
   
   You'll need:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region (e.g., us-east-1)
   - Default output format (json)

2. **Verify AWS Access**
   ```bash
   aws sts get-caller-identity
   ```

3. **Required AWS Permissions**
   
   Your AWS user/role needs the following permissions:
   - EC2 (VPC, Subnets, Security Groups, etc.)
   - S3 (Bucket creation and management)
   - RDS (Database instances and subnet groups)
   - ECS (Clusters, services, tasks)
   - ELB (Application Load Balancers)
   - API Gateway
   - CloudFront
   - IAM (Role and policy management)
   - CloudWatch (Logs and metrics)
   - Secrets Manager
   - ACM (Certificate management)

## Initial Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd video-ingest-infra
```

### 2. Set Up Terraform Backend

The first step is to create the S3 bucket and DynamoDB table for Terraform state management.

```bash
# Navigate to shared directory
cd shared

# Initialize and apply backend infrastructure
terraform init
terraform plan
terraform apply
```

**Important**: Note the outputs from this step, as you'll need them for the next step.

### 3. Configure Environment Backend

After creating the backend infrastructure, you need to configure each environment to use it.

Create a backend configuration file for each environment:

```bash
# For development environment
cat > environments/dev/backend.conf << EOF
bucket         = "video-ingest-terraform-state-us-east-1-xxxxxxxx"
key            = "environments/dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "video-ingest-terraform-locks"
encrypt        = true
EOF
```

Replace `xxxxxxxx` with the actual bucket suffix from the shared infrastructure output.

### 4. Configure Environment Variables

```bash
# Copy the example terraform.tfvars
cp terraform.tfvars.example environments/dev/terraform.tfvars

# Edit the file with your specific values
nano environments/dev/terraform.tfvars
```

**Critical Configuration Items:**

1. **S3 Bucket Name**: Must be globally unique
   ```hcl
   s3_bucket_name = "video-ingest-storage-dev-YOUR-UNIQUE-SUFFIX"
   ```

2. **Domain Name**: Update with your actual domain
   ```hcl
   domain_name = "api.video-ingest-dev.yourdomain.com"
   ```

3. **AWS Region**: Ensure consistency across all configurations
   ```hcl
   aws_region = "us-east-1"
   ```

### 5. Initialize Development Environment

```bash
# Initialize Terraform with backend configuration
make init ENV=dev

# Validate configuration
make validate ENV=dev

# Plan the infrastructure
make plan ENV=dev

# Review the plan carefully, then apply
make apply ENV=dev
```

## Environment-Specific Setup

### Development Environment

The development environment is configured for cost optimization:
- Single AZ deployment
- Smaller instance sizes
- Single NAT Gateway
- Minimal backup retention

### Staging Environment

```bash
# Copy dev configuration as starting point
cp -r environments/dev environments/staging

# Update staging-specific values
sed -i 's/dev/staging/g' environments/staging/terraform.tfvars
sed -i 's/db.t3.micro/db.t3.small/g' environments/staging/terraform.tfvars
sed -i 's/enable_rds_multi_az = false/enable_rds_multi_az = true/g' environments/staging/terraform.tfvars

# Initialize and apply
make init ENV=staging
make plan ENV=staging
make apply ENV=staging
```

### Production Environment

```bash
# Copy staging configuration as starting point
cp -r environments/staging environments/prod

# Update production-specific values
sed -i 's/staging/prod/g' environments/prod/terraform.tfvars
sed -i 's/db.t3.small/db.r6g.large/g' environments/prod/terraform.tfvars
sed -i 's/enable_rds_deletion_protection = false/enable_rds_deletion_protection = true/g' environments/prod/terraform.tfvars

# Initialize and apply
make init ENV=prod
make plan ENV=prod
make apply ENV=prod
```

## Verification

### 1. Check Infrastructure Status

```bash
# View current infrastructure status
make status ENV=dev

# View outputs
make outputs ENV=dev
```

### 2. Run Tests

```bash
# Run integration tests
make test ENV=dev
```

### 3. Verify AWS Resources

```bash
# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=video-ingest"

# Check S3 bucket
aws s3 ls | grep video-ingest

# Check RDS instances
aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `video-ingest`)]'
```

## Security Considerations

### 1. Secrets Management

Never commit sensitive information to version control:
- Database passwords are auto-generated and stored in AWS Secrets Manager
- SSL certificates are managed through ACM
- API keys should be stored in Secrets Manager

### 2. Network Security

- All application components are deployed in private subnets
- Security groups follow the principle of least privilege
- VPC Flow Logs are enabled for network monitoring

### 3. Encryption

- All data is encrypted at rest and in transit
- S3 buckets use server-side encryption
- RDS instances use encryption at rest
- ELB uses SSL/TLS termination

## Monitoring and Maintenance

### 1. CloudWatch Monitoring

The infrastructure includes comprehensive monitoring:
- VPC Flow Logs
- Application logs in CloudWatch
- Custom metrics and alarms
- Cost monitoring

### 2. Backup and Recovery

- RDS automated backups with point-in-time recovery
- S3 versioning and lifecycle policies
- Infrastructure as Code for disaster recovery

### 3. Cost Optimization

- Regular cost reviews using AWS Cost Explorer
- Right-sizing recommendations
- Lifecycle policies for storage optimization

## Troubleshooting

See [troubleshooting.md](troubleshooting.md) for common issues and solutions.

## Next Steps

After successful infrastructure deployment:

1. Deploy the video-ingest API service
2. Deploy the video-ingest-ui frontend
3. Configure DNS and SSL certificates
4. Set up monitoring and alerting
5. Configure CI/CD pipelines for application deployment
