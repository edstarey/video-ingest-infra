# Troubleshooting Guide

This guide covers common issues you might encounter when working with the Video Ingest infrastructure.

## Common Issues

### 1. Terraform Backend Issues

#### Problem: "Backend configuration changed"
```
Error: Backend configuration changed
```

**Solution:**
```bash
# Reinitialize with the new backend configuration
terraform init -reconfigure

# Or migrate state if needed
terraform init -migrate-state
```

#### Problem: "Error acquiring the state lock"
```
Error: Error acquiring the state lock
Lock Info:
  ID:        xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Path:      video-ingest-terraform-state/environments/dev/terraform.tfstate
  Operation: OperationTypePlan
  Who:       user@hostname
  Version:   1.5.0
  Created:   2023-XX-XX XX:XX:XX.XXXXXX UTC
```

**Solution:**
```bash
# Force unlock (use with caution)
terraform force-unlock xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Or wait for the lock to expire (usually 20 minutes)
```

### 2. AWS Permission Issues

#### Problem: "AccessDenied" errors
```
Error: AccessDenied: User: arn:aws:iam::123456789012:user/username is not authorized to perform: ec2:CreateVpc
```

**Solution:**
1. Verify your AWS credentials:
   ```bash
   aws sts get-caller-identity
   ```

2. Check your IAM permissions. You need the following policies:
   - EC2FullAccess (or custom VPC permissions)
   - S3FullAccess (or custom bucket permissions)
   - RDSFullAccess (or custom RDS permissions)
   - ECSFullAccess
   - ElasticLoadBalancingFullAccess
   - APIGatewayFullAccess
   - CloudFrontFullAccess
   - IAMFullAccess (for role creation)
   - CloudWatchFullAccess
   - SecretsManagerFullAccess

3. If using cross-account roles, ensure the trust relationship is configured correctly.

### 3. S3 Bucket Issues

#### Problem: "BucketAlreadyExists"
```
Error: Error creating S3 bucket: BucketAlreadyExists: The requested bucket name is not available
```

**Solution:**
```bash
# Update the bucket name in terraform.tfvars to be globally unique
s3_bucket_name = "video-ingest-storage-dev-$(date +%s)"
```

#### Problem: "AccessDenied" when accessing S3 bucket
```
Error: AccessDenied: Access Denied
```

**Solution:**
1. Check bucket policy and IAM permissions
2. Verify the bucket is in the correct region
3. Ensure public access block settings are appropriate

### 4. RDS Issues

#### Problem: "DBSubnetGroupDoesNotCoverEnoughAZs"
```
Error: DBSubnetGroupDoesNotCoverEnoughAZs: DB Subnet Group doesn't meet availability zone coverage requirement
```

**Solution:**
Ensure your database subnets span at least 2 availability zones:
```hcl
database_subnet_cidrs = [
  "10.0.21.0/24",  # us-east-1a
  "10.0.22.0/24",  # us-east-1b
  "10.0.23.0/24"   # us-east-1c
]
```

#### Problem: RDS instance creation timeout
```
Error: timeout while waiting for state to become 'available'
```

**Solution:**
1. Check AWS service health dashboard
2. Verify instance class is available in your region
3. Increase timeout in Terraform configuration
4. Check CloudWatch logs for detailed error messages

### 5. ECS Issues

#### Problem: "InvalidParameterException" for ECS task definition
```
Error: InvalidParameterException: Task definition does not exist
```

**Solution:**
This usually occurs when modules are applied out of order. Ensure dependencies are properly configured:
```bash
# Apply in correct order
make apply ENV=dev
```

### 6. Networking Issues

#### Problem: "InvalidVpcID.NotFound"
```
Error: InvalidVpcID.NotFound: The vpc ID 'vpc-xxxxxxxx' does not exist
```

**Solution:**
1. Verify the VPC was created successfully
2. Check if you're referencing the correct VPC ID
3. Ensure you're working in the correct AWS region

#### Problem: NAT Gateway connectivity issues
```
Error: timeout while waiting for state to become 'available'
```

**Solution:**
1. Verify Elastic IP allocation
2. Check route table configurations
3. Ensure Internet Gateway is attached to VPC

