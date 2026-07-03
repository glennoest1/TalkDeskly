# TalkDeskly Deploy Scripts

TalkDeskly deployment automation is Bash-only and direct-script only. There is no Makefile entrypoint.

DevOps should run one of these three mode scripts from the repository root:

```bash
./scripts/deploy-local.sh [action] [options]
./scripts/deploy-dev.sh [action] [options]
./scripts/deploy-prod.sh [action] [options]
```

`bash scripts/deploy-*.sh ...` also works when executable bits are not preserved by the checkout.

## Requirements

| Tool | Needed for |
| --- | --- |
| Bash | Running the deploy scripts. |
| Docker + Docker Compose | `dev`, `prod`, and local dependency containers. Scripts support both `docker compose` and `docker-compose`. |
| curl | HTTP readiness and status checks. |
| Go | `local` backend process and local seed command. |
| Node.js + npm | `local` frontend/widget processes and `prod` asset builds. |

On Windows, run from Git Bash, WSL, MSYS2, or another Bash-capable shell with Docker access.

Before first startup, review [Startup Environment Variables](startup-environment.md). It lists the required env source for each mode and points to the example files in `env/`.

## Actions

| Action | Purpose |
| --- | --- |
| `start` | Start the selected deployment mode. Default when action is omitted. |
| `stop` | Stop the selected deployment mode. |
| `restart` | Stop, then start. |
| `status` | Show runtime status and probe HTTP endpoints. |
| `logs` | Show logs. |
| `seed` | Seed demo data. |
| `build` | Build dependencies, assets, or Docker images for the mode. |
| `reset` | Reset one service. Requires `--service <name>`. |

## Options

| Option | Meaning |
| --- | --- |
| `--seed`, `-s` | Force demo data seeding when `start` or `restart` runs. |
| `--no-seed` | Skip automatic demo data seeding. |
| `--install-deps` | Force `npm install` where the mode uses npm packages. |
| `--follow`, `-f` | Follow logs. |
| `--tail <n>` | Number of log lines to print. Default is `100`. |
| `--service <name>` | Service name for `reset`. |
| `--help`, `-h` | Show script help. |

## Local Script

Local mode runs Postgres, Redis, and MailHog in Docker. Backend, admin frontend, and chat widget run as host processes.

```bash
./scripts/deploy-local.sh start --install-deps --no-seed
./scripts/deploy-local.sh status
./scripts/deploy-local.sh logs --tail 100
./scripts/deploy-local.sh reset --service frontend
./scripts/deploy-local.sh stop
```

Reset services:

```text
backend, frontend, chat-bubble, postgres, redis, mailhog
```

Local URLs:

| Service | URL |
| --- | --- |
| Admin frontend | `http://localhost:5173` |
| Chat widget | `http://localhost:3000` |
| Backend | `http://localhost:6721` |
| MailHog | `http://localhost:8025` |

Local process state is stored in `.deploy/local-pids.txt`. Local process logs are stored in `.deploy/logs/`.

## Development Script

Development mode runs the full Docker development stack from `docker-compose.dev.yml`.

```bash
./scripts/deploy-dev.sh start --no-seed
./scripts/deploy-dev.sh status
./scripts/deploy-dev.sh logs --tail 100
./scripts/deploy-dev.sh logs --follow --tail 200
./scripts/deploy-dev.sh reset --service backend
./scripts/deploy-dev.sh stop
```

Reset services:

```text
chat-bubble, backend, frontend, postgres, redis, mailhog
```

Development URLs:

| Service | URL |
| --- | --- |
| Admin frontend | `http://localhost:3001` |
| Chat widget | `http://localhost:3000` |
| Backend browser-facing alias | `http://localhost:6721` |
| Backend direct port | `http://localhost:8080` |
| MailHog | `http://localhost:8025` |

The Compose project name is `talkdeskly-dev`.

## Production Script

Production mode builds frontend and widget assets, copies them into `backend/public`, builds the production backend image, and starts `docker-compose.prod.yml`.

```bash
./scripts/deploy-prod.sh build --install-deps
./scripts/deploy-prod.sh start
./scripts/deploy-prod.sh status
./scripts/deploy-prod.sh logs --tail 200
./scripts/deploy-prod.sh reset --service backend
./scripts/deploy-prod.sh stop
```

Reset services:

```text
backend, postgres, redis
```

Production requires a repository-root `.env` with these variable names:

| Variable | Purpose |
| --- | --- |
| `POSTGRES_PASSWORD` | Password for the Compose-managed PostgreSQL instance. |
| `JWT_SECRET` | Token signing secret. |
| `BASE_URL` | Public backend origin used by frontend and widget. |
| `EMAIL_HOST` | SMTP host reachable from the backend container. |
| `EMAIL_PORT` | SMTP port reachable from the backend container. |
| `EMAIL_FROM` | Sender email address. |

The Compose project name is `talkdeskly-prod`.

Create production env from the template:

```bash
cp env/prod.env.example .env
# edit .env before starting
```

## Script Layout

| File | Responsibility |
| --- | --- |
| `scripts/deploy-common.sh` | Shared CLI parsing, command checks, Compose helpers, HTTP checks, npm dependency checks, seed decisions, and action dispatch. |
| `scripts/deploy-local.sh` | Standalone local host-run deployment CLI. |
| `scripts/deploy-dev.sh` | Standalone Docker development deployment CLI. |
| `scripts/deploy-prod.sh` | Standalone production-style deployment CLI. |

## Verification

After changing deploy scripts, run from Git Bash:

```bash
for f in scripts/deploy-common.sh scripts/deploy-local.sh scripts/deploy-dev.sh scripts/deploy-prod.sh; do bash -n "$f"; done

./scripts/deploy-local.sh --help
./scripts/deploy-dev.sh --help
./scripts/deploy-prod.sh --help

./scripts/deploy-dev.sh start --no-seed
./scripts/deploy-dev.sh status
./scripts/deploy-dev.sh logs --tail 40
./scripts/deploy-dev.sh reset --service backend
./scripts/deploy-dev.sh stop
```

Production E2E also needs a valid root `.env`. Local E2E needs Go and Node.js visible from the same Git Bash session.

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `bash` is not recognized | Bash is not installed or not in `PATH`. | Use Git Bash, WSL, MSYS2, or install Bash. |
| `Permission denied` when running `./scripts/deploy-dev.sh` | Executable bit was not preserved. | Run `chmod +x scripts/deploy-*.sh`, or call with `bash scripts/deploy-dev.sh`. |
| `Missing required command: docker` | Docker CLI is not installed or not visible from the shell. | Install/start Docker Desktop or Docker Engine and rerun from a shell with Docker access. |
| Docker permission errors | Docker Desktop is not running or the shell cannot access the engine. | Start Docker Desktop and rerun from Git Bash/WSL with Docker access. |
| `prod` fails before Compose starts | Root `.env` is missing required variable names. | Create `.env` following `docs/prod/production-deployment.md`. |
| Local status shows no process state | Local mode was not started by the script, or `.deploy/local-pids.txt` was removed. | Run `./scripts/deploy-local.sh start`. |
| Local frontend unavailable but backend/widget respond | Frontend host process is not running or port `5173` is occupied. | Check `.deploy/logs/frontend.err.log` and free the port. |
| Dev status says no running containers but endpoints respond | Another Compose project may be holding the same host ports. | Stop the old stack, then run `./scripts/deploy-dev.sh start`. |
