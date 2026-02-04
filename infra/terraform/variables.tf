variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "healthchecks_api_key" {
  description = "healthchecks.io API key (optional - leave empty to disable monitoring)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key for server access"
  type        = string
}

variable "server_name" {
  description = "Name of the VPS"
  type        = string
  default     = "vibe-vps"
}

variable "server_type" {
  description = "Hetzner server type (cpx22 = 2 vCPU, 4GB RAM, ~$7.50/mo)"
  type        = string
  default     = "cpx22"
}

variable "location" {
  description = "Datacenter location (nbg1 = Nuremberg, DE)"
  type        = string
  default     = "nbg1"
}

variable "github_repository" {
  description = "GitHub repository in format: owner/repo"
  type        = string
}

variable "project_name" {
  description = "Project name used for labels and identification"
  type        = string
  default     = "vibe-in-vps"
}

variable "additional_ssh_ips" {
  description = "Additional IP addresses/CIDR blocks allowed to SSH (port 22). GitHub Actions IPs are always included. Use [] for GitHub Actions only, or add your IP: ['1.2.3.4/32']"
  type        = list(string)
  default     = []
}

variable "allowed_http_ips" {
  description = "List of IP addresses/CIDR blocks allowed to access HTTP (port 80). Use ['0.0.0.0/0', '::/0'] for all IPs."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "allowed_https_ips" {
  description = "List of IP addresses/CIDR blocks allowed to access HTTPS (port 443). Use ['0.0.0.0/0', '::/0'] for all IPs."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}
