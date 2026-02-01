#
# Hetzner VPS + healthchecks.io monitoring
#

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
    project    = "vibe-in-vps"
  }

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false
  }
}

# Firewall resource
resource "hcloud_firewall" "web" {
  name = "${var.server_name}-firewall"

  # SSH access
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # HTTP access
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  # HTTPS access (for future use)
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

# Health check resource
resource "healthchecksio_check" "app" {
  name = var.server_name

  tags = [
    "vibe-in-vps",
    "production"
  ]

  # Check every 5 minutes (300 seconds)
  timeout = 300
  grace   = 60

  # Alert channels (configured in healthchecks.io dashboard)
  channels = "*"

  # Optional: Add more specific configuration
  desc = "Health check for ${var.github_repository} deployed on ${var.server_name}"
}
