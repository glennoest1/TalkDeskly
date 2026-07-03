#!/usr/bin/env bash
set -euo pipefail

SCRIPT_ENTRYPOINT="scripts/deploy-dev.sh"
DEFAULT_START_COMMAND="scripts/deploy-dev.sh"
SUPPORTED_SERVICES="chat-bubble, backend, frontend, postgres, redis, mailhog"

. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/deploy-common.sh"

parse_deploy_cli "$@"

seed_mode() {
  write_step "Seeding Docker development demo data"
  compose "talkdeskly-dev" "docker-compose.dev.yml" exec -T backend go run . seed run
}

start_mode() {
  write_step "Starting Docker development stack"
  compose "talkdeskly-dev" "docker-compose.dev.yml" up -d --build

  write_step "Waiting for development HTTP endpoints"
  wait_http "http://localhost:6721/health"
  wait_http "http://localhost:3001/"
  wait_http "http://localhost:3000/"
  wait_http "http://localhost:8025/"

  if should_seed 1; then
    seed_mode
  fi

  write_step "Development deployment ready"
  write_info "Admin frontend: http://localhost:3001"
  write_info "Chat widget:    http://localhost:3000"
  write_info "Backend:        http://localhost:6721"
  write_info "MailHog:        http://localhost:8025"
}

stop_mode() {
  write_step "Stopping Docker development stack"
  compose "talkdeskly-dev" "docker-compose.dev.yml" down
}

status_mode() {
  write_step "Docker development status"
  compose "talkdeskly-dev" "docker-compose.dev.yml" ps
  assert_compose_running "talkdeskly-dev" "docker-compose.dev.yml" "./scripts/deploy-dev.sh start"
  test_http "http://localhost:6721/health"
  test_http "http://localhost:3001/"
  test_http "http://localhost:3000/"
  test_http "http://localhost:8025/"
}

logs_mode() {
  write_step "Docker development logs"
  assert_compose_running "talkdeskly-dev" "docker-compose.dev.yml" "./scripts/deploy-dev.sh start"
  compose_logs "talkdeskly-dev" "docker-compose.dev.yml"
}

build_mode() {
  write_step "Building Docker development images"
  compose "talkdeskly-dev" "docker-compose.dev.yml" build
}

reset_mode() {
  case "$DEPLOY_SERVICE" in
    chat-bubble|backend|frontend|postgres|redis|mailhog)
      compose_reset_service "talkdeskly-dev" "docker-compose.dev.yml"
      ;;
    "")
      require_service
      ;;
    *)
      echo "Unsupported development service: $DEPLOY_SERVICE" >&2
      echo "Supported development services: chat-bubble, backend, frontend, postgres, redis, mailhog" >&2
      exit 2
      ;;
  esac
}

dispatch_action