### 7. SSL/TLS Certificate Issues

#### Problem: "CertificateNotFound"
```
Error: CertificateNotFound: Certificate not found
```

**Solution:**
1. Create the certificate in ACM first:
   ```bash
   aws acm request-certificate \
     --domain-name "*.yourdomain.com" \
     --validation-method DNS \
     --region us-east-1
   ```

2. Update the certificate ARN in terraform.tfvars

#### Problem: Certificate validation timeout
**Solution:**
1. Ensure DNS validation records are created
2. Wait for DNS propagation (can take up to 72 hours)
3. Verify domain ownership

### 8. Cost-Related Issues

#### Problem: Unexpected high costs
**Solution:**
1. Check for running resources:
   ```bash
   # Check for running EC2 instances
   aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`]'
   
   # Check for NAT Gateways
   aws ec2 describe-nat-gateways --filter "Name=state,Values=available"
   
   # Check RDS instances
   aws rds describe-db-instances --query 'DBInstances[?DBInstanceStatus==`available`]'
   ```

2. Review CloudWatch billing alarms
3. Use AWS Cost Explorer to identify cost drivers

### 9. Module-Specific Issues

#### Problem: Module not found
```
Error: Module not found: ./modules/vpc
```

**Solution:**
Ensure you're running Terraform from the correct directory:
```bash
# Should be in environments/dev, not root directory
cd environments/dev
terraform plan
```

#### Problem: Module version conflicts
**Solution:**
```bash
# Clear module cache and reinitialize
rm -rf .terraform/modules
terraform init
```

### 10. State File Issues

#### Problem: State file corruption
```
Error: Failed to load state: state snapshot was created by Terraform v1.x.x, which is newer than current v1.y.y
```

**Solution:**
1. Upgrade Terraform to the required version
2. Or restore from a backup:
   ```bash
   # List state file versions
   aws s3api list-object-versions --bucket your-terraform-state-bucket --prefix environments/dev/terraform.tfstate
   
   # Restore specific version
   aws s3api get-object --bucket your-terraform-state-bucket --key environments/dev/terraform.tfstate --version-id VERSION_ID terraform.tfstate
   ```

## Debugging Commands

### General Debugging
```bash
# Enable detailed logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log

# Run with verbose output
terraform plan -detailed-exitcode
terraform apply -auto-approve -parallelism=1
```

### AWS Resource Inspection
```bash
# Check VPC resources
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=video-ingest"
aws ec2 describe-subnets --filters "Name=tag:Project,Values=video-ingest"
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=video-ingest"

# Check S3 resources
aws s3api list-buckets --query 'Buckets[?contains(Name, `video-ingest`)]'

# Check RDS resources
aws rds describe-db-instances --query 'DBInstances[?contains(DBInstanceIdentifier, `video-ingest`)]'

# Check ECS resources
aws ecs list-clusters
aws ecs list-services --cluster video-ingest-cluster-dev
```

### State Inspection
```bash
# List all resources in state
terraform state list

# Show specific resource
terraform state show aws_vpc.main

# Import existing resource
terraform import aws_vpc.main vpc-xxxxxxxx
```

## Getting Help

### 1. Check Logs
- CloudWatch Logs for application issues
- VPC Flow Logs for network issues
- CloudTrail for API call auditing

### 2. AWS Support
- Use AWS Support Center for infrastructure issues
- Check AWS Service Health Dashboard

### 3. Community Resources
- Terraform AWS Provider documentation
- AWS documentation and best practices
- Stack Overflow for specific error messages

### 4. Internal Escalation
1. Check this troubleshooting guide
2. Review infrastructure documentation
3. Contact the platform team
4. Create an incident ticket if needed

## Prevention

### 1. Regular Maintenance
```bash
# Weekly infrastructure validation
make validate
make security-scan

# Monthly cost review
make cost ENV=dev
```

### 2. Monitoring
- Set up CloudWatch alarms for critical metrics
- Monitor AWS billing alerts
- Regular security scans

### 3. Backup Strategy
- Regular state file backups
- Infrastructure documentation updates
- Disaster recovery testing
