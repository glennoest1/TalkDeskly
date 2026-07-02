# TalkDeskly Production Docker Compose Deployment Guide

This guide walks through deploying TalkDeskly to a production server using Docker Compose.

---

## Prerequisites

- A Linux server (Ubuntu 22.04+ recommended) with Docker Engine & Docker Compose installed
- A domain name pointed to your server (e.g. `chat.yourdomain.com`)
- SMTP credentials for sending emails (e.g. Mailgun, SendGrid)

---

## Step 1: Clone the Repository

SSH into your server and clone the project:
```bash
git clone https://github.com/your-org/TalkDeskly.git
cd TalkDeskly
```

---

## Step 2: Create the Environment File

**File to create:** `.env` in the project root directory (same level as `docker-compose.prod.yml`)

```ini
# === Security ===
JWT_SECRET=f3b55c5e8de95821c97a5b399203a3d5e2e8b28cf9b3f4621cba1b9d4a8e2689
POSTGRES_PASSWORD=bf82a392c10b9de9e2a849dcd892c90e

# === Backend Settings ===
BASE_URL=https://chat.yourdomain.com
PORT=8080
GO_ENV=production

# === Email (SMTP) ===
EMAIL_PROVIDER=smtp
EMAIL_HOST=smtp.mailgun.org
EMAIL_PORT=587
EMAIL_USERNAME=postmaster@yourdomain.com
EMAIL_PASSWORD=your-smtp-password
EMAIL_FROM=support@yourdomain.com
```

> **Important:** Replace all placeholder values. Generate secrets with `openssl rand -hex 32`.

---

## Step 3: Review the Compose File

**File to review:** [docker-compose.prod.yml](../../../docker-compose.prod.yml)

This file defines three services:

| Service | Image | Description |
| :--- | :--- | :--- |
| **backend** | `liamash/talkdeskly:latest` | Go API server with bundled frontend assets |
| **postgres** | `postgres:16` | Database with persistent volume mount |
| **redis** | `redis:7-alpine` | Cache with append-only persistence |

Verify the configuration is valid:
```bash
docker compose -f docker-compose.prod.yml config
```

---

## Step 4: Launch the Stack

Start all services in detached mode:
```bash
docker compose -f docker-compose.prod.yml up -d
```

**What happens:**
1. Docker pulls `liamash/talkdeskly:latest`, `postgres:16`, and `redis:7-alpine`
2. PostgreSQL initializes with the password from `.env`
3. Backend waits for PostgreSQL and Redis, then starts
4. Database migrations run automatically on first launch

---

## Step 5: Verify the Deployment

Check that all containers are running:
```bash
docker compose -f docker-compose.prod.yml ps
```

**Expected:** All 3 services show status `Up`.

Check backend logs:
```bash
docker compose -f docker-compose.prod.yml logs -f backend
```

Test the health endpoint:
```bash
curl https://chat.yourdomain.com/health
```

**Expected:**
```json
{
  "status_code": 200,
  "status": "OK",
  "message": "health_check_completed"
}
```

---

## Step 6: Configure Nginx Reverse Proxy

For SSL termination and WebSocket support, set up Nginx.

See the full Nginx configuration in the [Operations Guide](../operations/README.md#-2-nginx-reverse-proxy-ssl--websockets).

---

## Updating to a Newer Version

```bash
# Pull newest image
docker compose -f docker-compose.prod.yml pull

# Recreate containers with the new image
docker compose -f docker-compose.prod.yml up -d
```

Migrations run automatically on startup.

---

## Files Referenced in This Guide

| File | Purpose |
| :--- | :--- |
| [docker-compose.prod.yml](../../../docker-compose.prod.yml) | Production services, volumes, and networking |
| [backend/docker/Dockerfile.prod](../../../backend/docker/Dockerfile.prod) | Multi-stage build for the Go backend |
| `.env` (project root) | Production secrets and settings |
| [Operations Guide](../operations/README.md) | SSL proxy, backups, troubleshooting |
