#
# Compute Resources - Hetzner VPS
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

  # Firewall rules
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
