# TalkDeskly Deploy Scripts

This document explains the Bash-only deployment automation used by the root `Makefile`.

Use this document when you need to start, stop, restart, check status, inspect logs, seed demo data, build assets, or troubleshoot `local`, `dev`, and `prod` deployment modes.

## Recommended Entry Point

Run deployment through `make` from the repository root:

```bash
make local
make dev
make prod
```

The Makefile calls a Bash dispatcher:

```text
scripts/deploy-dispatcher.sh
```

The dispatcher validates `MODE`, `ACTION`, and Makefile options, then routes to the mode-specific Bash script.

## Requirements

| Tool | Needed for |
| --- | --- |
| Bash | Running `scripts/deploy-dispatcher.sh` through Makefile |
| GNU Make | Running the supported deployment commands |
| Docker + Docker Compose | `dev`, `prod`, and local dependency containers. The script supports both `docker compose` and `docker-compose`. |
| curl | HTTP readiness and status checks |
| Go | `local` mode backend process and local seed command |
| Node.js + npm | `local` mode frontend/widget processes and `prod` asset builds |

On Windows, run these commands from WSL, Git Bash, MSYS2, or another Bash-capable shell with Docker access. If Git Bash does not see `make`, install GNU Make or add an existing Make binary such as MSYS2's `/c/msys64/usr/bin` to `PATH`.

## Command Reference

| Command | Purpose |
| --- | --- |
| `make local` | Start host-run local mode. Dependencies run in Docker; backend, frontend, and chat widget run as host processes. |
| `make dev` | Build and start the full Docker development stack. |
| `make prod` | Build frontend/widget assets, copy them into `backend/public`, build the production image, and start production Compose. |
| `make local-status` | Show local process status and check local HTTP endpoints. |
| `make dev-status` | Show Docker development Compose status and check dev HTTP endpoints. |
| `make prod-status` | Validate root `.env`, show production Compose status, and check prod HTTP endpoints. |
| `make local-stop` | Stop local host processes tracked in `.deploy/local-pids.txt`. |
| `make dev-stop` | Stop the Docker development Compose project. |
| `make prod-stop` | Stop the production Compose project. |
| `make local-restart` | Stop and start local host-run mode. |
| `make dev-restart` | Stop and start Docker development mode. |
| `make prod-restart` | Stop and start production mode. |
| `make local-logs` | Print local host-process logs from `.deploy/logs`. |
| `make dev-logs` | Print Docker development logs. |
| `make prod-logs` | Validate root `.env`, then print production Compose logs. |
| `make local-seed` | Run `go run . seed run` from `backend/`. |
| `make dev-seed` | Run the seed command inside the Docker development backend container. |
| `make prod-seed` | Run `./talkdeskly seed run` inside the production backend container. Use only for production-mode testing unless intentional. |
| `make local-build` | Install frontend and chat-bubble npm dependencies. |
| `make dev-build` | Build Docker development images. |
| `make prod-build` | Build frontend/widget assets, copy them into `backend/public`, and build the production backend image. |

Generic form:

```bash
make deploy MODE=dev ACTION=status
make deploy MODE=local ACTION=logs FOLLOW=1 TAIL=200
make deploy MODE=prod ACTION=build
```

Supported modes: `local`, `dev`, `prod`.

Supported actions: `start`, `stop`, `restart`, `status`, `logs`, `seed`, `build`.

## Options

| Make variable | Applies to | Meaning |
| --- | --- | --- |
| `NO_SEED=1` | `local`, `dev`, generic `start/restart` | Skip automatic demo data seeding. |
| `SEED=1` | `prod`, generic `start/restart` | Force demo data seeding. Production mode does not seed by default. |
| `INSTALL_DEPS=1` | `local`, `prod`, `build` | Force `npm install` even when `node_modules` already exists. |
| `FOLLOW=1` | `logs` | Keep streaming logs instead of printing and exiting. |
| `TAIL=<n>` | `logs` | Number of log lines to print before exit/follow. Default is `100`. |

Examples:

```bash
make dev NO_SEED=1
make prod SEED=1
make local INSTALL_DEPS=1
make dev-logs FOLLOW=1 TAIL=200
```

## Script Layout

| File | Responsibility |
| --- | --- |
| `Makefile` | Primary command interface. Users should run deployment through `make`. |
| `scripts/deploy-dispatcher.sh` | Thin Bash dispatcher. Validates mode/action/options, exports options, and routes to the selected mode script. |
| `scripts/deploy-common.sh` | Shared helpers for command checks, Docker Compose, HTTP readiness/status checks, npm dependencies, seed decisions, and action dispatch. |
| `scripts/deploy-local.sh` | Local host-run mode: dependency containers, host processes, PID tracking, local logs, local seed/build/status. |
| `scripts/deploy-dev.sh` | Docker development mode: Compose build/up/down/status/logs and dev seed. |
| `scripts/deploy-prod.sh` | Production mode: `.env` validation, asset builds/copies, production Compose actions, prod seed/status/logs. |

Deploy automation is Bash-only.

## Call Flow

```text
make dev
  -> Makefile
     -> bash ./scripts/deploy-dispatcher.sh dev start
        -> scripts/deploy-dev.sh
           -> scripts/deploy-common.sh
           -> docker compose -p talkdeskly-dev -f docker-compose.dev.yml up -d --build
           -> HTTP readiness checks
           -> optional seed
```

```text
make local
  -> bash ./scripts/deploy-dispatcher.sh local start
     -> scripts/deploy-local.sh
        -> scripts/deploy-common.sh
        -> starts postgres/redis/mailhog containers
        -> starts backend/frontend/chat-bubble host processes
        -> writes .deploy/local-pids.txt and .deploy/logs/*
```

