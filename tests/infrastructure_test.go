package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestInfrastructureDev(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../environments/dev",
		VarFiles:     []string{"terraform.tfvars"},
		NoColor:      true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test VPC creation
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcId)

	// Test S3 bucket creation
	s3BucketName := terraform.Output(t, terraformOptions, "s3_bucket_name")
	assert.NotEmpty(t, s3BucketName)
	assert.Contains(t, s3BucketName, "video-ingest")

	// Test security groups
	securityGroups := terraform.OutputMap(t, terraformOptions, "security_group_ids")
	assert.NotEmpty(t, securityGroups["alb"])
	assert.NotEmpty(t, securityGroups["ecs"])
	assert.NotEmpty(t, securityGroups["rds"])
}

func TestInfrastructureStaging(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../environments/staging",
		VarFiles:     []string{"terraform.tfvars"},
		NoColor:      true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test VPC creation
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcId)

	// Test S3 bucket creation
	s3BucketName := terraform.Output(t, terraformOptions, "s3_bucket_name")
	assert.NotEmpty(t, s3BucketName)
	assert.Contains(t, s3BucketName, "video-ingest")
}

func TestVPCModule(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/vpc",
		Vars: map[string]interface{}{
			"project_name":            "test-video-ingest",
			"environment":             "test",
			"vpc_cidr":               "10.0.0.0/16",
			"availability_zones":      []string{"us-east-1a", "us-east-1b"},
			"public_subnet_cidrs":     []string{"10.0.1.0/24", "10.0.2.0/24"},
			"private_subnet_cidrs":    []string{"10.0.11.0/24", "10.0.12.0/24"},
			"database_subnet_cidrs":   []string{"10.0.21.0/24", "10.0.22.0/24"},
			"enable_nat_gateway":      true,
			"single_nat_gateway":      true,
			"enable_vpc_flow_logs":    false,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test VPC outputs
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcId)

	vpcCidr := terraform.Output(t, terraformOptions, "vpc_cidr_block")
	assert.Equal(t, "10.0.0.0/16", vpcCidr)

	publicSubnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	assert.Len(t, publicSubnetIds, 2)

	privateSubnetIds := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	assert.Len(t, privateSubnetIds, 2)

	databaseSubnetIds := terraform.OutputList(t, terraformOptions, "database_subnet_ids")
	assert.Len(t, databaseSubnetIds, 2)
}

func TestS3Module(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/s3",
		Vars: map[string]interface{}{
			"project_name":       "test-video-ingest",
			"environment":        "test",
			"bucket_name":        "test-video-ingest-storage-12345",
			"enable_versioning":  true,
			"enable_encryption":  true,
			"enable_lifecycle":   true,
			"enable_cors":        true,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test S3 outputs
	bucketId := terraform.Output(t, terraformOptions, "bucket_id")
	assert.Equal(t, "test-video-ingest-storage-12345", bucketId)

	bucketArn := terraform.Output(t, terraformOptions, "bucket_arn")
	assert.Contains(t, bucketArn, "test-video-ingest-storage-12345")

	bucketDomainName := terraform.Output(t, terraformOptions, "bucket_domain_name")
	assert.NotEmpty(t, bucketDomainName)
}
