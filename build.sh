#!/usr/bin/env sh
# Build script for ERP Suite

set -e

echo "🐳 Building ERP API..."
docker build -f apps/api/Dockerfile -t erp-api:latest .

echo "🐳 Building ERP Web..."
docker build -f apps/web/Dockerfile -t erp-web:latest .

echo "✅ Build complete!"
echo ""
echo "To start all services, run:"
echo "  docker compose up -d"
echo ""
echo "To stop all services, run:"
echo "  docker compose down"
