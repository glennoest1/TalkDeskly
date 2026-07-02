# TalkDeskly Development Deployment

This guide explains how to build and run TalkDeskly in development mode with Docker Compose.

The deployment package in this folder contains:

| File | Purpose |
| --- | --- |
| `development-deployment.md` | Step-by-step development deployment guide |

## 1. What Development Mode Runs

Development mode runs the backend, admin frontend, chat widget, database, Redis, and a local SMTP test server as separate containers.

The development stack runs:

| Service | Purpose |
| --- | --- |
| `backend` | Go/Fiber backend, REST API, WebSocket routes, CLI commands, hot reload through Air |
| `frontend` | Vite development server for the admin/agent frontend |
| `chat-bubble` | Vite development server for the embeddable chat widget SDK app |
| `postgres` | PostgreSQL database for local development data |
| `redis` | Redis for background jobs and realtime support |
| `mailhog` | Local SMTP capture server and web inbox for email testing |

Development mode differs from production mode in these important ways:

| Area | Development mode | Production mode |
| --- | --- | --- |
| Frontend delivery | Separate Vite container | Static files served by backend |
| Chat widget delivery | Separate Vite container | Built SDK served from backend `/sdk/sdk.iife.js` |
| Backend runtime | Source mounted into container and rebuilt by Air | Compiled binary inside production image |
| Email delivery | MailHog test SMTP service | SMTP provider from runtime configuration |
| Restart policy | No explicit restart policy | `unless-stopped` for runtime services |

Development mode is for local feature work, debugging, and integration testing. Do not use it for a real production deployment.

## 2. Docker Compose Development Build

`docker-compose.dev.yml` builds three local development images:

```yaml
services:
  backend:
    build:
      context: ./backend
      dockerfile: docker/Dockerfile.dev
  frontend:
    build:
      context: ./frontend
      dockerfile: docker/Dockerfile.dev
  chat-bubble:
    build:
      context: ./chat-bubble
      dockerfile: docker/Dockerfile.dev
```

The build contexts are intentionally scoped to each application folder.

| Image | Build context | Dockerfile | Runtime command |
| --- | --- | --- | --- |
| Backend dev image | `./backend` | `backend/docker/Dockerfile.dev` | `air` |
| Frontend dev image | `./frontend` | `frontend/docker/Dockerfile.dev` | `npm run dev -- --host` |
| Chat widget dev image | `./chat-bubble` | `chat-bubble/docker/Dockerfile.dev` | `npm run dev -- --host` |

The backend image installs Go build dependencies and Air. The frontend and chat widget images install npm dependencies and run Vite in host-accessible mode.

## 3. Source Mounts And Hot Reload

Development Compose mounts source folders into each app container:

| Service | Host path | Container path | Effect |
| --- | --- | --- | --- |
| `backend` | `./backend` | `/app` | Go source changes are rebuilt by Air |
| `frontend` | `./frontend` | `/app` | Vite sees frontend source changes |
| `chat-bubble` | `./chat-bubble` | `/app` | Vite sees widget source changes |

The Node services also mount an anonymous `/app/node_modules` volume:

```yaml
volumes:
  - ./frontend:/app
  - /app/node_modules
```

This keeps container-installed dependencies from being overwritten by the host source bind mount.

## 4. Prerequisites

Install these tools on the development machine:

| Tool | Needed for |
| --- | --- |
| Docker + Docker Compose | Build and run the full development stack |
| Git | Clone and update the repository |
| curl or browser | Verify HTTP routes |
| Go | Optional, only needed when running backend commands directly on the host |
| Node.js + npm | Optional, only needed when running frontend or chat-bubble directly on the host |

On Windows PowerShell, use `npm.cmd` if `npm` is blocked by execution policy.

## 5. Published Ports

Development mode publishes these ports to the host:

| Host port | Container/service | Purpose |
| --- | --- | --- |
| `3000` | `chat-bubble:5173` | Chat widget Vite development server |
| `3001` | `frontend:5173` | Admin/agent frontend Vite development server |
| `8080` | `backend:8080` | Backend REST API and WebSocket server |
| `2345` | `backend:2345` | Delve debugger endpoint configured by Air |
| `5433` | `postgres:5432` | PostgreSQL access from host tools |
| `6379` | `redis:6379` | Redis access from host tools |
| `1025` | `mailhog:1025` | Local SMTP endpoint |
| `8025` | `mailhog:8025` | MailHog web inbox |

