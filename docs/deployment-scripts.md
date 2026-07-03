# TalkDeskly Deploy Scripts

This document explains how to run TalkDeskly deployment commands and how the deploy scripts are organized internally.

Use this document when you need to:

- start, stop, restart, check, seed, build, or inspect logs for `local`, `dev`, or `prod`
- understand which script owns each deployment mode
- troubleshoot Make, Docker Compose, `.env`, or local process issues

## Recommended Entry Point

Use `make` from the repository root. Deployment is intentionally exposed through Makefile targets only.

```bash
make local
make dev
make prod
```

The Makefile calls this internal dispatcher:

```text
scripts/deploy-dispatcher.ps1
```

The dispatcher routes to the internal mode-specific script:

```text
local -> scripts/deploy-local.ps1
dev   -> scripts/deploy-dev.ps1
prod  -> scripts/deploy-prod.ps1
```

## Command Reference

### Start

| Command | Purpose |
| --- | --- |
| `make local` | Start local host-run mode. Dependencies run in Docker; backend, frontend, and chat widget run as host processes. |
| `make dev` | Build and start the full Docker development stack. |
| `make prod` | Build frontend/widget assets, copy them into `backend/public`, build the production image, and start production Compose. |

### Status

| Command | Purpose |
| --- | --- |
| `make local-status` | Show local process status and check local HTTP endpoints. |
| `make dev-status` | Show Docker development Compose status and check dev HTTP endpoints. |
| `make prod-status` | Validate root `.env`, show production Compose status, and check prod HTTP endpoints. |

### Stop

| Command | Purpose |
| --- | --- |
| `make local-stop` | Stop local host processes tracked in `.deploy/local-pids.json`. Dependency containers are left running. |
| `make dev-stop` | Stop the Docker development Compose project. |
| `make prod-stop` | Stop the production Compose project. |

### Restart

| Command | Purpose |
| --- | --- |
| `make local-restart` | Stop and start local host-run mode. |
| `make dev-restart` | Stop and start Docker development mode. |
| `make prod-restart` | Stop and start production mode. |

### Logs

| Command | Purpose |
| --- | --- |
| `make local-logs` | Print local host-process logs from `.deploy/logs`. |
| `make dev-logs` | Print Docker development logs. |
| `make prod-logs` | Validate root `.env`, then print production Compose logs. |

Follow logs:

```bash
make dev-logs FOLLOW=1
make local-logs FOLLOW=1 TAIL=200
```

### Seed

| Command | Purpose |
| --- | --- |
| `make local-seed` | Run `go run . seed run` from `backend/`. |
| `make dev-seed` | Run the seed command inside the Docker development backend container. |
| `make prod-seed` | Run `./talkdeskly seed run` inside the production backend container. Use only for production-mode testing unless you intentionally want demo data. |

### Build

| Command | Purpose |
| --- | --- |
| `make local-build` | Install frontend and chat-bubble npm dependencies. |
| `make dev-build` | Build Docker development images. |
| `make prod-build` | Build frontend/widget assets, copy them into `backend/public`, and build the production backend image. |

### Generic Form

Use the generic form when scripting:

```bash
make deploy MODE=dev ACTION=status
make deploy MODE=local ACTION=logs FOLLOW=1 TAIL=200
make deploy MODE=prod ACTION=build
```

Supported modes:

| Mode | Meaning |
| --- | --- |
| `local` | Host-run development mode. |
| `dev` | Full Docker development mode. |
| `prod` | Production-style Docker Compose mode. |

Supported actions:

| Action | Meaning |
| --- | --- |
| `start` | Start the selected mode. |
| `stop` | Stop the selected mode. |
| `restart` | Stop, then start the selected mode. |
| `status` | Print runtime status and endpoint checks. |
| `logs` | Print logs. Use `FOLLOW=1` to follow. |
| `seed` | Seed demo data. |
| `build` | Run the build/preparation step for the selected mode. |

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
| `scripts/deploy-dispatcher.ps1` | Internal dispatcher used by `Makefile`; validates `MODE`/`ACTION` and calls the matching mode script. |
| `scripts/deploy-local.ps1` | Internal orchestration for local host-run deployment. |
| `scripts/deploy-dev.ps1` | Internal orchestration for Docker development deployment. |
| `scripts/deploy-prod.ps1` | Internal orchestration for production deployment. |
| `scripts/deploy-common.ps1` | Internal module loader and common path setup. |

Shared modules:

| Module | Responsibility |
| --- | --- |
| `scripts/modules/deploy-core.ps1` | Output helpers, checked command execution, seed decision logic, action dispatch. |
| `scripts/modules/deploy-http.ps1` | HTTP wait and status checks. |
| `scripts/modules/deploy-node.ps1` | npm command detection and dependency installation. |
| `scripts/modules/deploy-compose.ps1` | Docker Compose wrapper helpers for project-scoped commands and logs. |
| `scripts/modules/deploy-local-process.ps1` | Local host-process PID tracking, stopping, status, and logs. |
| `scripts/modules/deploy-prod-assets.ps1` | Production `.env` validation, frontend/widget builds, safe copy into `backend/public`. |

## Call Flow

Normal Makefile flow:

```text
make dev
  -> Makefile
     -> scripts/deploy-dispatcher.ps1 dev start
        -> scripts/deploy-dev.ps1 start
           -> scripts/deploy-common.ps1
              -> scripts/modules/*.ps1
```

Local example:

