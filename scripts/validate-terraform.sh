#!/bin/bash
#
# Validate Terraform configuration without applying
#

set -euo pipefail

echo "=== Validating Terraform Configuration ==="

cd "$(dirname "$0")/../infra/terraform"

# Check if terraform.tfvars exists
if [ ! -f terraform.tfvars ]; then
  echo "ERROR: terraform.tfvars not found"
  echo "Please copy terraform.tfvars.example to terraform.tfvars and fill in your values"
  exit 1
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Validate configuration
echo "Validating Terraform syntax..."
terraform validate

# Format check
echo "Checking Terraform formatting..."
if ! terraform fmt -check; then
  echo "WARNING: Some files are not properly formatted"
  echo "Run 'terraform fmt' to fix formatting"
fi

# Run plan (dry run)
echo ""
echo "Running Terraform plan (dry run)..."
terraform plan

echo ""
echo "=== Validation Complete ==="
echo "Terraform configuration is valid!"
echo ""
echo "To apply these changes, run: cd infra/terraform && terraform apply"
