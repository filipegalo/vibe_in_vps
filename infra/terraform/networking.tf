#
# Networking - Firewall Rules
#

resource "hcloud_firewall" "web" {
  name = "${var.server_name}-firewall"

  # SSH access - Restricted by IP if additional_ssh_ips is set, otherwise open to all
  # Security relies primarily on SSH key authentication (password auth disabled)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = length(var.additional_ssh_ips) > 0 ? var.additional_ssh_ips : ["0.0.0.0/0", "::/0"]
  }

  # HTTP access - customizable source IPs
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = var.allowed_http_ips
  }

  # HTTPS access - customizable source IPs
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = var.allowed_https_ips
  }
}