```text
make local
  -> scripts/deploy-dispatcher.ps1 local start
     -> scripts/deploy-local.ps1
        -> starts postgres/redis/mailhog containers
        -> starts backend/frontend/chat-bubble host processes
        -> writes .deploy/local-pids.json and .deploy/logs/*
```

Production example:

```text
make prod
  -> scripts/deploy-dispatcher.ps1 prod start
     -> scripts/deploy-prod.ps1
        -> validates .env
        -> builds frontend and chat widget
        -> copies assets into backend/public
        -> starts docker-compose.prod.yml
```

## Mode Details

### Local Mode

Local mode is for fastest development feedback on the host machine.

`make local` does this:

1. Starts dependency containers from `docker-compose.dev.yml`:
   - `postgres`
   - `redis`
   - `mailhog`
2. Ensures frontend and chat-bubble npm dependencies exist.
3. Stops previously tracked local host processes.
4. Starts host processes:
   - backend: `go run .` from `backend/`
   - frontend: `npm run dev -- --host 0.0.0.0` from `frontend/`
   - chat-bubble: `npm run dev -- --host 0.0.0.0 --port 3000` from `chat-bubble/`
5. Saves process state to `.deploy/local-pids.json`.
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

Local state files:

| Path | Purpose |
| --- | --- |
| `.deploy/local-pids.json` | PID tracking for host processes. |
| `.deploy/logs/backend.out.log` | Backend stdout. |
| `.deploy/logs/backend.err.log` | Backend stderr. |
| `.deploy/logs/frontend.out.log` | Frontend stdout. |
| `.deploy/logs/frontend.err.log` | Frontend stderr. |
| `.deploy/logs/chat-bubble.out.log` | Chat widget stdout. |
| `.deploy/logs/chat-bubble.err.log` | Chat widget stderr. |

### Development Mode

Development mode runs the full development stack in Docker.

`make dev` does this:

1. Uses Docker Compose project name `talkdeskly-dev`.
2. Builds and starts `docker-compose.dev.yml`.
3. Waits for endpoints.
4. Seeds demo data by default unless `NO_SEED=1` is passed.

Development URLs:

| Service | URL |
| --- | --- |
| Admin frontend | `http://localhost:3001` |
| Chat widget | `http://localhost:3000` |
| Backend browser-facing alias | `http://localhost:6721` |
| Backend direct port | `http://localhost:8080` |
| MailHog | `http://localhost:8025` |

The script uses Compose project name `talkdeskly-dev` so dev containers and volumes do not mix with local/prod script runs.

### Production Mode

Production mode builds a production-style backend image that serves the admin app, SDK, REST API, and WebSocket routes.

`make prod` does this:

1. Verifies repository-root `.env`.
2. Builds the admin frontend from `frontend/`.
3. Copies `frontend/dist/*` to `backend/public/app`.
4. Builds the chat widget SDK from `chat-bubble/`.
5. Copies `chat-bubble/dist/*` to `backend/public/sdk`.
6. Uses Docker Compose project name `talkdeskly-prod`.
7. Builds and starts `docker-compose.prod.yml`.
8. Waits for production endpoints.
9. Seeds only when `SEED=1` is passed.

Production URLs for local production-mode testing:

| Service | URL |
| --- | --- |
| Backend/admin | `http://localhost:8080` |
| SDK asset | `http://localhost:8080/sdk/sdk.iife.js` |

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

After changing deploy scripts, run these checks.

Parse all PowerShell scripts:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$files = Get-ChildItem -Path scripts -Recurse -Filter *.ps1 | Select-Object -ExpandProperty FullName; foreach ($file in $files) { $errors = $null; $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Raw $file), [ref]$errors); if ($errors) { Write-Output \"$file parse errors\"; $errors; exit 1 } }; Write-Output 'All deploy scripts parse'"
```

Run non-destructive local checks:

```bash
make local-status
make local-logs TAIL=5
```

Run non-destructive Docker development checks:

```bash
make dev-status
make dev-logs TAIL=5
```

Expected result: the Compose status must list running containers under project `talkdeskly-dev` before HTTP endpoint checks are trusted. If the HTTP ports respond but `talkdeskly-dev` has no running containers, the script fails because an older Compose project may be holding the same ports.

Production status requires root `.env`:

```bash
make prod-status
```

Expected result without `.env`: the script fails early with a clear `.env` message.

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `make` is not recognized | GNU Make is not installed or not in `PATH`. | Install Make through MSYS2, Chocolatey, Scoop, WSL, or another build-tool package. |
| PowerShell execution policy blocks a script | The Makefile cannot invoke the internal dispatcher with the expected execution policy. | Run through Make from the repository root and use the included Makefile target definitions. |
| Docker commands fail with permission errors | Docker Desktop is not running or the shell cannot access the Docker engine. | Start Docker Desktop and rerun from a shell with Docker access. |
| `prod` fails before Compose starts | Root `.env` is missing required variable names. | Create `.env` following `docs/prod/production-deployment.md`. |
| Local status shows no process state | Local mode was not started by the script, or `.deploy/local-pids.json` was removed. | Run `make local`. |
| Local frontend unavailable but backend/widget respond | Frontend host process is not running or port `5173` is occupied. | Check `.deploy/logs/frontend.err.log` and free the port. |
| `make dev-status` says no running containers were found but endpoints respond | An older stack may be running under the default Compose project name and holding the same host ports. | Stop the old stack manually, then run `make dev`. |
| `make dev` fails with `port is already allocated` | Another process or Compose project is already publishing one of the development ports. | Stop the process or old Compose project that owns the port, then rerun `make dev`. |
