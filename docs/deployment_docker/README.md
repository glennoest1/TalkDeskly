# TalkDeskly Docker Compose Deployment Guide

Deploying TalkDeskly using Docker Compose is the recommended path for production environments. It containers are pre-packaged, include integrated health checks, and isolate dependencies.

---

## 🚀 Container Deployment Setup

### Step 1: Environment File Configuration
Create a `.env` file in your production directory containing secure credentials:

```ini
# Production Secret Keys (Use strong random strings)
JWT_SECRET=f3b55c5e8de95821c97a5b399203a3d5e2e8b28cf9b3f4621cba1b9d4a8e2689
POSTGRES_PASSWORD=bf82a392c10b9de9e2a849dcd892c90e

# Backend Port and Domain Settings
BASE_URL=https://chat.yourdomain.com
PORT=8080
GO_ENV=production

# Outbound SMTP Mail Configuration
EMAIL_PROVIDER=smtp
EMAIL_HOST=smtp.mailgun.org
EMAIL_PORT=587
EMAIL_USERNAME=postmaster@yourdomain.com
EMAIL_PASSWORD=secure-smtp-password-here
EMAIL_FROM=support@yourdomain.com
```

---

### Step 2: Compose File Structure
We configure three primary services in `docker-compose.prod.yml`:
1. **Backend Service (`liamash/talkdeskly:latest`)**: Evaluates database and cache status before starting.
2. **Database Service (`postgres:16`)**: Mounts a persistent host folder to prevent data loss.
3. **Cache Service (`redis:7-alpine`)**: Run with appendonly persistence.

Verify the configuration by viewing the production orchestrator:
```bash
docker compose -f docker-compose.prod.yml config
```

---

### Step 3: Launch Services
Start the application stack in detached background mode:
```bash
docker compose -f docker-compose.prod.yml up -d
```

### Step 4: Verify Health Status
Check container runtime statistics:
```bash
docker compose -f docker-compose.prod.yml ps
```
Monitor startup output logs to verify database connectivity:
```bash
docker compose -f docker-compose.prod.yml logs -f backend
```

---

## 🔄 Updating to a Newer Version

To pull the latest release image and perform a rolling update:
```bash
# Pull newest image
docker compose -f docker-compose.prod.yml pull

# Recreate changed containers with minimal downtime
docker compose -f docker-compose.prod.yml up -d
```
The backend automatically executes schema migrations on launch.
