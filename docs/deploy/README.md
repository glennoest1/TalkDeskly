# TalkDeskly Docker Compose Deployment

This folder contains Docker Compose deployment guides for TalkDeskly.

Start here when you need to run the project with Docker Compose.

| Guide | Use when | Main compose file |
| --- | --- | --- |
| [Development deployment](dev/development-deployment.md) | Local development, hot reload, debugging, MailHog email testing, and widget testing against local inboxes | `docker-compose.dev.yml` |
| [Production deployment](prod/production-deployment.md) | Local production-mode testing or preparing a production-style backend image that serves built frontend and SDK assets | `docker-compose.prod.yml` |

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

## Important Differences

| Area | Development | Production |
| --- | --- | --- |
| Backend | Go source mounted into container and run with Air | Compiled Go binary in final image |
| Admin frontend | Vite dev server on its own container | Static files copied into backend image |
| Chat widget | Vite dev server on its own container | Built SDK copied into backend image |
| Backend host ports | `8080` plus `6721` compatibility alias | `8080` |
| Email testing | MailHog service included | External SMTP configuration |
| Runtime variables | Mostly in `docker-compose.dev.yml` | Shell or root `.env` values consumed by Compose |
| Data reset | Safe for disposable local volumes | Do not remove real production volumes without backup |

## First-Time Local Development

1. Read [Development deployment](dev/development-deployment.md).
2. Start the dev stack.
3. Seed demo data.
4. Log in through the admin frontend.
5. For chat widget testing, update the hard-coded development `inboxId` in `chat-bubble/app/sdk.tsx` as described in the development guide. Keep the widget `baseUrl` as an HTTP origin such as `http://localhost:6721`; the widget code derives both REST and WebSocket URLs from that origin.

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
