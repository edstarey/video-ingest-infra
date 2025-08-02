# Video Ingest Infrastructure Makefile
# Usage: make <target> ENV=<environment>

# Default values
ENV ?= dev
REGION ?= us-east-1
PROJECT_NAME = video-ingest

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

# Validate required environment variable
check-env:
	@if [ -z "$(ENV)" ]; then \
		echo "$(RED)Error: ENV variable is required. Usage: make <target> ENV=<environment>$(NC)"; \
		exit 1; \
	fi
	@if [ ! -d "environments/$(ENV)" ]; then \
		echo "$(RED)Error: Environment '$(ENV)' does not exist$(NC)"; \
		exit 1; \
	fi

# Help target
.PHONY: help
help:
	@echo "$(BLUE)Video Ingest Infrastructure Management$(NC)"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC)"
	@echo "  make <target> ENV=<environment>"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@echo "  $(GREEN)init$(NC)           Initialize Terraform for specified environment"
	@echo "  $(GREEN)plan$(NC)           Generate and show execution plan"
	@echo "  $(GREEN)apply$(NC)          Apply infrastructure changes"
	@echo "  $(GREEN)destroy$(NC)        Destroy infrastructure (use with caution)"
	@echo "  $(GREEN)validate$(NC)       Validate Terraform configuration"
	@echo "  $(GREEN)format$(NC)         Format Terraform files"
	@echo "  $(GREEN)test$(NC)           Run Terratest integration tests"
	@echo "  $(GREEN)cost$(NC)           Estimate infrastructure costs"
	@echo "  $(GREEN)security-scan$(NC)  Run security analysis with tfsec"
	@echo "  $(GREEN)clean$(NC)          Clean temporary files"
	@echo "  $(GREEN)setup-backend$(NC)  Setup Terraform state backend"
	@echo ""
	@echo "$(YELLOW)Available environments:$(NC) dev, staging, prod"
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make init ENV=dev"
	@echo "  make plan ENV=staging"
	@echo "  make apply ENV=prod"

# Setup Terraform state backend (run once per AWS account)
.PHONY: setup-backend
setup-backend:
	@echo "$(BLUE)Setting up Terraform state backend...$(NC)"
	cd shared && terraform init
	cd shared && terraform plan
	cd shared && terraform apply -auto-approve
	@echo "$(GREEN)Backend setup complete$(NC)"

# Initialize Terraform
.PHONY: init
init: check-env
	@echo "$(BLUE)Initializing Terraform for $(ENV) environment...$(NC)"
	cd environments/$(ENV) && terraform init -reconfigure
	@echo "$(GREEN)Terraform initialized for $(ENV)$(NC)"

# Plan infrastructure changes
.PHONY: plan
plan: check-env
	@echo "$(BLUE)Planning infrastructure changes for $(ENV)...$(NC)"
	cd environments/$(ENV) && terraform plan -var-file="terraform.tfvars" -out="$(ENV).tfplan"
	@echo "$(GREEN)Plan generated for $(ENV)$(NC)"

# Apply infrastructure changes
.PHONY: apply
apply: check-env
	@echo "$(BLUE)Applying infrastructure changes for $(ENV)...$(NC)"
	@echo "$(YELLOW)Warning: This will modify AWS resources$(NC)"
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd environments/$(ENV) && terraform apply "$(ENV).tfplan"; \
		echo "$(GREEN)Infrastructure applied for $(ENV)$(NC)"; \
	else \
		echo "$(YELLOW)Apply cancelled$(NC)"; \
	fi

# Destroy infrastructure
.PHONY: destroy
destroy: check-env
	@echo "$(RED)WARNING: This will destroy all infrastructure for $(ENV)!$(NC)"
	@echo "$(RED)This action cannot be undone!$(NC)"
	@read -p "Type 'destroy-$(ENV)' to confirm: " confirm; \
	if [ "$$confirm" = "destroy-$(ENV)" ]; then \
		cd environments/$(ENV) && terraform destroy -var-file="terraform.tfvars" -auto-approve; \
		echo "$(GREEN)Infrastructure destroyed for $(ENV)$(NC)"; \
	else \
		echo "$(YELLOW)Destroy cancelled$(NC)"; \
	fi