If a port is already in use, edit the left side of the relevant mapping in `docker-compose.dev.yml`.

Example:

```yaml
ports:
  - "3002:5173"
```

The right side is the port inside the container and should usually stay unchanged.

## 6. Runtime Variables

Development mode defines runtime variables directly in `docker-compose.dev.yml`.

Do not commit real secrets. If you need machine-specific overrides, prefer a local override file such as `docker-compose.override.yml` that is not committed.

Variable reference:

| Variable | Service | Required | Sensitivity | Purpose | Value |
| --- | --- | --- | --- | --- | --- |
| `NODE_ENV` | `frontend`, `chat-bubble` | yes | public config | Enables Node development behavior | `unspecified` |
| `VITE_API_URL` | `chat-bubble` | intended | public config | Intended API base URL for widget dev runtime | `unspecified` |
| `VITE_WS_URL` | `chat-bubble` | intended | public config | Intended WebSocket URL for widget dev runtime | `unspecified` |
| `GO_ENV` | `backend` | yes | public config | Marks backend runtime as development mode in Compose | `unspecified` |
| `DATABASE_URL` | `backend` | yes | secret/internal | Backend PostgreSQL connection string | `[redacted]` |
| `PORT` | `backend` | yes | public config | Backend listen port inside the container | `unspecified` |
| `JWT_SECRET` | `backend` | yes | secret | Local token signing secret | `[redacted]` |
| `BASE_URL` | `backend` | yes | public config | Backend base URL for generated links and widget integration | `unspecified` |
| `REDIS_URL` | `backend` | yes | internal config | Redis address used by backend services | `unspecified` |
| `EMAIL_HOST` | `backend` | yes | internal config | SMTP host reachable from backend container | `unspecified` |
| `EMAIL_PORT` | `backend` | yes | internal config | SMTP port reachable from backend container | `unspecified` |
| `EMAIL_USERNAME` | `backend` | optional | secret | SMTP username when the provider requires auth | `[redacted]` |
| `EMAIL_PASSWORD` | `backend` | optional | secret | SMTP password when the provider requires auth | `[redacted]` |
| `EMAIL_FROM` | `backend` | yes | public config | Sender address used by backend emails | `unspecified` |
| `POSTGRES_USER` | `postgres` | yes | internal config | Local database user | `unspecified` |
| `POSTGRES_PASSWORD` | `postgres` | yes | secret | Local database password | `[redacted]` |
| `POSTGRES_DB` | `postgres` | yes | internal config | Local database name | `unspecified` |
| `MH_STORAGE` | `mailhog` | yes | internal config | MailHog message storage mode | `unspecified` |
| `MH_MAILDIR_PATH` | `mailhog` | yes | internal config | MailHog storage directory inside container | `unspecified` |

### Config Name Warning

The backend config loader reads `ENVIRONMENT`, not `GO_ENV`.

`docker-compose.dev.yml` currently sets `GO_ENV`. That value may be useful for conventions or future code, but it does not populate `config.App.Environment` in the current backend config loader.

If backend behavior must depend on the environment name, set `ENVIRONMENT` as well.

### Frontend API URL Warning

The current frontend and chat-bubble source code hard-codes development API and WebSocket URLs in these files:

| File | Current behavior |
| --- | --- |
| `frontend/src/lib/api/client.ts` | Uses a hard-coded development API base URL |
| `frontend/src/context/websocket-context.tsx` | Uses a hard-coded development WebSocket URL |
| `chat-bubble/app/lib/api/client.ts` | Uses a hard-coded development API base URL |
| `chat-bubble/app/sdk.tsx` | Auto-initializes the widget in development with a hard-coded base URL |

Because of that, the `VITE_API_URL` and `VITE_WS_URL` values in `docker-compose.dev.yml` are not currently consumed by those clients.

Before relying on the Compose-published backend URL, either:

1. Update the frontend and widget clients to read `import.meta.env.VITE_API_URL` and `import.meta.env.VITE_WS_URL`.
2. Or align the backend host port with the hard-coded development URLs.

This is the main configuration mismatch to check if the frontend loads but API or WebSocket calls fail.

## 7. SMTP Host Rule

In Docker Compose, services should talk to each other by service name.

The backend should use the MailHog Compose service as its SMTP host. Do not use `localhost` unless the SMTP server runs inside the backend container itself.

From inside a Docker container, `localhost` means that same container.

