# TalkDeskly Local Development Setup Guide

This guide describes how to run all components of TalkDeskly on a local machine for coding, testing, and debugging.

---

## Architecture Overview

TalkDeskly consists of the following components:

| Component | Description | Default Port |
| :--- | :--- | :---: |
| **PostgreSQL** | Primary database | `5433` (host) → `5432` (container) |
| **Redis** | Cache & pub/sub | `6379` |
| **Mailhog** | Development email server | SMTP: `1025`, Web UI: `8025` |
| **Go Backend** | API server + WebSocket | Hybrid: `8080`, Docker: `8080` |
| **Frontend** | Agent Console dashboard (React) | `3001` |
| **Chat Bubble** | Embeddable chat widget (React) | `3000` |

You can choose between two setup workflows:

* **Approach A (Hybrid)**: Database services in Docker + Go/React on your host. Best for active coding.
* **Approach B (Full Docker)**: Everything in Docker containers. Best for quick setup without installing Go/Node.

---

## Prerequisites

| Dependency | Approach A (Hybrid) | Approach B (Full Docker) |
| :--- | :---: | :---: |
| **Docker Engine & Compose** | Required | Required |
| **Go (v1.21+)** | Required | Not needed |
| **Node.js (v18+) & npm** | Required | Not needed |
| **Air** (Go hot-reload) | Required | Bundled in container |
| **Delve** (Go debugger) | Optional | Bundled in container |

---

## Approach A: Hybrid Development (Recommended)

### Step 1: Start Database Services in Docker

From the **project root**, start only the infrastructure containers:
```bash
docker compose -f docker-compose.dev.yml up -d postgres redis mailhog
```

**What this does:**
- Starts PostgreSQL on port `5433` (mapped from container port `5432`)
- Starts Redis on port `6379`
- Starts Mailhog SMTP on port `1025` with Web UI at `http://localhost:8025`

**File involved:** [docker-compose.dev.yml](../../../docker-compose.dev.yml)

---

### Step 2: Configure the Backend

**File to edit:** [backend/.env](../../../backend/.env)

Create or edit the `.env` file inside the `backend/` folder with these values:
```ini
PORT=8080
BASE_URL=http://localhost:8080
GO_ENV=development
JWT_SECRET=secret
DATABASE_URL=postgres://postgres:postgres@localhost:5433/talkdeskly
REDIS_URL=localhost:6379
EMAIL_PROVIDER=smtp
EMAIL_HOST=localhost
EMAIL_PORT=1025
SUPPORTED_LANGUAGES=en,vi
DEFAULT_LANGUAGE=en
```

> **Note:** Full configuration variable reference is available in the [Operations Guide](../operations/README.md).

---

### Step 3: Run Database Migrations & Seed Data

From the `backend/` folder, initialize the database schema and populate test data:
```bash
cd backend
go run main.go migrate run
go run main.go seed run
```

**Expected output after seeding:**
```
✅ Seeding completed!
🔑 Admin login: admin@talkdeskly.com (password: password123)
🏢 Company: New Media Parents
👥 8 agents, 📮 8 inboxes, 👤 25 contacts, 💬 40 conversations
```

---

### Step 4: Start the Backend Server

From the `backend/` folder, start the Go server with hot-reloading:
```bash
air
```

**Expected result:** Server starts on `http://localhost:8080`, Delve debugger on port `2345`.

**Verify:** Open `http://localhost:8080/health` in your browser — you should see `"status": "OK"`.

---

### Step 5: Start the Agent Console (Frontend)

Open a **new terminal**, navigate to the `frontend/` folder:
```bash
cd frontend
npm install
npm run dev
```

**Expected result:** Dashboard runs at `http://localhost:3001`.

**Verify:** Open `http://localhost:3001` → login with `admin@talkdeskly.com` / `password123`.

**Files with hardcoded dev URLs (edit if you change the backend port):**
- API base URL: [frontend/src/lib/api/client.ts](../../../frontend/src/lib/api/client.ts) (Line 14, default: `http://localhost:8080/api`)
- WebSocket URL: [frontend/src/context/websocket-context.tsx](../../../frontend/src/context/websocket-context.tsx) (Line 13, default: `ws://localhost:8080/ws`)

---

### Step 6: Start the Chat Widget

Open a **third terminal**, navigate to the `chat-bubble/` folder:
```bash
cd chat-bubble
npm install
npm run dev
```

**Expected result:** Chat widget demo page runs at `http://localhost:3000`.

**Files with hardcoded dev URLs (edit if you change the backend port):**
- Auto-init config: [chat-bubble/app/sdk.tsx](../../../chat-bubble/app/sdk.tsx) (Lines 44-55, default: `ws://localhost:8080`)
- API base URL: [chat-bubble/app/lib/api/client.ts](../../../chat-bubble/app/lib/api/client.ts) (Line 8, default: `http://localhost:8080/api`)

