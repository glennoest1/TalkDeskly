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
- [Communication Architecture At A Glance](#communication-architecture-at-a-glance)
- [Important Differences](#important-differences)
- [First-Time Docker Development](#first-time-docker-development)
- [First-Time Host-Run Development](#first-time-host-run-development)
- [Production-Mode Local Test](#production-mode-local-test)
- [Safety Notes](#safety-notes)

## Quick Choice

Use development mode when you want separate containers for backend, frontend, chat widget, Postgres, Redis, and MailHog:

```bash
docker compose -f docker-compose.dev.yml up -d --build
```

Development mode exposes the backend on both `http://localhost:8080` and `http://localhost:6721`. The backend container still listens on `8080`; `6721` is a host-port compatibility alias for the current frontend and chat widget development code.

Use production mode when you want one backend container serving the compiled admin frontend, widget SDK, REST API, and WebSocket routes:

```bash
docker compose -f docker-compose.prod.yml up -d --build
```

Use local mode when you want the backend, frontend, and chat widget as host processes - fastest reload and native IDE debugging - with only the infrastructure in Docker:

```bash
docker compose -f docker-compose.dev.yml up -d postgres redis mailhog
```

Then follow [Local deployment](local/local-deployment.md) to start the three host processes.

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
