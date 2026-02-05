terraform {
  required_version = ">= 1.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    healthchecksio = {
      source  = "kristofferahl/healthchecksio"
      version = "~> 2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "healthchecksio" {
  # If api_key is empty, provider will be configured but resources won't be created (count = 0)
  # Using coalesce with nonsensitive to avoid "marked value" error during validation
  api_key = coalesce(var.healthchecks_api_key, "disabled")
}

provider "cloudflare" {
  # If api_token is empty, provider will be configured but resources won't be created (count = 0)
  # Using coalesce with nonsensitive to avoid "marked value" error during validation
  api_token = coalesce(var.cloudflare_api_token, "disabled")
}
