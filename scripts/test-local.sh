#!/bin/bash
#
# Test the Docker build locally before deploying
#

set -euo pipefail

echo "=== Testing Local Docker Build ==="

cd "$(dirname "$0")/.."

# Build the Docker image
echo "Building Docker image..."
docker build -t vibe-test:latest ./app

# Run the container
echo "Starting container..."
docker run -d \
  --name vibe-test \
  -p 3001:3000 \
  vibe-test:latest

# Wait for the app to start
echo "Waiting for app to be ready..."
sleep 3

# Test health endpoint
echo "Testing health endpoint..."
if curl -f http://localhost:3001/health; then
  echo ""
  echo "✓ Health check passed"
else
  echo ""
  echo "✗ Health check failed"
  docker logs vibe-test
  docker stop vibe-test
  docker rm vibe-test
  exit 1
fi

# Test main endpoint
echo "Testing main endpoint..."
if curl -f http://localhost:3001/; then
  echo ""
  echo "✓ Main endpoint working"
else
  echo ""
  echo "✗ Main endpoint failed"
  docker logs vibe-test
  docker stop vibe-test
  docker rm vibe-test
  exit 1
fi

# Show logs
echo ""
echo "=== Container Logs ==="
docker logs vibe-test

# Cleanup
echo ""
echo "Cleaning up..."
docker stop vibe-test
docker rm vibe-test
docker rmi vibe-test:latest

echo ""
echo "=== Test Complete ==="
echo "Your Docker build is working correctly!"
