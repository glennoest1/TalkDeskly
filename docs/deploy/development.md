# TalkDeskly Local Development Setup Guide

This guide provides instructions for setting up and running TalkDeskly locally for development, testing, and debugging purposes.

---

## 🏗️ Local Development Architecture

In development mode, the React applications (Frontend and Widget) run on hot-reloading Webpack/Vite servers, while the Go backend connects to containerized database, cache, and email testing instances.

```
+--------------------------------------------------------------+
|                       Local Machine                          |
|                                                              |
|   +------------------+             +-------------------+     |
|   |  Agent UI        |             |  Widget UI        |     |
|   |  (React/Vite)    |             |  (React/Vite)     |     |
|   |  Port 3001       |             |  Port 3000        |     |
|   +--------+---------+             +---------+---------+     |
|            |                                 |               |
|            +----------------+----------------+               |
|                             | (HTTP / WebSocket)             |
|                             v                                |
|                    +-----------------+                       |
|                    |  Go Backend     |                       |
|                    |  (Fiber/Air)    |                       |
|                    |  Port 6721/2345 |                       |
|                    +--------+--------+                       |
|                             |                                |
|            +----------------+----------------+               |
|            |                                 |               |
|            v                                 v               |
|    +---------------+                 +---------------+       |
|    |  PostgreSQL   |                 |  Redis        |       |
|    |  Port 5433    |                 |  Port 6379    |       |
|    +---------------+                 +---------------+       |
|                                                              |
+--------------------------------------------------------------+
```

---

## 📋 Prerequisites

Ensure you have the following installed locally:
* **Node.js** (v18.0.0 or higher) & **npm**
* **Go Compiler** (v1.21 or higher)
* **Docker Engine** & **Docker Compose**
* **Air** (for Go hot-reloading): `go install github.com/cosmtrek/air@latest`
* **Delve** (for Go debugging): `go install github.com/go-delve/delve/cmd/dlv@latest`

---

## 🛠️ Step-by-Step Setup

### Step 1: Start Containerized Services
Spin up local instances of PostgreSQL, Redis, and Mailhog:
```bash
docker compose -f docker-compose.dev.yml up -d postgres redis mailhog
```
* **PostgreSQL** is bound to host port `5433` (to avoid conflicts with local DB instances).
* **Redis** is bound to host port `6379`.
* **Mailhog** SMTP is on port `1025`, and its Web UI is on port `8025`.

---

### Step 2: Configure and Run Backend
1. Navigate to the `backend` folder:
   ```bash
   cd backend
   ```
2. Set up your environment file `.env`:
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
4. Seed the database with sample agents, companies, and conversations:
   ```bash
   go run main.go seed run
   ```
5. Start the server with `air` for automatic re-compilation on file changes:
   ```bash
   air
   ```
   *The server will start listening for requests on port `6721`, with Delve debugger listener running on port `2345`.*

---

### Step 3: Run the Agent Console (Frontend)
1. Open a new terminal tab and navigate to the `frontend` folder:
   ```bash
   cd frontend
   ```
2. Install npm packages:
   ```bash
   npm install
   ```
3. Start the development server:
   ```bash
   npm run dev
   ```
   *The dashboard will be active at `http://localhost:3001`.*

---

### Step 4: Run the Chat Widget
1. Open another terminal tab and navigate to the `chat-bubble` folder:
   ```bash
   cd chat-bubble
   ```
2. Install npm packages:
   ```bash
   npm install
   ```
3. Start the development server:
   ```bash
   npm run dev
   ```
   *The chat bubble widget demo page will run at `http://localhost:3000`.*

---

## 📧 Testing Email Deliverability
TalkDeskly uses **Mailhog** as an SMTP catch-all server during development. 
* To view system notification emails, welcome messages, or reset-password links sent by the backend, open your browser and navigate to:
  `http://localhost:8025`
