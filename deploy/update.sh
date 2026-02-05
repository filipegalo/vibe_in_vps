#!/bin/bash
#
# Update script for subsequent deployments
# This script is run on every push to main
#

set -euo pipefail

echo "=== Deployment: Updating Application ==="

cd /opt/app

# Verify .env exists (should be copied by deployment workflow)
if [ ! -f .env ]; then
  echo "ERROR: .env file not found. It should be copied during deployment."
  exit 1
fi

echo "Using environment configuration from .env file..."

# Login to GitHub Container Registry
echo "Logging in to GHCR..."
echo "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_ACTOR}" --password-stdin

# Pull latest images
echo "Pulling latest images..."
docker compose pull

# Restart all services (app, databases, cloudflared if enabled)
echo "Restarting services..."
docker compose up -d

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