```text
make prod
  -> bash ./scripts/deploy-dispatcher.sh prod start
     -> scripts/deploy-prod.sh
        -> scripts/deploy-common.sh
        -> validates root .env variable names
        -> builds frontend and chat widget
        -> copies assets into backend/public
        -> starts docker-compose.prod.yml
```

## Mode Details

### Local Mode

`make local` does this:

1. Starts dependency containers from `docker-compose.dev.yml`: `postgres`, `redis`, and `mailhog`.
2. Ensures frontend and chat-bubble npm dependencies exist.
3. Stops previously tracked local host processes.
4. Starts host processes:
   - backend: `go run .` from `backend/`
   - frontend: `npm run dev -- --host 0.0.0.0` from `frontend/`
   - chat-bubble: `npm run dev -- --host 0.0.0.0 --port 3000` from `chat-bubble/`
5. Saves process state to `.deploy/local-pids.txt`.
6. Writes logs to `.deploy/logs`.
7. Waits for endpoints.
8. Seeds demo data by default unless `NO_SEED=1` is passed.

Local URLs:

| Service | URL |
| --- | --- |
| Admin frontend | `http://localhost:5173` |
| Chat widget | `http://localhost:3000` |
| Backend | `http://localhost:6721` |
| MailHog | `http://localhost:8025` |

### Development Mode

`make dev` does this:

1. Uses Docker Compose project name `talkdeskly-dev`.
2. Builds and starts `docker-compose.dev.yml`.
3. Waits for endpoints.
4. Seeds demo data by default unless `NO_SEED=1` is passed.

The script checks that `talkdeskly-dev` has running containers before trusting HTTP endpoint checks. This prevents a false pass when an older Compose project is holding the same ports.

Development URLs:

| Service | URL |
| --- | --- |
| Admin frontend | `http://localhost:3001` |
| Chat widget | `http://localhost:3000` |
| Backend browser-facing alias | `http://localhost:6721` |
| Backend direct port | `http://localhost:8080` |
| MailHog | `http://localhost:8025` |

### Production Mode

`make prod` does this:

1. Verifies repository-root `.env` exists and contains required variable names.
2. Builds the admin frontend from `frontend/`.
3. Copies `frontend/dist/*` to `backend/public/app`.
4. Builds the chat widget SDK from `chat-bubble/`.
5. Copies `chat-bubble/dist/*` to `backend/public/sdk`.
6. Uses Docker Compose project name `talkdeskly-prod`.
7. Builds and starts `docker-compose.prod.yml`.
8. Waits for production endpoints.
9. Seeds only when `SEED=1` is passed.

Required root `.env` variable names:

| Variable | Purpose |
| --- | --- |
| `POSTGRES_PASSWORD` | Password for the Compose-managed PostgreSQL instance. |
| `JWT_SECRET` | Token signing secret. |
| `BASE_URL` | Public backend origin used by frontend and widget. |
| `EMAIL_HOST` | SMTP host reachable from the backend container. |
| `EMAIL_PORT` | SMTP port reachable from the backend container. |
| `EMAIL_FROM` | Sender email address. |

Do not commit `.env`. Keep real values local or in a secret manager.

## E2E Checks

After changing deploy scripts, run:

```bash
bash -n scripts/deploy-dispatcher.sh
bash -n scripts/deploy-common.sh
bash -n scripts/deploy-local.sh
bash -n scripts/deploy-dev.sh
bash -n scripts/deploy-prod.sh
make help
make -n dev NO_SEED=1
make local-status
make local-logs TAIL=5
make dev-status
make dev-logs TAIL=5
make prod-status
```

Expected notes:

| Check | Expected result |
| --- | --- |
| `make -n dev NO_SEED=1` | Prints `bash ./scripts/deploy-dispatcher.sh dev start -NoSeed -Tail 100`. |
| `make dev-status` | Lists running containers under project `talkdeskly-dev` before HTTP checks. |
| `make prod-status` without `.env` | Fails early with a clear `.env` message. |

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `make` is not recognized | GNU Make is not installed or not in `PATH`. | Install Make through MSYS2, WSL, Homebrew, or a Linux package manager. |
| `bash` is not recognized | Bash is not installed or the command is not in `PATH`. | Use WSL, Git Bash, MSYS2, or install Bash for your platform. |
| Git Bash says `make: command not found` | Git Bash does not ship with GNU Make in its default PATH. | Install GNU Make or add MSYS2 Make to PATH, for example `export PATH=/c/msys64/usr/bin:$PATH`. |
| `Missing required command: docker` | Docker CLI is not installed or not visible from the shell running Make. | Install Docker Desktop/Engine with Compose support and rerun from a shell with Docker access. |
| Docker commands fail with permission errors | Docker Desktop is not running or the shell cannot access the Docker engine. | Start Docker Desktop and rerun from a shell with Docker access. |
| `prod` fails before Compose starts | Root `.env` is missing required variable names. | Create `.env` following `docs/prod/production-deployment.md`. |
| Local status shows no process state | Local mode was not started by the script, or `.deploy/local-pids.txt` was removed. | Run `make local`. |
| Local frontend unavailable but backend/widget respond | Frontend host process is not running or port `5173` is occupied. | Check `.deploy/logs/frontend.err.log` and free the port. |
| `make dev-status` says no running containers were found but endpoints respond | An older stack may be running under the default Compose project name and holding the same host ports. | Stop the old stack manually, then run `make dev`. |
| `make dev` fails with `port is already allocated` | Another process or Compose project is already publishing one of the development ports. | Stop the process or old Compose project that owns the port, then rerun `make dev`. |