Use this pattern:

| SMTP location | `EMAIL_HOST` pattern |
| --- | --- |
| MailHog in this Compose stack | service name |
| SMTP server on Docker Desktop host | `host.docker.internal` |
| External SMTP provider | provider hostname |

Open the MailHog web inbox after the stack is running:

```text
http://localhost:8025
```

## 8. Step-By-Step Deploy

Run these commands from the repository root unless stated otherwise.

### Step 1: Build Development Images

```bash
docker compose -f docker-compose.dev.yml build
```

To rebuild only one service:

```bash
docker compose -f docker-compose.dev.yml build backend
docker compose -f docker-compose.dev.yml build frontend
docker compose -f docker-compose.dev.yml build chat-bubble
```

### Step 2: Start The Development Stack

```bash
docker compose -f docker-compose.dev.yml up -d
```

If source dependencies or Dockerfiles changed and you want Compose to rebuild before starting:

```bash
docker compose -f docker-compose.dev.yml up -d --build
```

### Step 3: Watch Startup Logs

```bash
docker compose -f docker-compose.dev.yml logs -f backend
```

In a second terminal, check the Vite services:

```bash
docker compose -f docker-compose.dev.yml logs -f frontend
docker compose -f docker-compose.dev.yml logs -f chat-bubble
```

Expected behavior:

| Service | Expected startup signal |
| --- | --- |
| `backend` | Air builds and starts the Go server |
| `frontend` | Vite reports a network-accessible dev server |
| `chat-bubble` | Vite reports a network-accessible dev server |
| `postgres` | Container is running and accepts database connections |
| `redis` | Container is running |
| `mailhog` | Healthcheck passes |

### Step 4: Check Containers

```bash
docker ps --filter "name=talkdeskly"
```

Expected result:

| Container | Expected status |
| --- | --- |
| `talkdeskly-backend-1` | `Up` and not restarting |
| `talkdeskly-frontend-1` | `Up` |
| `talkdeskly-chat-bubble-1` | `Up` |
| `talkdeskly-postgres-1` | `Up` |
| `talkdeskly-redis-1` | `Up` |
| `talkdeskly-mailhog-1` | `healthy` |

If Compose uses a different project name, the container prefix may differ.

### Step 5: Verify HTTP Routes

```bash
curl http://localhost:8080/health
curl -I http://localhost:3001/
curl -I http://localhost:3000/
curl -I http://localhost:8025/
```

Expected result:

| URL | Expected result |
| --- | --- |
| `http://localhost:8080/health` | HTTP `200` with health JSON |
| `http://localhost:3001/` | HTTP `200`, admin frontend Vite app |
| `http://localhost:3000/` | HTTP `200`, chat widget Vite app |
| `http://localhost:8025/` | HTTP `200`, MailHog web UI |

Then open:

```text
http://localhost:3001
http://localhost:3000
http://localhost:8025
```

### Step 6: Seed Demo Data

For local testing only, seed demo data after the backend is running:

```bash
docker compose -f docker-compose.dev.yml exec backend go run . seed run
```

The seed command creates a demo admin account:

```text
Email: admin@talkdeskly.com
Password: password123
```

Use it to log in at the admin frontend:

```text
http://localhost:3001
```

The seed command also creates sample companies, agents, inboxes, contacts, conversations, and messages.

### Step 7: Test Backend CLI Commands

The backend CLI can be run inside the development container with `go run .`.

```bash
docker compose -f docker-compose.dev.yml exec backend go run . --help
docker compose -f docker-compose.dev.yml exec backend go run . db status
docker compose -f docker-compose.dev.yml exec backend go run . seed run
```

Use these commands for development checks without building a host binary.

### Step 8: Test Email Delivery

Trigger a flow that sends email, such as invite or password reset, then open:

```text
http://localhost:8025
```

Expected result:

| Check | Expected result |
| --- | --- |
| Backend logs | No SMTP connection error |
| MailHog inbox | Captured email appears in web UI |
| Email links | Links point to the configured frontend URL or backend URL for the tested flow |

If emails do not appear, check `EMAIL_HOST`, `EMAIL_PORT`, backend logs, and whether the flow actually sends email.

## 9. Backend Hot Reload And Debugging

The backend development image runs Air:

```text
CMD ["air"]
```

Air reads:

```text
backend/.air.toml
```

The current Air config builds the backend when Go/template files change and exposes a Delve endpoint through the backend container port mapping:

