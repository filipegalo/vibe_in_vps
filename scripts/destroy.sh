#!/bin/bash
#
# Destroy all infrastructure
# WARNING: This will delete your VPS and all data!
#

set -euo pipefail

echo "=== DESTROY INFRASTRUCTURE ==="
echo ""
echo "WARNING: This will permanently delete:"
echo "  - Your Hetzner VPS"
echo "  - All data on the VPS"
echo "  - The healthchecks.io check"
echo ""
echo "This will NOT delete:"
echo "  - Docker images in GHCR (delete manually from GitHub Packages)"
echo "  - GitHub repository"
echo "  - Local Terraform state"
echo ""

read -p "Are you sure you want to destroy everything? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

cd "$(dirname "$0")/../infra/terraform"

# Check if Terraform is initialized
if [ ! -d .terraform ]; then
  echo "Initializing Terraform..."
  terraform init
fi

# Destroy infrastructure
echo ""
echo "Destroying infrastructure..."
terraform destroy

echo ""
echo "=== Destroy Complete ==="
echo ""
echo "Manual cleanup steps:"
echo "  1. Delete Docker images from GitHub Packages:"
echo "     https://github.com/users/YOUR_USERNAME/packages"
echo ""
echo "  2. (Optional) Delete healthchecks.io check from dashboard:"
echo "     https://healthchecks.io/projects/"
echo ""
echo "  3. (Optional) Delete local Terraform state:"
echo "     rm -rf infra/terraform/.terraform*"
echo "     rm -rf infra/terraform/terraform.tfstate*"
