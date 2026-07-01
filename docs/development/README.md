# TalkDeskly Local Development Setup Guide

This guide provides instructions for setting up and running TalkDeskly locally for development, testing, and debugging purposes.

---

## 🏗️ Local Development Architecture

In local development, you can choose between two setup workflows:

* **Approach A (Hybrid)**: Run database and queue services in Docker, while running the React applications and Go backend directly on your host machine. *Highly recommended for active coding and step-by-step debugging.*
* **Approach B (Full Containerized - Deploy Mode Dev)**: Run the entire stack (including the frontend, widget, and Go server) inside Docker containers. *Perfect for running the exact development environment setup without installing Go or Node.js on your host.*

---

## 📋 Prerequisites

Depending on your chosen approach, ensure the following are installed:

| Dependency | Approach A (Hybrid) | Approach B (Full Docker) |
| :--- | :---: | :---: |
| **Docker Engine & Compose** | Yes | Yes |
| **Go Compiler (v1.21+)** | Yes | No |
| **Node.js (v18.0.0+) & npm** | Yes | No |
| **Air** (Go hot-reloading) | Yes | No (Bundled in container) |
| **Delve** (Go debugger) | Yes | No (Bundled in container) |

---

## 🛠️ Approach A: Hybrid Development (Recommended)

### Step 1: Start Containerized Services
Spin up local instances of PostgreSQL, Redis, and Mailhog:
```bash
docker compose -f docker-compose.dev.yml up -d postgres redis mailhog
```
* **PostgreSQL** binds to host port `5433` (to avoid conflict with default database installations).
* **Redis** binds to host port `6379`.
* **Mailhog** SMTP listens on port `1025`, and its Web GUI runs on port `8025`.

### Step 2: Configure and Run Backend
1. Navigate to the `backend` folder and copy `.env`:
   ```bash
   cd backend
   ```
2. Adjust your configuration variables inside `.env`:
   ```ini
   DATABASE_URL=postgres://postgres:postgres@localhost:5433/talkdeskly
   JWT_SECRET=secret
   PORT=6721
   REDIS_URL=localhost:6379
   EMAIL_HOST=localhost
   SUPPORTED_LANGUAGES=en,vi
   DEFAULT_LANGUAGE=en
   ```
3. Run database migrations to construct the schemas:
   ```bash
   go run main.go migrate run
   ```
4. Seed the database with sample data:
   ```bash
   go run main.go seed run
   ```
5. Start the server with `air` for hot-reloading:
   ```bash
   air
   ```
   *The server will start on port `6721`, with Delve debugger listener running on port `2345`.*

### Step 3: Run the Agent Console (Frontend)
1. Open a new terminal tab and navigate to the `frontend` folder:
   ```bash
   cd frontend
   npm install
   npm run dev
   ```
   *The dashboard will run locally at `http://localhost:3001`.*

### Step 4: Run the Chat Widget
1. Open a third terminal tab and navigate to the `chat-bubble` folder:
   ```bash
   cd chat-bubble
   npm install
   npm run dev
   ```
   *The chat bubble widget demo page will run at `http://localhost:3000`.*

---

## 🐳 Approach B: Full Stack Dockerized Development (Deploy Mode Dev)

This approach deploys all backend, frontend, and widget services inside container instances using volume binds, making development setup fast and consistent across systems.

### Step 1: Launch the Entire Compose Stack
From the project root directory, launch all services defined in `docker-compose.dev.yml`:
```bash
docker compose -f docker-compose.dev.yml up -d
```
This command performs the following:
* Automatically builds dev images for `backend`, `frontend`, and `chat-bubble`.
* Mounts local code directories as volumes to ensure changes reflect immediately.
* Maps ports to your host:
  - **Chat Bubble widget**: `http://localhost:3000`
  - **Agent Console dashboard**: `http://localhost:3001`
  - **Go Backend Server API**: `http://localhost:8080`
  - **Delve Debugger Interface**: Port `2345`

### Step 2: Initialize Database Inside the Container
Because the database runs containerized, you must run migrations and seeds inside the active backend container:

1. **Run Migrations**:
   ```bash
   docker compose -f docker-compose.dev.yml exec backend go run main.go migrate run
   ```
2. **Seed Database**:
   ```bash
   docker compose -f docker-compose.dev.yml exec backend go run main.go seed run
   ```

### Step 3: Check Container Status
Verify all services are up and healthy:
```bash
docker compose -f docker-compose.dev.yml ps
```
To view live logs from the backend server:
```bash
docker compose -f docker-compose.dev.yml logs -f backend
```

---

## 📧 Testing Email Deliverability
TalkDeskly uses **Mailhog** as an SMTP catch-all server during development in both setup workflows. 
* To view welcome messages, system alerts, or password resets sent by the backend, navigate to:
  `http://localhost:8025`