```text
localhost:2345
```

Debugging notes:

| Item | Details |
| --- | --- |
| Source root | `backend/` mounted to `/app` |
| Build output | `backend/tmp/` inside the mounted source tree |
| Debug port | Host `2345` mapped to container `2345` |
| Rebuild trigger | Go, template, and HTML files configured in `.air.toml` |
| Build log | `backend/build-errors.log` when Air build errors occur |

If debugging does not attach, verify the backend logs and confirm that Air started the Delve command from `.air.toml`.

## 10. Development Data And Volumes

Compose defines persistent named volumes:

| Volume | Used by | Purpose |
| --- | --- | --- |
| `postgres_data` | `postgres` | Local database files |
| `redis_data` | `redis` | Redis persistence data |
| `mailhog_data` | `mailhog` | Captured email storage |

Stop containers while keeping data:

```bash
docker compose -f docker-compose.dev.yml down
```

Remove all development data:

```bash
docker compose -f docker-compose.dev.yml down -v
```

Only remove volumes when a local reset is intended.

## 11. Development Widget Behavior

In development mode, the chat widget is served by the `chat-bubble` Vite server:

```text
http://localhost:3000
```

The widget auto-initializes in development from `chat-bubble/app/sdk.tsx`.

### Test Any Inbox In Chat-Bubble Dev Mode

The development widget does not currently let you choose an inbox from the browser UI. It auto-starts with hard-coded config in:

```text
chat-bubble/app/sdk.tsx
```

To test the widget against any web chat inbox:

1. Start the development stack.
2. Seed demo data or create a web chat inbox from the admin frontend.
3. Copy the target inbox ID.
4. Open `chat-bubble/app/sdk.tsx`.
5. Replace the hard-coded `inboxId` in the `import.meta.env.DEV` block.
6. Make sure `baseUrl` points to the backend URL that the widget can reach from the browser.
7. Save the file and let the `chat-bubble` Vite container reload.
8. Open or refresh the widget dev page.

The development block looks like this:

```tsx
if (import.meta.env.DEV) {
  init({
    inboxId: "<target-web-chat-inbox-id>",
    position: "bottom-right",
    primaryColor: "#dc0462",
    zIndex: 9999,
    baseUrl: "<backend-url-reachable-from-browser>",
  });
}
```

Fields to change when testing a different inbox:

| Field | Required change | Notes |
| --- | --- | --- |
| `inboxId` | yes | Use the ID of the web chat inbox you want to test |
| `baseUrl` | often | Must match the backend URL reachable from the browser |
| `position` | optional | Use when checking widget placement |
| `primaryColor` | optional | Use when checking widget theme |
| `zIndex` | optional | Use when checking overlay behavior on a host page |

If the widget opens but cannot load inbox data or create conversations, check that the selected inbox exists, is a web chat inbox, and the hard-coded `baseUrl` matches the backend port being used by the current dev stack.

For a realistic end-to-end test:

1. Start the full development stack.
2. Seed demo data.
3. Open the admin frontend.
4. Create or inspect a web chat inbox.
5. Put that inbox ID into the `import.meta.env.DEV` block in `chat-bubble/app/sdk.tsx`.
6. Confirm REST and WebSocket calls reach the backend.

Important: production widget testing is different. Production serves the built SDK from:

```text
/sdk/sdk.iife.js
```

Development mode does not build or copy the SDK into `backend/public/sdk`.

## 12. Running Individual Services

You can start only the dependencies and one app service when debugging a narrower issue.

Backend with dependencies:

```bash
docker compose -f docker-compose.dev.yml up -d postgres redis mailhog backend
```

Frontend with backend and dependencies:

```bash
docker compose -f docker-compose.dev.yml up -d postgres redis mailhog backend frontend
```

Chat widget with backend and dependencies:

```bash
docker compose -f docker-compose.dev.yml up -d postgres redis mailhog backend chat-bubble
```

Run one-off commands in a service container:

```bash
docker compose -f docker-compose.dev.yml exec backend sh
docker compose -f docker-compose.dev.yml exec frontend sh
docker compose -f docker-compose.dev.yml exec chat-bubble sh
```

## 13. What The Development Dockerfiles Do

### Backend Dockerfile

`backend/docker/Dockerfile.dev` uses `golang:1.24-alpine`.

It installs:

