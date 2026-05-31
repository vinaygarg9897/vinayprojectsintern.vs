# ERP Suite - Docker Deployment Guide

## Overview
This project is containerized using Docker best practices with multi-stage builds, health checks, and optimized layer caching.

### Architecture
- **API**: NestJS backend running on port 3001 (exposed internally on 3000)
- **Web**: Next.js frontend running on port 3000
- **PostgreSQL**: Database on port 5432
- **Redis**: Cache on port 6379
- **Keycloak**: Identity provider on port 8080

## Quick Start

### Development Mode
```bash
# Copy environment template
cp .env.example .env

# Start all services with hot reload
docker compose up
```

The `develop: watch:` sections in docker-compose.yml enable automatic rebuilds when code changes in `apps/api/src` and `apps/web/src`.

### Production Mode
```bash
# Build images
docker build -f apps/api/Dockerfile -t erp-api:latest .
docker build -f apps/web/Dockerfile -t erp-web:latest .

# Start services
docker compose -f docker-compose.yml up -d
```

## Environment Configuration

Copy `.env.example` to `.env` and customize:

```bash
# Database
DB_USER=erp_admin
DB_PASSWORD=erp_password  # Change in production!
DB_NAME=erp_db

# Keycloak
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin  # Change in production!

# API
JWT_SECRET=your-secret-key-change-in-production
NODE_ENV=production

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:3001
```

## Docker Best Practices Applied

### 1. Multi-Stage Builds
- **Builder Stage**: Full Node.js image with TypeScript, build tools, and dev dependencies
- **Runtime Stage**: Lean Alpine image with only production dependencies
- **Result**: ~70-80% smaller images compared to single-stage builds

### 2. Alpine Base Images
- Used `node:23-alpine` for 85%+ smaller base than `node:23`
- Also using `postgres:17-alpine` and `redis:8.0-M03-alpine`

### 3. Health Checks
All services include health checks for orchestration awareness:
- PostgreSQL: `pg_isready` command
- Redis: `redis-cli ping`
- API: HTTP GET to `/health` endpoint
- Web: HTTP GET to port 3000

### 4. Networking
- Custom bridge network `erp-network` for service communication
- Services resolve via container names (e.g., `postgres:5432`)
- No port mapping needed between internal services

### 5. Volume Management
- **Named volumes**: `pgdata`, `redisdata` for persistence
- **Bind mounts** (development): Source code directories with hot reload

### 6. Layer Caching Optimization
- Workspace files copied first (rarely change)
- Dependencies installed separately (cache-friendly)
- Application code copied last (frequently changes)
- `.dockerignore` excludes node_modules, .turbo, .next, dist

### 7. Security
- Run containers as non-root (default Alpine Node user)
- No secrets in Dockerfiles (use `.env` and env_file instead)
- Health checks prevent unhealthy containers from receiving traffic

## Common Commands

### View running containers
```bash
docker compose ps
```

### View service logs
```bash
docker compose logs -f api
docker compose logs -f web
docker compose logs -f postgres
```

### Execute commands in containers
```bash
# Run migrations or scripts in API
docker compose exec api pnpm run migration:run

# Access PostgreSQL shell
docker compose exec postgres psql -U erp_admin -d erp_db
```

### Rebuild a specific service
```bash
docker compose build --no-cache api
docker compose up -d api
```

### Clean up
```bash
# Stop containers
docker compose down

# Remove images
docker rmi erp-api erp-web

# Remove volumes (careful - deletes data!)
docker compose down -v
```

## Troubleshooting

### Services won't start
```bash
# Check logs
docker compose logs

# Verify health status
docker compose ps

# Inspect specific service
docker inspect erp_api
```

### Port conflicts
Change exposed ports in `docker-compose.yml`:
```yaml
ports:
  - "3001:3000"  # Change first port if 3001 is taken
```

### Database connection errors
```bash
# Check PostgreSQL is healthy
docker compose exec postgres pg_isready -U erp_admin

# Check Redis is healthy
docker compose exec redis redis-cli ping
```

### Memory issues
Increase Docker Desktop memory limit or add resource limits in docker-compose.yml:
```yaml
services:
  api:
    deploy:
      resources:
        limits:
          memory: 1G
```

## Production Deployment

For production, consider:

1. **Use Docker Swarm or Kubernetes** instead of docker-compose
2. **Push images to a registry** (Docker Hub, ECR, GCR)
3. **Use secrets management** (Docker Secrets, Kubernetes Secrets, Vault)
4. **Scale services** with container orchestration
5. **Use reverse proxy** (nginx, Traefik) for load balancing
6. **Enable logging** (ELK, Splunk, CloudWatch)
7. **Monitor containers** (Prometheus, Datadog)

### Example: Kubernetes Deployment
```bash
# Push images
docker tag erp-api:latest myregistry/erp-api:1.0.0
docker push myregistry/erp-api:1.0.0

# Deploy manifests
kubectl apply -f k8s/
```

## File Structure
```
.
├── .dockerignore           # Files excluded from build context
├── .env.example            # Environment template
├── docker-compose.yml      # Full service stack definition
├── apps/
│   ├── api/
│   │   ├── Dockerfile      # Multi-stage build for NestJS
│   │   ├── src/
│   │   └── package.json
│   └── web/
│       ├── Dockerfile      # Multi-stage build for Next.js
│       ├── src/
│       └── package.json
└── packages/               # Shared packages
```

## Additional Resources
- [Docker Documentation](https://docs.docker.com)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Best Practices for Dockerfiles](https://docs.docker.com/develop/dev-best-practices/)