---

## Approach B: Full Stack Docker Development (Deploy Mode Dev)

This approach runs **everything** inside Docker containers using a single command.

### Step 1: Launch the Entire Stack

From the **project root**:
```bash
docker compose -f docker-compose.dev.yml up -d
```

**What this does:**
- Builds dev images using Dockerfiles:
  - [backend/docker/Dockerfile.dev](../../../backend/docker/Dockerfile.dev)
  - [frontend/docker/Dockerfile.dev](../../../frontend/docker/Dockerfile.dev)
  - [chat-bubble/docker/Dockerfile.dev](../../../chat-bubble/docker/Dockerfile.dev)
- Mounts local source code as volumes (changes reflect immediately)
- Starts all 6 services with these port mappings:

| Service | URL | Port Mapping |
| :--- | :--- | :--- |
| Chat Bubble | `http://localhost:3000` | Host `3000` → Container `5173` |
| Agent Console | `http://localhost:3001` | Host `3001` → Container `5173` |
| Go Backend API | `http://localhost:8080` | Host `8080` → Container `8080` |
| Delve Debugger | `localhost:2345` | Host `2345` → Container `2345` |
| PostgreSQL | `localhost:5433` | Host `5433` → Container `5432` |
| Mailhog Web UI | `http://localhost:8025` | Host `8025` → Container `8025` |

**File involved:** [docker-compose.dev.yml](../../../docker-compose.dev.yml)

---

### Step 2: Initialize the Database

After all containers are running, execute migrations and seeds **inside the backend container**:
```bash
docker compose -f docker-compose.dev.yml exec backend go run main.go migrate run
docker compose -f docker-compose.dev.yml exec backend go run main.go seed run
```

---

### Step 3: Verify All Services

Check that all containers are running:
```bash
docker compose -f docker-compose.dev.yml ps
```

**Expected:** All 6 services show status `Up`.

Verify the backend health endpoint:
```bash
curl http://localhost:8080/health
```

**Expected response:**
```json
{
  "status_code": 200,
  "status": "OK",
  "message": "health_check_completed"
}
```

View live backend logs:
```bash
docker compose -f docker-compose.dev.yml logs -f backend
```

---

### Step 4: Rebuild After Code Changes

If you modify a Dockerfile or `package.json`, rebuild:
```bash
# Rebuild all
docker compose -f docker-compose.dev.yml up -d --build

# Rebuild specific service
docker compose -f docker-compose.dev.yml up -d --build backend
```

---

## Testing Email

Both approaches use **Mailhog** as the development email server.
- **Web UI**: Open `http://localhost:8025` to view all emails sent by the backend
- **SMTP**: Backend connects to `localhost:1025` (Hybrid) or `mailhog:1025` (Docker)

---

## Quick Reference: All Accessible URLs

| What | Hybrid (Approach A) | Full Docker (Approach B) |
| :--- | :--- | :--- |
| Backend API | `http://localhost:8080` | `http://localhost:8080` |
| Backend Health | `http://localhost:8080/health` | `http://localhost:8080/health` |
| Agent Console | `http://localhost:3001` | `http://localhost:3001` |
| Chat Widget | `http://localhost:3000` | `http://localhost:3000` |
| Mailhog UI | `http://localhost:8025` | `http://localhost:8025` |
| PostgreSQL | `localhost:5433` | `localhost:5433` |
| Login | `admin@talkdeskly.com` / `password123` | `admin@talkdeskly.com` / `password123` |

---

## Files Referenced in This Guide

| File | Purpose |
| :--- | :--- |
| [docker-compose.dev.yml](../../../docker-compose.dev.yml) | Docker Compose orchestration for dev environment |
| [backend/.env](../../../backend/.env) | Backend environment configuration |
| [backend/docker/Dockerfile.dev](../../../backend/docker/Dockerfile.dev) | Backend dev container image |
| [frontend/docker/Dockerfile.dev](../../../frontend/docker/Dockerfile.dev) | Frontend dev container image |
| [chat-bubble/docker/Dockerfile.dev](../../../chat-bubble/docker/Dockerfile.dev) | Chat widget dev container image |
| [frontend/src/lib/api/client.ts](../../../frontend/src/lib/api/client.ts) | Frontend API base URL (hardcoded dev default) |
| [frontend/src/context/websocket-context.tsx](../../../frontend/src/context/websocket-context.tsx) | Frontend WebSocket URL (hardcoded dev default) |
| [chat-bubble/app/sdk.tsx](../../../chat-bubble/app/sdk.tsx) | Chat widget auto-init config (hardcoded dev default) |
| [chat-bubble/app/lib/api/client.ts](../../../chat-bubble/app/lib/api/client.ts) | Chat widget API base URL (hardcoded dev default) |
| [Operations Guide](../operations/README.md) | Full .env reference, Nginx, backups, troubleshooting |
