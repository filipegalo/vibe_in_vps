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
  # Cloudflare enabled check (same pattern as healthchecks.io)
  cloudflare_enabled = var.cloudflare_api_token != ""

  # Hetzner firewall has max 50 IPs per rule, so we need to chunk the GitHub Actions IPs
  # Split into chunks of 45 to leave room for additional_ssh_ips
  chunk_size = 45
  github_ip_chunks = [
    for i in range(0, length(local.github_actions_ips), local.chunk_size) :
    slice(local.github_actions_ips, i, min(i + local.chunk_size, length(local.github_actions_ips)))
  ]
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

  # SSH access - GitHub Actions IPs (chunked to stay under 50 IP limit per rule)
  # Multiple rules are created because GitHub Actions has 50+ IP ranges
  dynamic "rule" {
    for_each = local.github_ip_chunks
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "22"
      source_ips = rule.value
    }
  }

  # SSH access - additional user-provided IPs
  # Only created if additional_ssh_ips is not empty
  dynamic "rule" {
    for_each = length(var.additional_ssh_ips) > 0 ? [1] : []
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "22"
      source_ips = var.additional_ssh_ips
    }
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

# ============================================
# Cloudflare Tunnel (optional - custom domain + HTTPS)
# ============================================

# Generate random tunnel secret
resource "random_password" "tunnel_secret" {
  count   = local.cloudflare_enabled ? 1 : 0
  length  = 64
  special = false
}

# Create Cloudflare Tunnel
resource "cloudflare_zero_trust_tunnel_cloudflared" "app" {
  count      = local.cloudflare_enabled ? 1 : 0
  account_id = var.cloudflare_account_id
  name       = "${var.project_name}-tunnel"
  secret     = base64encode(random_password.tunnel_secret[0].result)
}

# Configure Cloudflare Tunnel ingress rules
resource "cloudflare_zero_trust_tunnel_cloudflared_config" "app" {
  count      = local.cloudflare_enabled ? 1 : 0
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.app[0].id

  config {
    ingress_rule {
      hostname = var.domain_name
      service  = "http://localhost:80"
    }
    # Catch-all rule (required)
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# Create DNS record pointing to tunnel
resource "cloudflare_record" "app" {
  count   = local.cloudflare_enabled ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.domain_name
  value   = "${cloudflare_zero_trust_tunnel_cloudflared.app[0].id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}
