# Video Ingest Infrastructure

This repository contains the Terraform infrastructure code for the Video Ingest system, a comprehensive video upload and viewing platform built with a microservices architecture.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CloudFront    │    │   API Gateway   │    │      ECS        │
│      CDN        │    │                 │    │   Fargate       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│       S3        │    │      ALB        │    │      RDS        │
│   Video Store   │    │                 │    │  PostgreSQL     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Project Structure

```
video-ingest-infra/
├── environments/           # Environment-specific configurations
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/               # Reusable Terraform modules
│   ├── vpc/
│   ├── s3/
│   ├── rds/
│   ├── ecs/
│   ├── alb/
│   ├── api-gateway/
│   ├── cloudfront/
│   ├── security/
│   └── monitoring/
├── shared/                # Shared resources (state backend, etc.)
├── scripts/               # Utility scripts
├── tests/                 # Terratest integration tests
├── docs/                  # Additional documentation
├── .github/               # GitHub Actions workflows
├── Makefile              # Automation commands
├── terraform.tfvars.example
└── augment.md            # Technical specifications
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [Make](https://www.gnu.org/software/make/) for automation commands
- [Go](https://golang.org/dl/) >= 1.19 (for Terratest)

## Quick Start

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd video-ingest-infra
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Infrastructure**
   ```bash
   make init ENV=dev
   make plan ENV=dev
   make apply ENV=dev
   ```

3. **Verify Deployment**
   ```bash
   make validate ENV=dev
   make test ENV=dev
   ```

## Available Commands

| Command | Description |
|---------|-------------|
| `make init ENV=<env>` | Initialize Terraform for specified environment |
| `make plan ENV=<env>` | Generate and show execution plan |
| `make apply ENV=<env>` | Apply infrastructure changes |
| `make destroy ENV=<env>` | Destroy infrastructure |
| `make validate ENV=<env>` | Validate Terraform configuration |
| `make format` | Format Terraform files |
| `make test ENV=<env>` | Run Terratest integration tests |
| `make cost ENV=<env>` | Estimate infrastructure costs |
| `make security-scan` | Run security analysis with tfsec |

## Environment Configuration

### Development
- Single AZ deployment
- Smaller instance sizes
- Basic monitoring

### Staging
- Multi-AZ deployment
- Production-like configuration
- Enhanced monitoring

### Production
- Multi-AZ with high availability
- Auto-scaling enabled
- Comprehensive monitoring and alerting
- Backup and disaster recovery

## Security Features

- **Least Privilege IAM**: Minimal required permissions
- **Encryption**: At-rest and in-transit encryption
- **Network Security**: VPC with private subnets, security groups
- **Secrets Management**: AWS Secrets Manager integration
- **SSL/TLS**: End-to-end encryption with ACM certificates

## Monitoring and Observability

- CloudWatch logs and metrics
- Custom dashboards and alarms
- Cost monitoring and optimization
- Performance tracking

## Contributing

1. Create a feature branch
2. Make changes and test locally
3. Run `make validate` and `make format`
4. Submit a pull request
5. CI/CD will run automated tests and security scans

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for common issues and solutions.

## Support

For questions or issues, please refer to the documentation in the `docs/` directory or create an issue in this repository.