| Dependency | Purpose |
| --- | --- |
| `gcc`, `g++`, `musl-dev`, `libc-dev`, `build-base` | Build support for Go packages that need C/C++ tooling |
| `git` | Go module and tooling support |
| `pkgconfig`, `make` | Build tooling support |
| `github.com/cosmtrek/air` | Go hot reload runner |

It copies `go.mod` and `go.sum`, downloads modules, copies the rest of the backend source, and starts Air.

### Frontend Dockerfile

`frontend/docker/Dockerfile.dev` uses `node:20-alpine`.

It copies `package*.json`, installs dependencies, copies source, and starts Vite with `--host` so the app is reachable from outside the container.

### Chat-Bubble Dockerfile

`chat-bubble/docker/Dockerfile.dev` also uses `node:20-alpine`.

It follows the same development pattern as the frontend Dockerfile and starts the widget Vite server with `--host`.

## 14. Database Initialization

The backend connects to PostgreSQL and runs GORM `AutoMigrate` during startup.

Seed data is optional and should be used only for local demos or disposable development environments:

```bash
docker compose -f docker-compose.dev.yml exec backend go run . seed run
```

Seeded demo credentials:

```text
admin@talkdeskly.com / password123
```

To clear seeded data while preserving schema:

```bash
docker compose -f docker-compose.dev.yml exec backend go run . seed clear --force
```

To reset the full local database volume:

```bash
docker compose -f docker-compose.dev.yml down -v
docker compose -f docker-compose.dev.yml up -d --build
```

## 15. Troubleshooting

### Backend Keeps Restarting

Check logs:

```bash
docker compose -f docker-compose.dev.yml logs --tail=100 backend
```

Common causes:

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Database connection failure | Postgres is not ready, DSN mismatch, or database volume has stale state | Check `postgres` logs, backend `DATABASE_URL`, and reset dev volumes if needed |
| Redis connection failure | Redis is not running or backend points to the wrong host | Check `redis` container status and backend `REDIS_URL` |
| SMTP connection refused | Backend cannot reach MailHog | Use the MailHog service name from inside Compose and check `mailhog` health |
| Air build error | Go code does not compile | Check `backend/build-errors.log` and backend logs |
| Debugger port unavailable | Host port is already used | Change the host side of the `2345:2345` mapping |

### Frontend Loads But API Calls Fail

Check browser devtools and compare the requested API URL with the backend port exposed by Compose.

The current source hard-codes development API and WebSocket URLs. If the browser requests a different port than Compose publishes, either update the source to use Vite environment variables or align the Compose port mapping.

Relevant files:

| File | Check |
| --- | --- |
| `frontend/src/lib/api/client.ts` | Admin frontend API base URL |
| `frontend/src/context/websocket-context.tsx` | Admin frontend WebSocket URL |
| `chat-bubble/app/lib/api/client.ts` | Widget API base URL |
| `chat-bubble/app/sdk.tsx` | Widget development auto-init base URL |

### Frontend Or Chat-Bubble Container Exits

Check logs:

```bash
docker compose -f docker-compose.dev.yml logs --tail=100 frontend
docker compose -f docker-compose.dev.yml logs --tail=100 chat-bubble
```

Common causes:

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Dependency missing | Image was built before package changes | Rebuild the affected service |
| Vite cannot bind | Port conflict or command override issue | Check host port mapping and Vite logs |
| TypeScript/runtime error | App source error | Fix source and let Vite reload |

### MailHog Is Empty

Check:

1. The backend flow actually sends an email.
2. The backend points to the MailHog service from inside Compose.
3. MailHog is healthy.
4. Backend logs do not show SMTP errors.

### Database Port Conflict

The Postgres container maps the container database port to a host port for local tools.

If that host port is already used, change the left side of the mapping:

```yaml
ports:
  - "5434:5432"
```

Then connect host tools to the new host port. Other Compose services should continue using the Postgres service name and internal port.

### Dev Data Looks Stale

Stop containers and remove development volumes:

```bash
docker compose -f docker-compose.dev.yml down -v
docker compose -f docker-compose.dev.yml up -d --build
```

This deletes local Postgres, Redis, and MailHog data.

## 16. Stop Development Stack

Stop containers while keeping volumes:

```bash
docker compose -f docker-compose.dev.yml down
```

Stop and remove volumes for a disposable local reset:

```bash
docker compose -f docker-compose.dev.yml down -v
```

Do not remove volumes unless a data reset is explicitly intended.
