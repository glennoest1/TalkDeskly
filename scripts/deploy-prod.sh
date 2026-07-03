#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ENTRYPOINT="scripts/deploy-prod.sh"
DEFAULT_START_COMMAND="scripts/deploy-prod.sh"
SUPPORTED_SERVICES="backend, postgres, redis"
PROD_REQUIRED_ENV="POSTGRES_PASSWORD JWT_SECRET BASE_URL EMAIL_HOST EMAIL_PORT EMAIL_FROM"
PROD_OPTIONAL_ENV="EMAIL_USERNAME EMAIL_PASSWORD"

. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/deploy-common.sh"

parse_deploy_cli "$@"

assert_prod_env() {
  local env_file="$REPO_ROOT/.env"
  if [ ! -f "$env_file" ]; then
    echo "Production mode requires .env at the repository root. See docs/prod/production-deployment.md Step 0." >&2
    exit 1
  fi
  for name in $PROD_REQUIRED_ENV; do
    if ! grep -Eq "^${name}[[:space:]]*=" "$env_file"; then
      echo "Missing required production variable in .env: $name" >&2
      exit 1
    fi
  done
  for name in $PROD_OPTIONAL_ENV; do
    if ! grep -Eq "^${name}[[:space:]]*=" "$env_file"; then
      echo "Missing optional production variable in .env: $name" >&2
      echo "Set it to an empty value if your SMTP provider does not require it." >&2
      exit 1
    fi
  done
}

clear_directory_contents() {
  local target="$1"
  mkdir -p "$target"
  local repo_real
  local target_real
  repo_real=$(CDPATH= cd -- "$REPO_ROOT" && pwd -P)
  target_real=$(CDPATH= cd -- "$target" && pwd -P)
  case "$target_real" in
    "$repo_real"/*) ;;
    *)
      echo "Refusing to clear path outside repository: $target_real" >&2
      exit 1
      ;;
  esac
  find "$target_real" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
}

copy_directory_contents() {
  local src="$1"
  local target="$2"
  if [ ! -d "$src" ]; then
    echo "Missing source directory: $src" >&2
    exit 1
  fi
  clear_directory_contents "$target"
  cp -R "$src"/. "$target"/
}

build_prod_assets() {
  write_step "Building admin frontend"
  ensure_npm_deps "$REPO_ROOT/frontend" "$INSTALL_DEPS"
  run_in "$REPO_ROOT/frontend" npm run build
  copy_directory_contents "$REPO_ROOT/frontend/dist" "$REPO_ROOT/backend/public/app"

  write_step "Building chat widget SDK"
  ensure_npm_deps "$REPO_ROOT/chat-bubble" "$INSTALL_DEPS"
  run_in "$REPO_ROOT/chat-bubble" npm run build
  copy_directory_contents "$REPO_ROOT/chat-bubble/dist" "$REPO_ROOT/backend/public/sdk"
}

seed_mode() {
  write_step "Seeding production demo data"
  compose "talkdeskly-prod" "docker-compose.prod.yml" exec -T backend ./talkdeskly seed run
}

start_mode() {
  assert_prod_env
  build_prod_assets

  write_step "Starting production stack"
  compose "talkdeskly-prod" "docker-compose.prod.yml" up -d --build

  write_step "Waiting for production HTTP endpoint"
  wait_http "http://localhost:8080/health"
  wait_http "http://localhost:8080/"
  wait_http "http://localhost:8080/sdk/sdk.iife.js"

  if should_seed 0; then
    seed_mode
  fi

  write_step "Production deployment ready"
  write_info "Backend/admin: http://localhost:8080"
  write_info "SDK:           http://localhost:8080/sdk/sdk.iife.js"
}

stop_mode() {
  write_step "Stopping production stack"
  compose "talkdeskly-prod" "docker-compose.prod.yml" down
}

status_mode() {
  assert_prod_env
  write_step "Production status"
  compose "talkdeskly-prod" "docker-compose.prod.yml" ps
  assert_compose_running "talkdeskly-prod" "docker-compose.prod.yml" "./scripts/deploy-prod.sh start"
  test_http "http://localhost:8080/health"
  test_http "http://localhost:8080/"
  test_http "http://localhost:8080/sdk/sdk.iife.js"
}

logs_mode() {
  assert_prod_env
  write_step "Production logs"
  assert_compose_running "talkdeskly-prod" "docker-compose.prod.yml" "./scripts/deploy-prod.sh start"
  compose_logs "talkdeskly-prod" "docker-compose.prod.yml"
}

build_mode() {
  assert_prod_env
  build_prod_assets
  write_step "Building production Docker image"
  compose "talkdeskly-prod" "docker-compose.prod.yml" build backend
}

reset_mode() {
  assert_prod_env
  case "$DEPLOY_SERVICE" in
    backend|postgres|redis)
      if [ "$DEPLOY_SERVICE" = "backend" ]; then
        build_prod_assets
      fi
      compose_reset_service "talkdeskly-prod" "docker-compose.prod.yml"
      ;;
    "")
      require_service
      ;;
    *)
      echo "Unsupported production service: $DEPLOY_SERVICE" >&2
      echo "Supported production services: backend, postgres, redis" >&2
      exit 2
      ;;
  esac
}

dispatch_action
