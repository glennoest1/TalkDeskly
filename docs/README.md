# TalkDeskly Deployment Guides

This folder contains the deployment guides for TalkDeskly: Docker development, Docker production, and host-run local development.

Start here when you need to run the project.

| Guide | Use when | Main compose file |
| --- | --- | --- |
| [Development deployment](dev/development-deployment.md) | Local development fully in Docker: hot reload, debugging, MailHog email testing, and widget testing against local inboxes | `docker-compose.dev.yml` |
| [Production deployment](prod/production-deployment.md) | Local production-mode testing or preparing a production-style backend image that serves built frontend and SDK assets | `docker-compose.prod.yml` |
| [Local deployment](local/local-deployment.md) | Running backend, frontend, and chat widget directly on the host for the fastest feedback loop and native IDE debugging; only Postgres, Redis, and MailHog run in Docker | `docker-compose.dev.yml` (dependency services only) |

Each guide begins with an architecture diagram and a connection table showing exactly who talks to whom in that mode: [Development Architecture](dev/development-deployment.md#development-architecture), [Production Architecture](prod/production-deployment.md#production-architecture), [Local Architecture](local/local-deployment.md#local-architecture).

## Table Of Contents

- [Quick Choice](#quick-choice)
- [Deploy Scripts](#deploy-scripts)
- [Startup Environment](#startup-environment)
- [Communication Architecture At A Glance](#communication-architecture-at-a-glance)
- [Important Differences](#important-differences)
- [First-Time Docker Development](#first-time-docker-development)
- [First-Time Host-Run Development](#first-time-host-run-development)
- [Production-Mode Local Test](#production-mode-local-test)
- [Safety Notes](#safety-notes)

## Quick Choice

Use development mode when you want separate containers for backend, frontend, chat widget, Postgres, Redis, and MailHog:

```bash
./scripts/deploy-dev.sh start
```

Development mode exposes the backend on both `http://localhost:8080` and `http://localhost:6721`. The backend container still listens on `8080`; `6721` is a host-port compatibility alias for the current frontend and chat widget development code.

Use production mode when you want one backend container serving the compiled admin frontend, widget SDK, REST API, and WebSocket routes:

```bash
./scripts/deploy-prod.sh start
```

Use local mode when you want the backend, frontend, and chat widget as host processes - fastest reload and native IDE debugging - with only the infrastructure in Docker:

```bash
./scripts/deploy-local.sh start
```

Then open the URLs printed by the script.

## Deploy Scripts

Use the standalone Bash deploy scripts from the repository root:

```bash
./scripts/deploy-local.sh start
./scripts/deploy-dev.sh start
./scripts/deploy-prod.sh start
./scripts/deploy-local.sh status
./scripts/deploy-dev.sh stop
./scripts/deploy-prod.sh restart
./scripts/deploy-dev.sh reset --service backend
./scripts/deploy-dev.sh logs --tail 100
./scripts/deploy-local.sh seed
./scripts/deploy-prod.sh build
```

Script layout:

| File | Role |
| --- | --- |
| `scripts/deploy-common.sh` | Shared Bash helpers for command checks, Compose, HTTP, npm, seeding decisions, and action dispatch |
| `scripts/deploy-local.sh` | Local host-run deployment actions |
| `scripts/deploy-dev.sh` | Docker development deployment actions |
| `scripts/deploy-prod.sh` | Production-style deployment actions |

See [Deployment Scripts](deployment-scripts.md) for a full file-by-file explanation.

Examples:

| Command | What it does |
| --- | --- |
| `./scripts/deploy-local.sh start` | Starts Postgres, Redis, and MailHog in Docker, then starts backend, frontend, and chat widget as host processes |
| `./scripts/deploy-dev.sh start` | Builds and starts the full Docker development stack |
| `./scripts/deploy-prod.sh start` | Builds frontend and widget assets, copies them into `backend/public`, then builds and starts the production Compose stack |
| `./scripts/deploy-dev.sh stop` | Stops the Docker development stack |
| `./scripts/deploy-dev.sh reset --service backend` | Recreates one Docker development service without resetting named volumes |
| `./scripts/deploy-local.sh status` | Shows local process status and checks HTTP endpoints |
| `./scripts/deploy-dev.sh logs --tail 100` | Shows Docker development logs |
| `./scripts/deploy-local.sh seed` | Seeds local demo data |
| `./scripts/deploy-prod.sh build` | Builds production frontend/widget assets and Docker image |

Use script options for seed, dependency, log, and reset behavior:

```bash
./scripts/deploy-dev.sh start --no-seed
./scripts/deploy-prod.sh start --seed
./scripts/deploy-local.sh start --install-deps
./scripts/deploy-dev.sh restart
./scripts/deploy-dev.sh reset --service backend
./scripts/deploy-dev.sh logs --follow --tail 200
```

By default, `local` and `dev` seed demo data after startup. Use `NO_SEED=1` to skip it or `SEED=1` to seed production mode explicitly.

Production mode requires a repository-root `.env` before running the script. See [Production deployment](prod/production-deployment.md#step-0-verify-prerequisites-and-configure-variables).

The script uses separate Docker Compose project names per mode: `talkdeskly-local`, `talkdeskly-dev`, and `talkdeskly-prod`. This keeps containers and volumes from different modes from being mixed in `docker compose ps`.

## Startup Environment

Use [Startup Environment Variables](startup-environment.md) before first startup or when moving values between modes.

| Mode | Startup env source | Example file |
| --- | --- | --- |
| Local | `backend/.env` | `env/local.env.example` |
| Development | `docker-compose.dev.yml` inline env | `env/dev.compose.env.example` |
| Production | root `.env` | `env/prod.env.example` |

## Communication Architecture At A Glance

The three modes differ mainly by where JavaScript is served from and which address plane each caller uses.

| Mode | Browser loads UI from | Browser calls backend at | Backend reaches data services at | Widget `baseUrl` model |
| --- | --- | --- | --- | --- |
| Local host-run | Host Vite servers | `localhost:6721` | Published host ports for Postgres, Redis, and MailHog | HTTP origin for the host backend |
| Docker development | Vite containers published to host ports | `localhost:6721` compatibility alias, or `localhost:8080` for direct backend checks | Compose service names inside the Docker network | HTTP origin for the published backend alias |
| Production | Backend static file server | Public backend origin (`BASE_URL`) | Compose service names plus external SMTP host | Public backend origin that serves `/sdk`, `/api`, and `/ws` |

Common rule: frontend and widget containers do not make API calls by themselves. They serve JavaScript to the browser; the browser then calls the backend. Container service names such as `backend`, `postgres`, or `mailhog` only work from inside the Docker network, never from browser JavaScript.

## Important Differences

| Area | Local (host-run) | Development (Docker) | Production |
| --- | --- | --- | --- |
| Backend | `go run .` on host, listens on `6721` from `backend/.env` | Go source mounted into container and run with Air | Compiled Go binary in final image |
| Admin frontend | Vite on host, port `5173` | Vite dev server on its own container, host port `3001` | Static files copied into backend image |
| Chat widget | Vite on host, port `3000` | Vite dev server on its own container, host port `3000` | Built SDK copied into backend image |
| Backend host ports | `6721` | `8080` plus `6721` compatibility alias | `8080` |
| Email testing | MailHog container, backend connects via `localhost:1025` | MailHog service, backend connects via service name `mailhog` | External SMTP configuration |
| Runtime variables | `backend/.env` read by `godotenv` on startup | Mostly in `docker-compose.dev.yml` | Shell or root `.env` values consumed by Compose |
| Extra host tools | Go 1.24+, gcc, Node.js | Docker only | Node.js for asset builds |
| Data reset | Same dev volumes, safe to reset | Safe for disposable local volumes | Do not remove real production volumes without backup |

## First-Time Docker Development

1. Read [Development deployment](dev/development-deployment.md).
2. Start the dev stack.
3. Seed demo data.
4. Log in through the admin frontend.
5. For chat widget testing, update the hard-coded development `inboxId` in `chat-bubble/app/sdk.tsx` as described in the development guide. Keep the widget `baseUrl` as an HTTP origin such as `http://localhost:6721`; the widget code derives both REST and WebSocket URLs from that origin.

## First-Time Host-Run Development

1. Read [Local deployment](local/local-deployment.md).
2. Start only `postgres`, `redis`, and `mailhog` from `docker-compose.dev.yml`.
3. Start the backend with `go run .` from `backend/`; it listens on `6721` via `backend/.env`.
4. Start the admin frontend with `npm run dev` from `frontend/` (port `5173`).
5. Start the chat widget with `npm run dev -- --port 3000` from `chat-bubble/`.
6. Seed demo data with `go run . seed run` from `backend/`, then log in at `http://localhost:5173`.

## Production-Mode Local Test

1. Read [Production deployment](prod/production-deployment.md).
2. Build the admin frontend.
3. Copy frontend assets into `backend/public/app`.
4. Build the chat widget SDK.
5. Copy SDK assets into `backend/public/sdk`.
6. Build and start the production Compose stack.
7. Test `/health`, `/`, and `/sdk/sdk.iife.js`.

## Safety Notes

Do not commit real secrets or copied `.env` values into documentation, Compose files, or example snippets.

For production-mode testing, use placeholders in shared docs and keep real values in a local `.env` file or secret store.
