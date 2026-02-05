#!/bin/bash
#
# Update script for subsequent deployments
# This script is run on every push to main
#

set -euo pipefail

echo "=== Deployment: Updating Application ==="

cd /opt/app

# Write environment variables to .env file for docker-compose
echo "Writing environment configuration..."
cat > .env <<EOF
GITHUB_REPOSITORY=${GITHUB_REPOSITORY}
POSTGRES_USER=${POSTGRES_USER:-app}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-}
POSTGRES_DB=${POSTGRES_DB:-app}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-}
MYSQL_USER=${MYSQL_USER:-app}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-}
MYSQL_DATABASE=${MYSQL_DATABASE:-app}
REDIS_PASSWORD=${REDIS_PASSWORD:-}
CLOUDFLARE_TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN:-}
EOF

# Login to GitHub Container Registry
echo "Logging in to GHCR..."
echo "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_ACTOR}" --password-stdin

# Pull latest image
echo "Pulling latest image..."
docker compose pull app

# Restart app service
echo "Restarting app..."
docker compose up -d app

# Clean up old images
echo "Cleaning up old images..."
docker image prune -f

# Wait for health check
echo "Waiting for app to be healthy..."
sleep 5

if docker compose ps app | grep -q "healthy\|Up"; then
  echo "✓ Deployment successful"
  exit 0
else
  echo "WARNING: App may not be healthy yet"
  echo "Check status with: docker compose ps"
  exit 0
fi
