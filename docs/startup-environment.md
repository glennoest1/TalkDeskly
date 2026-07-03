# Startup Environment Variables

This document organizes the environment variables required to start TalkDeskly in `local`, `dev`, and `prod` modes.

## Files

| File | Purpose | Loaded automatically |
| --- | --- | --- |
| `backend/.env` | Host-run local backend config. | Yes, by backend `godotenv.Load()` when backend runs on the host. |
| `env/local.env.example` | Template for recreating `backend/.env`. | No. Copy to `backend/.env` if needed. |
| `docker-compose.dev.yml` | Docker development startup config. | Yes, by Docker Compose. |
| `env/dev.compose.env.example` | Human-readable reference for the inline dev Compose env. | No. It mirrors the values in `docker-compose.dev.yml`. |
| `.env` | Production-mode Compose variables. | Yes, by Docker Compose when running `docker-compose.prod.yml`. |
| `env/prod.env.example` | Template for root `.env`. | No. Copy to `.env` and replace placeholders. |

Do not commit root `.env`. It is ignored by git.

## Local Mode

Local mode command:

```bash
./scripts/deploy-local.sh start
```

Local mode starts Postgres, Redis, and MailHog in Docker, then runs the backend, frontend, and chat widget as host processes.

Backend startup variables come from `backend/.env`:

| Variable | Required | Example | Purpose |
| --- | --- | --- | --- |
| `DATABASE_URL` | yes | `postgres://postgres:postgres@localhost:5433/talkdeskly` | Host backend connects to Postgres published from Docker. |
| `JWT_SECRET` | yes | `secret` | Local token signing secret. |
| `PORT` | yes | `6721` | Backend host listen port. |
| `BASE_URL` | recommended | `http://localhost:6721` | Backend origin used in generated links and widget setup. |
| `FRONTEND_URL` | optional | `http://localhost:5173` | Admin frontend origin. |
| `ENVIRONMENT` | optional | `development` | Backend runtime environment. |
| `LOG_LEVEL` | optional | `info` | Backend log level. |
| `REDIS_URL` | yes | `localhost:6379` | Host backend connects to Redis published from Docker. |
| `EMAIL_PROVIDER` | recommended | `smtp` | Email provider implementation. |
| `EMAIL_HOST` | yes | `localhost` | Host backend connects to MailHog published from Docker. |
| `EMAIL_PORT` | yes | `1025` | MailHog SMTP port. |
| `EMAIL_USERNAME` | optional | empty | SMTP username if needed. |
| `EMAIL_PASSWORD` | optional | empty | SMTP password if needed. |
| `EMAIL_FROM` | recommended | `noreply@talkdeskly.com` | Sender address. |
| `DEFAULT_LANGUAGE` | optional | `en` | Default i18n language. |
| `SUPPORTED_LANGUAGES` | optional | `en` | Comma-separated supported languages. |
| `APPLICATION_NAME` | optional | `TalkDeskly` | Application display name. |
| `ENABLE_REGISTRATION` | optional | `false` | Registration feature flag. |

To recreate local env:

```bash
cp env/local.env.example backend/.env
```

## Docker Development Mode

Development mode command:

```bash
./scripts/deploy-dev.sh start --no-seed
```

Development mode does not require root `.env`. `docker-compose.dev.yml` sets startup values inline.

Backend container variables:

| Variable | Value | Purpose |
| --- | --- | --- |
| `GO_ENV` | `development` | Convention marker for container runtime. Current backend config reads `ENVIRONMENT`, so this is not the app environment field. |
| `DATABASE_URL` | `postgres://postgres:postgres@postgres:5432/talkdeskly` | Backend-to-Postgres connection inside Compose network. |
| `PORT` | `8080` | Backend listen port inside container. |
| `JWT_SECRET` | `secret` | Disposable dev token signing secret. |
| `BASE_URL` | `http://localhost:8080` | Backend base URL for generated links. |
| `REDIS_URL` | `redis:6379` | Backend-to-Redis connection inside Compose network. |
| `EMAIL_HOST` | `mailhog` | Backend-to-MailHog connection inside Compose network. |
| `EMAIL_PORT` | `1025` | MailHog SMTP port. |
| `EMAIL_USERNAME` | empty | SMTP username. |
| `EMAIL_PASSWORD` | empty | SMTP password. |
| `EMAIL_FROM` | `noreply@talkdeskly.com` | Sender address. |

Frontend/widget container variables:

| Service | Variable | Value | Purpose |
| --- | --- | --- | --- |
| `frontend` | `NODE_ENV` | `development` | Frontend dev runtime. |
| `chat-bubble` | `NODE_ENV` | `development` | Widget dev runtime. |
| `chat-bubble` | `VITE_API_URL` | `http://localhost:8080/api` | Intended browser API URL for widget dev. |
| `chat-bubble` | `VITE_WS_URL` | `ws://localhost:8080/ws` | Intended browser WebSocket URL for widget dev. |

Data service variables:

| Service | Variable | Value |
| --- | --- | --- |
| `postgres` | `POSTGRES_USER` | `postgres` |
| `postgres` | `POSTGRES_PASSWORD` | `postgres` |
| `postgres` | `POSTGRES_DB` | `talkdeskly` |
| `mailhog` | `MH_STORAGE` | `maildir` |
| `mailhog` | `MH_MAILDIR_PATH` | `/tmp` |

`env/dev.compose.env.example` is only a reference copy so DevOps can review startup values in one place.

## Production Mode

Production mode command:

```bash
cp env/prod.env.example .env
# edit .env first
./scripts/deploy-prod.sh start
```

Production mode requires root `.env` because `docker-compose.prod.yml` interpolates these variables.

| Variable | Required | Secret | Purpose |
| --- | --- | --- | --- |
| `POSTGRES_PASSWORD` | yes | yes | Password for Compose-managed PostgreSQL. |
| `JWT_SECRET` | yes | yes | Token signing secret. |
| `BASE_URL` | yes | no | Public backend origin used by the admin app, widget SDK, REST, and WebSocket routes. |
| `EMAIL_HOST` | yes | no | SMTP host reachable from the backend container. |
| `EMAIL_PORT` | yes | no | SMTP port. |
| `EMAIL_USERNAME` | provider-dependent | yes | SMTP username. Leave empty if provider does not require auth. |
| `EMAIL_PASSWORD` | provider-dependent | yes | SMTP password. Leave empty if provider does not require auth. |
| `EMAIL_FROM` | yes | no | Sender email address. |

Production-mode local E2E with MailHog can use:

```env
POSTGRES_PASSWORD=talkdeskly_e2e_password
JWT_SECRET=talkdeskly_e2e_jwt_secret_at_least_32_chars
BASE_URL=http://localhost:8080
EMAIL_HOST=host.docker.internal
EMAIL_PORT=1025
EMAIL_USERNAME=
EMAIL_PASSWORD=
EMAIL_FROM=noreply@example.local
```

Do not use those E2E values for real production.

## Startup Checks

Use these commands before starting a mode:

```bash
./scripts/deploy-local.sh --help
./scripts/deploy-dev.sh --help
./scripts/deploy-prod.sh --help
```

For production, the deploy script fails early if root `.env` is missing any required variable name:

```bash
./scripts/deploy-prod.sh status
```
