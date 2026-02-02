#!/bin/bash
#
# Bootstrap script for initial VPS setup
# This script is run once during first deployment
#

set -euo pipefail

echo "=== Bootstrap: Provision Infrastructure ==="

# Wait for cloud-init to complete
echo "Waiting for cloud-init to complete..."
MAX_WAIT=300
ELAPSED=0
while [ ! -f /opt/app/.cloud-init-complete ]; do
  if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo "ERROR: cloud-init did not complete within ${MAX_WAIT}s"
    exit 1
  fi
  echo "  Still waiting... (${ELAPSED}s)"
  sleep 10
  ELAPSED=$((ELAPSED + 10))
done
echo "✓ cloud-init complete"

# Verify Docker is ready
echo "Verifying Docker is installed..."
if ! command -v docker &> /dev/null; then
  echo "ERROR: Docker not found"
  exit 1
fi
docker --version
echo "✓ Docker ready"

# Verify Docker Compose is ready
echo "Verifying Docker Compose is installed..."
if ! docker compose version &> /dev/null; then
  echo "ERROR: Docker Compose not found"
  exit 1
fi
docker compose version
echo "✓ Docker Compose ready"

# Create .env file if it doesn't exist
if [ ! -f /opt/app/.env ]; then
  echo "Creating .env file..."
  cat > /opt/app/.env <<EOF
GITHUB_REPOSITORY=${GITHUB_REPOSITORY}
EOF
  echo "✓ .env file created"
else
  echo "✓ .env file already exists"
fi

# Login to GitHub Container Registry
echo "Logging in to GitHub Container Registry..."
echo "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_ACTOR}" --password-stdin
echo "✓ Logged in to GHCR"

# Pull the latest image
echo "Pulling latest image from GHCR..."
cd /opt/app
docker compose pull
echo "✓ Image pulled"

# Start the services
echo "Starting services..."
docker compose up -d
echo "✓ Services started"

# Wait for app to be healthy
echo "Waiting for app to be healthy..."
sleep 10
if docker compose ps | grep -q "healthy\|Up"; then
  echo "✓ App is running"
else
  echo "WARNING: App may not be healthy yet. Check with: docker compose ps"
fi

echo ""
echo "=== Bootstrap Complete ==="
echo "Your app should be accessible at: http://$(curl -s ifconfig.me)"
echo ""
