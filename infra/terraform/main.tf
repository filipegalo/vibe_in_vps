#
# Hetzner VPS + healthchecks.io monitoring
#

# Fetch GitHub Actions IP ranges
data "http" "github_meta" {
  url = "https://api.github.com/meta"

  request_headers = {
    Accept = "application/vnd.github+json"
  }
}

# Parse GitHub Actions IP ranges from API response
locals {
  github_meta        = jsondecode(data.http.github_meta.response_body)
  github_actions_ips = local.github_meta.actions
  # Combine GitHub Actions IPs with user-provided additional IPs
  all_ssh_ips        = concat(local.github_actions_ips, var.additional_ssh_ips)
}

# SSH key resource
resource "hcloud_ssh_key" "deploy" {
  name       = "${var.server_name}-deploy-key"
  public_key = var.ssh_public_key
}

# VPS server
resource "hcloud_server" "vps" {
  name        = var.server_name
  server_type = var.server_type
  location    = var.location
  image       = "ubuntu-24.04"

  ssh_keys = [hcloud_ssh_key.deploy.id]

  # Cloud-init configuration
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    ssh_public_key = var.ssh_public_key
  })

  # Firewall rules (inline for simplicity)
  firewall_ids = [hcloud_firewall.web.id]

  labels = {
    managed-by = "terraform"
    project    = var.project_name
  }

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false
  }
}

# Firewall resource
resource "hcloud_firewall" "web" {
  name = "${var.server_name}-firewall"

  # SSH access - restricted to GitHub Actions + optional additional IPs
  # GitHub Actions IPs are always included for automated deployments
  # Additional IPs can be configured via additional_ssh_ips variable
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = local.all_ssh_ips
  }

  # HTTP access - customizable source IPs
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = var.allowed_http_ips
  }

  # HTTPS access - customizable source IPs (for future use)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = var.allowed_https_ips
  }
}

# Health check resource (optional)
resource "healthchecksio_check" "app" {
  count = var.healthchecks_api_key != "" ? 1 : 0

  name = var.server_name

  tags = [
    var.project_name,
    "production"
  ]

  # Check every 5 minutes (300 seconds)
  timeout = 300
  grace   = 60

  # Alerts will be sent to all channels configured in healthchecks.io dashboard
  # (channels attribute omitted = default behavior sends to all channels)

  # Optional: Add more specific configuration
  desc = "Health check for ${var.github_repository} deployed on ${var.server_name}"
}
