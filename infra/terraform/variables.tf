variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "healthchecks_api_key" {
  description = "healthchecks.io API key"
  type        = string
  sensitive   = true
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
  description = "Hetzner server type (cx22 = ~$4.50/mo)"
  type        = string
  default     = "cx22"
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
