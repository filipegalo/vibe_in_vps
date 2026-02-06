#
# Cloudflare Tunnel - Custom Domain + HTTPS (Optional)
#
# Enabled when both cloudflare_api_token and domain_name are set
#

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
      service  = "http://app:3000"
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
  content = "${cloudflare_zero_trust_tunnel_cloudflared.app[0].id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}
