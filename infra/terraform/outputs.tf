#
# Terraform outputs
# These values are used to configure GitHub Actions secrets
#

output "server_ip" {
  description = "Public IPv4 address of the VPS"
  value       = hcloud_server.vps.ipv4_address
}

output "server_status" {
  description = "Current status of the VPS"
  value       = hcloud_server.vps.status
}

output "ssh_command" {
  description = "Ready-to-use SSH command"
  value       = "ssh deploy@${hcloud_server.vps.ipv4_address}"
}

output "healthcheck_ping_url" {
  description = "healthchecks.io ping URL (add to GitHub Secrets) - empty if healthchecks disabled"
  value       = length(healthchecksio_check.app) > 0 ? healthchecksio_check.app[0].ping_url : ""
  sensitive   = true
}

output "app_url" {
  description = "URL to access your application"
  value       = local.cloudflare_enabled ? "https://${var.domain_name}" : "http://${hcloud_server.vps.ipv4_address}"
  sensitive   = true
}

output "cloudflare_tunnel_token" {
  description = "Cloudflare Tunnel token for cloudflared daemon (add to GitHub Secrets) - empty if Cloudflare disabled"
  value       = local.cloudflare_enabled ? cloudflare_zero_trust_tunnel_cloudflared.app[0].tunnel_token : ""
  sensitive   = true
}

output "custom_domain_url" {
  description = "Custom domain URL with HTTPS - empty if Cloudflare disabled"
  value       = local.cloudflare_enabled ? "https://${var.domain_name}" : ""
  sensitive   = true
}

output "github_secrets_summary" {
  description = "Summary of required GitHub Secrets"
  value       = <<-EOT

  Add these secrets to your GitHub repository:

  VPS_HOST: ${hcloud_server.vps.ipv4_address}
  ${length(healthchecksio_check.app) > 0 ? "HEALTHCHECK_PING_URL: ${healthchecksio_check.app[0].ping_url}" : "HEALTHCHECK_PING_URL: (healthchecks.io disabled)"}
  ${local.cloudflare_enabled ? "CLOUDFLARE_TUNNEL_TOKEN: [see cloudflare_tunnel_token output]" : "CLOUDFLARE_TUNNEL_TOKEN: (custom domain disabled)"}
  ${local.cloudflare_enabled ? "CUSTOM_DOMAIN_URL: https://${var.domain_name}" : ""}

  Note: SSH user is always "deploy" (no configuration needed).

  Then push to main branch to trigger deployment.
  ${local.cloudflare_enabled ? "\n  Don't forget to uncomment the cloudflared service in deploy/docker-compose.yml!" : ""}
  EOT
  sensitive   = true
}
