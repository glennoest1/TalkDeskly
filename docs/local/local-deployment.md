# TalkDeskly Local Deployment

This guide explains how to run TalkDeskly directly on the host machine: the Go backend, the admin frontend, and the chat widget run as host processes, while only the infrastructure dependencies (PostgreSQL, Redis, MailHog) run in Docker.

Use this mode when you want the fastest feedback loop, native debugger attachment from your IDE, or when Docker-based hot reload is too slow on your machine.

The deployment package in this folder contains:

| File | Purpose |
| --- | --- |
| `local-deployment.md` | Step-by-step local (host-run) deployment guide |

## Table Of Contents

- [1. What Local Mode Runs](#1-what-local-mode-runs)
  - [Local Architecture](#local-architecture)
    - [Local Communication Checks](#local-communication-checks)
- [2. How Backend Configuration Loading Works](#2-how-backend-configuration-loading-works)
- [3. Prerequisites](#3-prerequisites)
- [4. Published Ports](#4-published-ports)
- [5. Runtime Variables](#5-runtime-variables)
- [6. SMTP Host Rule](#6-smtp-host-rule)
- [7. Step-By-Step Deploy](#7-step-by-step-deploy)
  - [Step 0: Verify Prerequisites](#step-0-verify-prerequisites)
  - [Step 1: Start Dependency Containers](#step-1-start-dependency-containers)
  - [Step 2: Verify Dependencies](#step-2-verify-dependencies)
  - [Step 3: Review Backend Environment File](#step-3-review-backend-environment-file)
  - [Step 4: Start The Backend](#step-4-start-the-backend)
  - [Step 5: Start The Admin Frontend](#step-5-start-the-admin-frontend)
  - [Step 6: Start The Chat Widget](#step-6-start-the-chat-widget)
  - [Step 7: Seed Demo Data](#step-7-seed-demo-data)
  - [Step 8: Log In And Verify](#step-8-log-in-and-verify)
  - [Step 9: Test Email Delivery](#step-9-test-email-delivery)
- [8. Backend Hot Reload With Air](#8-backend-hot-reload-with-air)
- [9. Backend CLI Commands](#9-backend-cli-commands)
- [10. Local Widget Behavior](#10-local-widget-behavior)
- [11. Database Initialization](#11-database-initialization)
- [12. Troubleshooting](#12-troubleshooting)
  - [Backend Fails To Build](#backend-fails-to-build)
  - [Backend Starts Then Exits](#backend-starts-then-exits)
  - [Frontend Loads But API Calls Fail](#frontend-loads-but-api-calls-fail)
  - [Chat Widget Port Conflict](#chat-widget-port-conflict)
  - [Email Links Point To The Wrong URL](#email-links-point-to-the-wrong-url)
  - [Config Changes Are Ignored](#config-changes-are-ignored)
- [13. Stop The Local Environment](#13-stop-the-local-environment)
- [14. Copy-Paste Quick Start](#14-copy-paste-quick-start)

## 1. What Local Mode Runs

Local mode splits the stack between host processes and Docker containers:

| Component | Where it runs | How it runs |
| --- | --- | --- |
| `backend` | Host | `go run .` from `backend/` (or Air for hot reload) |
| `frontend` | Host | `npm run dev` from `frontend/` (Vite, port `5173`) |
| `chat-bubble` | Host | `npm run dev -- --port 3000` from `chat-bubble/` (Vite) |
| `postgres` | Docker | `docker compose -f docker-compose.dev.yml up -d postgres` |
| `redis` | Docker | `docker compose -f docker-compose.dev.yml up -d redis` |
| `mailhog` | Docker | `docker compose -f docker-compose.dev.yml up -d mailhog` |

How local mode compares to the other modes:

| Area | Local mode | Development mode (Docker) | Production mode |
| --- | --- | --- | --- |
| Backend | `go run .` on host, port `6721` | Air inside container, port `8080` (+ `6721` alias) | Compiled binary in image, port `8080` |
| Admin frontend | Vite on host, port `5173` | Vite container, host port `3001` | Static files served by backend |
| Chat widget | Vite on host, port `3000` (recommended) | Vite container, host port `3000` | Built SDK at `/sdk/sdk.iife.js` |
| Backend config source | `backend/.env` via `godotenv` | Environment set in `docker-compose.dev.yml` | Shell or root `.env` via Compose |
| Debugging | Native IDE debugger against host process | Delve through container port `2345` | Not intended |
| Node/Go tooling | Required on host | Optional on host | Required on host for asset builds |

The frontend and widget development code hard-codes `http://localhost:6721` as the backend URL. In local mode this works without any alias because `backend/.env` sets `PORT=6721`, so the host backend listens on `6721` directly.

The local startup env is organized in [Startup Environment Variables](../startup-environment.md). If `backend/.env` needs to be recreated, copy `env/local.env.example` to `backend/.env`.

### Local Architecture

Who talks to whom in local mode:

```mermaid
flowchart LR
    B(["Browser"])

    subgraph Host["Host processes"]
        FE["frontend :5173"]
        CB["chat-bubble :3000"]
        BE["backend :6721"]
    end

    subgraph Docker["Docker containers"]
        PG[("postgres :5433")]
        RD[("redis :6379")]
        MH["mailhog :1025 / :8025"]
    end

    B -->|":5173"| FE
    B -->|":3000"| CB
    B -->|":6721 api + ws"| BE
    B -->|":8025"| MH
    BE -->|":5433"| PG
    BE -->|":6379"| RD
    BE -->|":1025"| MH
```

Every edge is a `localhost` port: the browser reaches the three host processes directly, and the backend reaches the containers through their published host ports.

Every connection in local mode:

| From | To | Address used | Protocol | Purpose |
| --- | --- | --- | --- | --- |
| Browser | frontend host process | `http://localhost:5173` | HTTP | Load the admin app (Vite dev server) |
| Browser | chat-bubble host process | `http://localhost:3000` | HTTP | Load the widget dev page (Vite dev server) |
| Browser | backend host process | `http://localhost:6721/api` | HTTP | REST calls made by admin app JS and widget JS |
| Browser | backend host process | `ws://localhost:6721/ws` | WebSocket | Realtime events for agents and widget visitors. Widget config still uses HTTP `baseUrl`; the SDK derives the WebSocket route from it. |
| Browser | `mailhog` container | `http://localhost:8025` | HTTP | Read captured emails |
| Backend host process | `postgres` container | `localhost:5433` | TCP | Database, via the published host port |
| Backend host process | `redis` container | `localhost:6379` | TCP | Background jobs and realtime support |
| Backend host process | `mailhog` container | `localhost:1025` | SMTP | Outgoing email capture |

Two rules that explain the whole picture:

1. There is exactly one address plane in local mode: everything is `localhost`. Compose service names such as `postgres` or `mailhog` are never used, because no application code runs inside the Docker network.
2. The Docker boundary is crossed in the opposite direction compared to development mode: the backend reaches *into* Docker through the published host ports (`5433`, `6379`, `1025`), while in development mode the browser reaches into Docker and the backend talks to its dependencies internally. This is why `DATABASE_URL` uses `localhost:5433` here but `postgres:5432` in the development Compose file, and why `EMAIL_HOST=localhost` is correct here but wrong there.

#### Local Communication Checks

| Check | Expected result |
| --- | --- |
| `curl http://localhost:6721/health` | Backend health responds from the host process |
| Browser devtools on admin frontend | API calls go to `http://localhost:6721/api` |
| Browser devtools on widget page | Public inbox REST calls go to `http://localhost:6721/api`; contact WebSocket goes to `/ws/contacts` on the same origin |
| Backend terminal | No database, Redis, or SMTP connection errors |

## 2. How Backend Configuration Loading Works

Understanding this prevents most local-mode confusion. On startup, the backend resolves configuration in this priority order (later wins):

| Priority | Source | Notes |
| --- | --- | --- |
| 1 (lowest) | Built-in defaults in `backend/config/config.go` | For example `PORT=3000`, `EMAIL_HOST=mailhog`, `BASE_URL=http://localhost:6721` |
| 2 | Environment variables | `godotenv.Load()` reads `backend/.env` into the environment; variables already set in your shell win over `.env` values |
| 3 (highest) | `backend/storage/config.json` | Written by the `config:set` style setters and the admin runtime; any key present here silently overrides both defaults and environment |

Practical rules:

1. Run the backend from the `backend/` directory. Both `.env` and `storage/config.json` are resolved relative to the working directory.
2. If a value in `backend/.env` appears to be ignored, check whether the same variable is set in your shell or whether `backend/storage/config.json` exists and contains that key.
3. The backend reads `ENVIRONMENT`, not `GO_ENV`. The default is `development`.

## 3. Prerequisites

Install these tools on the host machine:

| Tool | Needed for | Version requirement |
| --- | --- | --- |
| Go | Backend | `1.24.1` or newer (from `backend/go.mod`) |
| C compiler (gcc) | Backend build | Required: `github.com/chai2010/webp` is a cgo package |
| Node.js + npm | Frontend and chat widget | 18.x or newer; 20.x recommended (matches the Docker dev images) |
| Docker + Docker Compose | Postgres, Redis, MailHog dependency containers | Compose v2 |
| curl or browser | Verify HTTP routes | any |

C compiler installation by platform:

| Platform | Recommended toolchain |
| --- | --- |
| Windows | MSYS2 with `mingw-w64-ucrt-x86_64-gcc` (add its `bin` directory to `PATH`), or TDM-GCC |
| macOS | Xcode Command Line Tools: `xcode-select --install` |
| Linux | `build-essential` (Debian/Ubuntu) or `gcc` package |

On Windows PowerShell, use `npm.cmd` if `npm` is blocked by execution policy.

## 4. Published Ports

Local mode uses these host ports:

| Host port | Component | Purpose |
| --- | --- | --- |
| `6721` | backend (host process) | REST API and WebSocket server, from `backend/.env` `PORT=6721` |
| `5173` | frontend (host process) | Admin/agent frontend Vite dev server (Vite default) |
| `3000` | chat-bubble (host process) | Chat widget Vite dev server (recommended explicit `--port 3000`) |
| `5433` | `postgres` container | PostgreSQL, published by `docker-compose.dev.yml` |
| `6379` | `redis` container | Redis, published by `docker-compose.dev.yml` |
| `1025` | `mailhog` container | SMTP capture endpoint |
| `8025` | `mailhog` container | MailHog web inbox |

Do not change the backend port `6721` unless you also update the hard-coded development URLs in `frontend/src/lib/api/client.ts`, `frontend/src/context/websocket-context.tsx`, `chat-bubble/app/lib/api/client.ts`, and `chat-bubble/app/sdk.tsx`.

## 5. Runtime Variables

Local mode reads backend variables from `backend/.env`. The file is local-development configuration only and should be treated as disposable:

| Variable | Expected local shape | Purpose |
| --- | --- | --- |
| `DATABASE_URL` | PostgreSQL URL for the dependency container published to the host | Backend database connection |
| `JWT_SECRET` | local throwaway secret | Token signing for local logins only |
| `PORT` | local backend port used in [Local Architecture](#local-architecture) | Matches the hard-coded frontend and widget development URLs |
| `REDIS_URL` | Redis host-port address for the dependency container | Background jobs and realtime support |
| `EMAIL_HOST` | host address for MailHog | Correct in local mode; see [section 6](#6-smtp-host-rule) |

Variables not present in `backend/.env` fall back to built-in defaults. The defaults that matter in local mode:

| Variable | Default | Effect in local mode |
| --- | --- | --- |
| `EMAIL_PORT` | MailHog SMTP port | Matches the dependency container SMTP endpoint |
| `EMAIL_PROVIDER` | SMTP sender provider | Plain SMTP sender, works with MailHog |
| `EMAIL_FROM` | local sender email | Sender shown in MailHog |
| `BASE_URL` | local backend HTTP origin | Backend URL used in generated links |
| `FRONTEND_URL` | frontend HTTP origin | Must match the frontend port used in local mode |
| `ENVIRONMENT` | development environment name | Development behavior without extra setup |

Recommended addition for local mode: set `FRONTEND_URL` in `backend/.env` to the local frontend origin so email links (invites, password resets) point at the right place.

These local values are for local use only. Never reuse them, or this file pattern, for a real deployment.

## 6. SMTP Host Rule

The SMTP rule is the opposite of the Docker guides here, and this is intentional:

| Where the backend runs | Correct `EMAIL_HOST` for MailHog |
| --- | --- |
| On the host (this guide) | `localhost`  -  MailHog publishes port `1025` to the host |
| Inside a Compose container (development guide) | `mailhog`  -  the Compose service name |

`backend/.env` already sets `EMAIL_HOST=localhost`, which is correct for local mode. If you copy values between this mode and the Docker modes, this is the variable that breaks.

## 7. Step-By-Step Deploy

Run these commands from the repository root unless stated otherwise.

You will need three long-running terminals: one for the backend, one for the frontend, one for the chat widget. Steps 4, 5, and 6 each occupy one terminal.

### Step 0: Verify Prerequisites

Verify tool availability first:

```bash
go version
gcc --version
node --version
npm --version
docker --version
docker compose version
```

Expected result: each command prints a version and exits without error. `go version` must report `go1.24.1` or newer.

Then confirm the required host ports are free: `6721`, `5173`, `3000`, `5433`, `6379`, `1025`, `8025`.

Linux/macOS:

```bash
for p in 6721 5173 3000 5433 6379 1025 8025; do lsof -iTCP:$p -sTCP:LISTEN; done
```

Windows PowerShell:

```powershell
Get-NetTCPConnection -State Listen | Where-Object { $_.LocalPort -in 6721,5173,3000,5433,6379,1025,8025 }
```

Expected result: no output means all ports are free. If the full Docker development stack is currently running, stop it first  -  it occupies `3000`, `6721`, `5433`, `6379`, `1025`, and `8025`:

```bash
docker compose -f docker-compose.dev.yml down
```

### Step 1: Start Dependency Containers

Start only the infrastructure services from the development Compose file:

```bash
docker compose -f docker-compose.dev.yml up -d postgres redis mailhog
```

This does not start the `backend`, `frontend`, or `chat-bubble` containers  -  those roles are filled by host processes in this mode.

### Step 2: Verify Dependencies

```bash
docker ps --filter "name=talkdeskly"
docker compose -f docker-compose.dev.yml exec postgres pg_isready -U postgres
docker compose -f docker-compose.dev.yml exec redis redis-cli ping
curl -I http://localhost:8025/
```

Expected result:

| Check | Expected result |
| --- | --- |
| `docker ps` | Exactly three containers: `postgres`, `redis`, `mailhog` (prefix `talkdeskly-`), `mailhog` reaching `healthy` |
| `pg_isready` | `accepting connections` |
| `redis-cli ping` | `PONG` |
| MailHog web UI | HTTP `200` |

### Step 3: Review Backend Environment File

Open `backend/.env` and confirm it contains the values listed in [section 5](#5-runtime-variables). If you followed the recommendation, it also ends with `FRONTEND_URL=http://localhost:5173`.

Also confirm no leftover override file exists:

```bash
ls backend/storage/config.json
```

Expected result: file not found. If the file exists from earlier experiments, remember its keys override `.env` (see [section 2](#2-how-backend-configuration-loading-works)); delete it or reconcile its contents before continuing.

### Step 4: Start The Backend

In terminal 1:

```bash
cd backend
go run .
```

The first run downloads Go modules and compiles the cgo webp dependency; this can take a few minutes. Later runs are fast.

Expected startup behavior:

| Signal | Meaning |
| --- | --- |
| GORM `AutoMigrate` log lines | Database schema created/updated on `localhost:5433` |
| No SMTP connection error | MailHog reachable at `localhost:1025` |
| Fiber banner showing port `6721` | Server listening |

Verify from a separate terminal:

```bash
curl http://localhost:6721/health
```

Expected result: HTTP `200` with health JSON.

### Step 5: Start The Admin Frontend

In terminal 2:

```bash
cd frontend
npm install
npm run dev
```

Windows PowerShell:

```powershell
Set-Location frontend
npm.cmd install
npm.cmd run dev
```

Expected result: Vite reports the dev server at `http://localhost:5173/`.

Start the frontend before the chat widget. Both apps default to Vite port `5173`; the first one started claims it.

### Step 6: Start The Chat Widget

In terminal 3:

```bash
cd chat-bubble
npm install
npm run dev -- --port 3000
```

Windows PowerShell:

```powershell
Set-Location chat-bubble
npm.cmd install
npm.cmd run dev -- --port 3000
```

Expected result: Vite reports the dev server at `http://localhost:3000/`.

The explicit `--port 3000` keeps the widget on the same URL as Docker development mode, so the widget instructions in the development guide apply unchanged. If you omit it and the frontend already holds `5173`, Vite auto-shifts the widget to `5174` and prints a warning  -  that also works, but the URLs in this guide assume `3000`.

### Step 7: Seed Demo Data

For local testing only, seed demo data while the backend is running. In a separate terminal:

```bash
cd backend
go run . seed run
```

The seed command creates a demo admin account:

```text
Email: admin@talkdeskly.com
Password: password123
```

It also creates sample companies, agents, inboxes, contacts, conversations, and messages.

### Step 8: Log In And Verify

Open the admin frontend:

```text
http://localhost:5173
```

Log in with the seeded admin account. Then verify the full loop:

| Check | Expected result |
| --- | --- |
| Login at `http://localhost:5173` | Succeeds; browser devtools shows API calls to `http://localhost:6721/api` returning `200` |
| WebSocket | Devtools network tab shows a connection to `ws://localhost:6721/ws` |
| Widget page `http://localhost:3000` | Chat bubble renders; see [section 10](#10-local-widget-behavior) to point it at a real inbox |

### Step 9: Test Email Delivery

Trigger a flow that sends email, such as an agent invite or password reset, then open:

```text
http://localhost:8025
```

Expected result:

| Check | Expected result |
| --- | --- |
| Backend terminal | No SMTP connection error |
| MailHog inbox | Captured email appears in the web UI |
| Email links | Point to `http://localhost:5173/...` when `FRONTEND_URL` is set as recommended |

## 8. Backend Hot Reload With Air

`go run .` does not restart on file changes. For hot reload on the host, install Air (the same tool the Docker development image uses):

```bash
go install github.com/cosmtrek/air@latest
```

Then run it from the backend directory, where it picks up the committed `backend/.air.toml`:

```bash
cd backend
air
```

Air rebuilds when Go, template, and HTML files change. Build errors are written to `backend/build-errors.log`. Make sure `$(go env GOPATH)/bin` is on your `PATH` so the `air` binary is found.

Alternatively, attach your IDE debugger directly to the `go run .` process or launch `backend/main.go` from the IDE  -  no Delve port forwarding is needed in local mode.

## 9. Backend CLI Commands

In local mode, CLI commands run directly with `go run .` from the `backend/` directory and use the same `backend/.env` configuration:

```bash
cd backend
go run . --help
go run . db status
go run . migrate run
go run . seed run
go run . seed clear --force
go run . config:show
```

To build a reusable binary instead of compiling on every invocation:

```bash
cd backend
./build-cli.sh
./talkdeskly --help
```

Windows PowerShell equivalent:

```powershell
Set-Location backend
go build -o talkdeskly.exe .
.\talkdeskly.exe --help
```

## 10. Local Widget Behavior

The widget behaves exactly as in Docker development mode, because the same Vite dev server and the same hard-coded development config are used. The complete widget workflow  -  choosing an inbox, finding inbox IDs, end-to-end conversation testing, and resetting browser state  -  is documented in the development guide and applies verbatim here:

| Topic | Reference |
| --- | --- |
| Widget URL model (`baseUrl` must be an HTTP origin) | [Development guide, section 11](../dev/development-deployment.md#widget-url-model) |
| Test any inbox by editing `chat-bubble/app/sdk.tsx` | [Development guide, section 11](../dev/development-deployment.md#test-any-inbox-in-chat-bubble-dev-mode) |
| Find a test inbox ID | [Development guide, section 11](../dev/development-deployment.md#find-a-test-inbox-id) |
| End-to-end widget test | [Development guide, section 11](../dev/development-deployment.md#end-to-end-widget-test) |
| Reset browser widget state | [Development guide, section 11](../dev/development-deployment.md#reset-browser-widget-state) |

Two local-mode specifics:

1. The `baseUrl` in the `import.meta.env.DEV` block of `chat-bubble/app/sdk.tsx` stays `http://localhost:6721`  -  in local mode this is the backend's real listen address, not a Compose alias.
2. When querying Postgres for inbox IDs, connect from the host through port `5433`, or reuse the `docker compose ... exec postgres psql` commands from the development guide unchanged.

## 11. Database Initialization

The backend connects to PostgreSQL and runs GORM `AutoMigrate` during startup  -  no manual migration step is needed for a fresh database.

Seed data is optional and for local demos only:

```bash
cd backend
go run . seed run
```

To clear seeded data while preserving schema:

```bash
cd backend
go run . seed clear --force
```

To reset the local database completely, remove the dependency volumes and restart:

```bash
docker compose -f docker-compose.dev.yml down -v
docker compose -f docker-compose.dev.yml up -d postgres redis mailhog
```

Then restart the backend so `AutoMigrate` recreates the schema. This deletes local Postgres, Redis, and MailHog data.

## 12. Troubleshooting

### Backend Fails To Build

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `cgo: C compiler "gcc" not found` | No C toolchain installed | Install gcc per [section 3](#3-prerequisites) and reopen the terminal |
| Errors compiling `chai2010/webp` | Toolchain incomplete or wrong architecture | On Windows use the `ucrt64` MSYS2 environment; confirm `gcc --version` runs in the same terminal |
| `go: go.mod requires go >= 1.24.1` | Old Go version | Upgrade Go |

### Backend Starts Then Exits

Check the terminal output from `go run .` directly  -  in local mode there is no container restart policy hiding the error.

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Database connection refused | Dependency containers not running | Run [Step 1](#step-1-start-dependency-containers) and [Step 2](#step-2-verify-dependencies) |
| Database auth or DSN error | `DATABASE_URL` edited or shell variable overriding `.env` | Confirm `postgres://postgres:postgres@localhost:5433/talkdeskly`; run `go run . db status` |
| Port already in use on `6721` | Docker dev stack still running (it publishes `6721`), or a stale backend process | `docker compose -f docker-compose.dev.yml down`, or kill the stale process |
| SMTP connection refused | MailHog not running, or `EMAIL_HOST` changed away from `localhost` | Check `mailhog` container health and `backend/.env` |
| Redis connection error | Redis container not running or `REDIS_URL` wrong | Expect `localhost:6379` in `backend/.env` |

### Frontend Loads But API Calls Fail

In local mode the browser must reach the backend at `http://localhost:6721`. Check:

1. `curl http://localhost:6721/health` returns `200`.
2. The backend terminal shows the Fiber banner with port `6721`  -  if it shows `3000`, the process was started outside `backend/` and never loaded `backend/.env`; restart it from the `backend/` directory.
3. No shell variable `PORT` overrides the `.env` value (run `echo $PORT` / `$env:PORT`).

### Chat Widget Port Conflict

If Vite reports `Port 3000 is in use`, the Docker dev stack's `chat-bubble` container is probably still running. Stop it, or pick another port and use that URL instead:

```bash
npm run dev -- --port 3002
```

### Email Links Point To The Wrong URL

Invite and reset links are built from `FRONTEND_URL`, which defaults to `http://localhost:3001` (the Docker dev frontend). Add `FRONTEND_URL=http://localhost:5173` to `backend/.env` and restart the backend, as described in [section 5](#5-runtime-variables).

### Config Changes Are Ignored

Priority is defaults -> environment (including `backend/.env`) -> `backend/storage/config.json`. If an edit to `backend/.env` has no effect:

1. Check `backend/storage/config.json`  -  any key present there wins. Delete the file or remove the key.
2. Check your shell: variables already exported win over `.env` values because `godotenv.Load()` does not overwrite existing environment variables.
3. Restart the backend  -  configuration is read at startup.

## 13. Stop The Local Environment

Stop the host processes with `Ctrl+C` in each of the three terminals (backend, frontend, chat-bubble).

Stop the dependency containers while keeping data:

```bash
docker compose -f docker-compose.dev.yml stop postgres redis mailhog
```

Or stop and remove the containers, keeping volumes:

```bash
docker compose -f docker-compose.dev.yml down
```

Remove volumes only for a disposable local reset:

```bash
docker compose -f docker-compose.dev.yml down -v
```

Do not remove volumes unless a data reset is explicitly intended.

## 14. Copy-Paste Quick Start

The full sequence from a clean checkout to a working local environment. Run [Step 0](#step-0-verify-prerequisites) first to confirm tools and free ports. Terminals 1-3 stay running.

Terminal 0 (setup):

```bash
# Step 1: start dependencies
docker compose -f docker-compose.dev.yml up -d postgres redis mailhog

# Step 2: verify dependencies
docker compose -f docker-compose.dev.yml exec postgres pg_isready -U postgres
docker compose -f docker-compose.dev.yml exec redis redis-cli ping
curl -I http://localhost:8025/
```

Terminal 1 (backend):

```bash
cd backend
go run .
```

Terminal 2 (admin frontend):

```bash
cd frontend
npm install
npm run dev
```

Terminal 3 (chat widget):

```bash
cd chat-bubble
npm install
npm run dev -- --port 3000
```

Terminal 0 again (seed and verify):

```bash
# Step 4 verification
curl http://localhost:6721/health

# Step 7: seed demo data
cd backend && go run . seed run && cd ..
```

Then open in the browser:

| URL | What to do |
| --- | --- |
| `http://localhost:5173` | Log in with `admin@talkdeskly.com` / `password123` |
| `http://localhost:3000` | Chat widget dev page; see [section 10](#10-local-widget-behavior) to point it at a real inbox |
| `http://localhost:8025` | MailHog inbox for captured emails |

On Windows PowerShell, replace `curl` with `curl.exe`, `npm` with `npm.cmd`, and `cd backend && go run . seed run && cd ..` with `Set-Location backend; go run . seed run; Set-Location ..`.