# Validate Terraform configuration
.PHONY: validate
validate:
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	terraform fmt -check=true -recursive
	terraform validate
	@for env in dev staging prod; do \
		if [ -d "environments/$$env" ]; then \
			echo "Validating $$env environment..."; \
			cd environments/$$env && terraform validate; \
			cd ../..; \
		fi; \
	done
	@echo "$(GREEN)Validation complete$(NC)"

# Format Terraform files
.PHONY: format
format:
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	terraform fmt -recursive
	@echo "$(GREEN)Formatting complete$(NC)"

# Run integration tests
.PHONY: test
test: check-env
	@echo "$(BLUE)Running integration tests for $(ENV)...$(NC)"
	@if [ ! -f "tests/go.mod" ]; then \
		echo "$(YELLOW)Initializing Go module for tests...$(NC)"; \
		cd tests && go mod init video-ingest-infra-tests; \
		cd tests && go get github.com/gruntwork-io/terratest/modules/terraform; \
		cd tests && go get github.com/stretchr/testify/assert; \
	fi
	cd tests && go test -v -timeout 30m -run TestInfrastructure$(shell echo $(ENV) | sed 's/.*/\u&/')
	@echo "$(GREEN)Tests completed for $(ENV)$(NC)"

# Estimate infrastructure costs
.PHONY: cost
cost: check-env
	@echo "$(BLUE)Estimating infrastructure costs for $(ENV)...$(NC)"
	@if ! command -v infracost >/dev/null 2>&1; then \
		echo "$(YELLOW)Installing infracost...$(NC)"; \
		curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh; \
	fi
	cd environments/$(ENV) && infracost breakdown --path . --terraform-var-file terraform.tfvars
	@echo "$(GREEN)Cost estimation complete for $(ENV)$(NC)"

# Run security analysis
.PHONY: security-scan
security-scan:
	@echo "$(BLUE)Running security analysis...$(NC)"
	@if ! command -v tfsec >/dev/null 2>&1; then \
		echo "$(YELLOW)Installing tfsec...$(NC)"; \
		curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash; \
	fi
	tfsec . --format json --out tfsec-results.json
	tfsec . --format table
	@if ! command -v checkov >/dev/null 2>&1; then \
		echo "$(YELLOW)Installing checkov...$(NC)"; \
		pip install checkov; \
	fi
	checkov -d . --framework terraform --output json --output-file checkov-results.json
	checkov -d . --framework terraform
	@echo "$(GREEN)Security scan complete$(NC)"

# Clean temporary files
.PHONY: clean
clean:
	@echo "$(BLUE)Cleaning temporary files...$(NC)"
	find . -name "*.tfplan" -delete
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name ".terraform.lock.hcl" -delete
	find . -name "terraform.tfstate*" -delete
	rm -f tfsec-results.json checkov-results.json
	@echo "$(GREEN)Cleanup complete$(NC)"

# Show current infrastructure status
.PHONY: status
status: check-env
	@echo "$(BLUE)Infrastructure status for $(ENV):$(NC)"
	cd environments/$(ENV) && terraform show -json | jq -r '.values.root_module.resources[] | select(.type != "data") | "\(.type).\(.name): \(.values.id // "N/A")"'

# Show outputs
.PHONY: outputs
outputs: check-env
	@echo "$(BLUE)Infrastructure outputs for $(ENV):$(NC)"
	cd environments/$(ENV) && terraform output -json | jq .

# Refresh state
.PHONY: refresh
refresh: check-env
	@echo "$(BLUE)Refreshing Terraform state for $(ENV)...$(NC)"
	cd environments/$(ENV) && terraform refresh -var-file="terraform.tfvars"
	@echo "$(GREEN)State refreshed for $(ENV)$(NC)"

# Import existing resource
.PHONY: import
import: check-env
	@echo "$(BLUE)Import existing resource for $(ENV)...$(NC)"
	@echo "Usage: make import ENV=dev RESOURCE=aws_s3_bucket.example ID=my-bucket-name"
	@if [ -z "$(RESOURCE)" ] || [ -z "$(ID)" ]; then \
		echo "$(RED)Error: RESOURCE and ID variables are required$(NC)"; \
		echo "Example: make import ENV=dev RESOURCE=aws_s3_bucket.example ID=my-bucket-name"; \
		exit 1; \
	fi
	cd environments/$(ENV) && terraform import $(RESOURCE) $(ID)

# Default target
.DEFAULT_GOAL := help
