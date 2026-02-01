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
  value       = "http://${hcloud_server.vps.ipv4_address}"
}

output "github_secrets_summary" {
  description = "Summary of required GitHub Secrets"
  value = <<-EOT

  Add these secrets to your GitHub repository:

  VPS_HOST: ${hcloud_server.vps.ipv4_address}
  VPS_SSH_KEY: <your-private-ssh-key>
  VPS_USER: deploy
  ${length(healthchecksio_check.app) > 0 ? "HEALTHCHECK_PING_URL: ${healthchecksio_check.app[0].ping_url}" : "HEALTHCHECK_PING_URL: (healthchecks.io disabled)"}

  Then push to main branch to trigger deployment.
  EOT
}
