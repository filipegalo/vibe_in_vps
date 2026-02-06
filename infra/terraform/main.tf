#
# Main Terraform Configuration
#
# Resources are organized into separate files:
# - compute.tf      : VPS and SSH keys
# - networking.tf   : Firewall rules
# - cloudflare.tf   : Cloudflare Tunnel + DNS
# - monitoring.tf   : healthchecks.io
#

locals {
  # Cloudflare enabled check - requires both API token AND domain name
  cloudflare_enabled = var.cloudflare_api_token != "" && var.domain_name != ""
}
