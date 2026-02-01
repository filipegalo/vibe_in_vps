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
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "healthchecksio" {
  api_key = var.healthchecks_api_key
}
