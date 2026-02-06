#!/bin/bash
#
# Generate .env file for VPS deployment
#
# This script creates a complete .env file by combining:
# - GitHub context (repository, actor, token)
# - Database credentials (from GitHub Secrets)
# - Cloudflare configuration (from Terraform outputs)
#
# All values use shell parameter expansion ${VAR:-default} to provide
# graceful fallbacks when variables are not set.
#
# Usage:
#   ./scripts/generate-env.sh
#
# Expected environment variables:
#   GITHUB_REPOSITORY       - GitHub repo (owner/name)
#   GITHUB_TOKEN            - GitHub token for GHCR access
#   GITHUB_ACTOR            - GitHub username
#   POSTGRES_PASSWORD       - PostgreSQL password (optional)
#   MYSQL_ROOT_PASSWORD     - MySQL root password (optional)
#   MYSQL_PASSWORD          - MySQL user password (optional)
#   REDIS_PASSWORD          - Redis password (optional)
#   CLOUDFLARE_TUNNEL_TOKEN - Cloudflare tunnel token (optional)
#

set -euo pipefail

# Output file (can be overridden)
OUTPUT_FILE="${OUTPUT_FILE:-.env}"

echo "Generating environment configuration at ${OUTPUT_FILE}..."

# Generate .env file
cat > "${OUTPUT_FILE}" << EOF
# GitHub Context
GITHUB_REPOSITORY=${GITHUB_REPOSITORY}
GITHUB_TOKEN=${GITHUB_TOKEN}
GITHUB_ACTOR=${GITHUB_ACTOR}

# Database Configuration
POSTGRES_USER=${POSTGRES_USER:-app}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-}
POSTGRES_DB=${POSTGRES_DB:-app}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-}
MYSQL_USER=${MYSQL_USER:-app}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-}
MYSQL_DATABASE=${MYSQL_DATABASE:-app}
REDIS_PASSWORD=${REDIS_PASSWORD:-}

# Cloudflare Configuration
CLOUDFLARE_TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN:-}
EOF

echo "✓ Environment configuration generated successfully"

# Show summary (without exposing secrets)
echo ""
echo "Configuration summary:"
echo "  GITHUB_REPOSITORY: ${GITHUB_REPOSITORY:-<not set>}"
echo "  GITHUB_ACTOR: ${GITHUB_ACTOR:-<not set>}"
echo "  POSTGRES_PASSWORD: $([ -n "${POSTGRES_PASSWORD:-}" ] && echo '<set>' || echo '<empty>')"
echo "  MYSQL_ROOT_PASSWORD: $([ -n "${MYSQL_ROOT_PASSWORD:-}" ] && echo '<set>' || echo '<empty>')"
echo "  MYSQL_PASSWORD: $([ -n "${MYSQL_PASSWORD:-}" ] && echo '<set>' || echo '<empty>')"
echo "  REDIS_PASSWORD: $([ -n "${REDIS_PASSWORD:-}" ] && echo '<set>' || echo '<empty>')"
echo "  CLOUDFLARE_TUNNEL_TOKEN: $([ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ] && echo '<set>' || echo '<empty>')"
