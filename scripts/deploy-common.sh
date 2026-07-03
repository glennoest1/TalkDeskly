#!/usr/bin/env bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
STATE_DIR="$REPO_ROOT/.deploy"
LOG_DIR="$STATE_DIR/logs"
PID_FILE="$STATE_DIR/local-pids.txt"

DEPLOY_ACTION="${DEPLOY_ACTION:-start}"
SEED_DEMO="${SEED_DEMO:-0}"
NO_SEED="${NO_SEED:-0}"
INSTALL_DEPS="${INSTALL_DEPS:-0}"
FOLLOW="${FOLLOW:-0}"
TAIL="${TAIL:-100}"
DEPLOY_SERVICE="${DEPLOY_SERVICE:-}"
SCRIPT_ENTRYPOINT="${SCRIPT_ENTRYPOINT:-deploy script}"
DEFAULT_START_COMMAND="${DEFAULT_START_COMMAND:-this script}"
SUPPORTED_SERVICES="${SUPPORTED_SERVICES:-}"
CLI_PARSED="${CLI_PARSED:-0}"

write_step() {
  printf '\n==> %s\n' "$1"
}

write_info() {
  printf '    %s\n' "$1"
}

print_common_usage() {
  cat <<EOF
Usage:
  $SCRIPT_ENTRYPOINT [action] [options]

Actions:
  start      Start this deployment mode. This is the default action.
  stop       Stop this deployment mode.
  restart    Stop and start this deployment mode.
  status     Show runtime status and probe HTTP endpoints.
  logs       Show logs.
  seed       Seed demo data.
  build      Build dependencies, assets, or images for this mode.
  reset      Reset one service. Requires --service <name>.

Options:
  --seed, -s              Force demo data seeding when start/restart runs.
  --no-seed              Skip automatic demo data seeding.
  --install-deps         Force npm install where this mode uses npm packages.
  --follow, -f           Follow logs.
  --tail <n>             Number of log lines to print. Default: 100.
  --service <name>       Service name for reset.
  --help, -h             Show this help.

EOF

  if [ -n "$SUPPORTED_SERVICES" ]; then
    cat <<EOF

Reset services:
  $SUPPORTED_SERVICES
EOF
  fi
}

parse_deploy_cli() {
  if [ "$CLI_PARSED" = "1" ]; then
    return
  fi

  if [ $# -gt 0 ]; then
    case "$1" in
      start|stop|restart|status|logs|seed|build|reset)
        DEPLOY_ACTION="$1"
        shift
        ;;
      -h|--help|help)
        print_common_usage
        exit 0
        ;;
      -*)
        ;;
      *)
        echo "Unsupported deployment action: $1" >&2
        print_common_usage >&2
        exit 2
        ;;
    esac
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      --seed|-s|-SeedDemoData)
        SEED_DEMO=1
        ;;
      --no-seed|-NoSeed)
        NO_SEED=1
        ;;
      --install-deps|-InstallDeps)
        INSTALL_DEPS=1
        ;;
      --follow|-f|-Follow)
        FOLLOW=1
        ;;
      --tail|-Tail)
        shift
        if [ $# -eq 0 ] || [ "${1#-}" != "$1" ]; then
          echo "Missing value for --tail" >&2
          exit 2
        fi
        TAIL="$1"
        ;;
      --service|-Service)
        shift
        if [ $# -eq 0 ] || [ "${1#-}" != "$1" ]; then
          echo "Missing value for --service" >&2
          exit 2
        fi
        DEPLOY_SERVICE="$1"
        ;;
      --help|-h|help)
        print_common_usage
        exit 0
        ;;
      *)
        echo "Unsupported option: $1" >&2
        print_common_usage >&2
        exit 2
        ;;
    esac
    shift
  done

  CLI_PARSED=1
}

ensure_state_dir() {
  mkdir -p "$LOG_DIR"
}

run_in() {
  local dir="$1"
  shift
  write_info "$*"
  (cd "$dir" && "$@")
}

require_command() {
  local name="$1"
  local install_hint="$2"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Missing required command: $name" >&2
    if [ -n "$install_hint" ]; then
      echo "$install_hint" >&2
    fi
    exit 127
  fi
}

require_curl() {
  require_command "curl" "Install curl, then rerun $DEFAULT_START_COMMAND."
}

require_docker() {
  require_command "docker" "Install Docker Desktop or Docker Engine with Compose v2, then rerun $DEFAULT_START_COMMAND."
}

get_compose_command() {
  if docker compose version >/dev/null 2>&1; then
    printf '%s\n' "docker compose"
    return
  fi

  if command -v docker-compose >/dev/null 2>&1 && docker-compose version >/dev/null 2>&1; then
    printf '%s\n' "docker-compose"
    return
  fi

  echo "Missing Docker Compose command: neither 'docker compose' nor 'docker-compose' is available." >&2
  echo "Install Docker Desktop/Engine with Compose support, then rerun $DEFAULT_START_COMMAND." >&2
  exit 127
}

require_go() {
  require_command "go" "Install Go 1.24 or newer, then rerun $DEFAULT_START_COMMAND."
}

require_npm() {
  require_command "npm" "Install Node.js and npm, then rerun $DEFAULT_START_COMMAND."
}

compose() {
  local project="$1"
  local file="$2"
  shift 2
  require_docker
  local compose_cmd
  compose_cmd=$(get_compose_command)
  write_info "$compose_cmd -p $project -f $file $*"
  if [ "$compose_cmd" = "docker compose" ]; then
    (cd "$REPO_ROOT" && MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" docker compose -p "$project" -f "$file" "$@")
  else
    (cd "$REPO_ROOT" && MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" docker-compose -p "$project" -f "$file" "$@")
  fi
}

compose_logs() {
  local project="$1"
  local file="$2"
  local args=(logs --tail "$TAIL")
  if [ "$FOLLOW" = "1" ]; then
    args+=(-f)
  fi
  compose "$project" "$file" "${args[@]}"
}

require_service() {
  if [ -z "$DEPLOY_SERVICE" ]; then
    echo "A service name is required for reset. Example: $DEFAULT_START_COMMAND reset --service backend" >&2
    exit 2
  fi
}

compose_reset_service() {
  local project="$1"
  local file="$2"
  require_service
  write_step "Resetting service '$DEPLOY_SERVICE'"
  compose "$project" "$file" up -d --build --force-recreate --no-deps "$DEPLOY_SERVICE"
}

compose_running_ids() {
  local project="$1"
  local file="$2"
  require_docker
  local compose_cmd
  compose_cmd=$(get_compose_command)
  if [ "$compose_cmd" = "docker compose" ]; then
    (cd "$REPO_ROOT" && MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" docker compose -p "$project" -f "$file" ps -q)
  else
    (cd "$REPO_ROOT" && MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" docker-compose -p "$project" -f "$file" ps -q)
  fi
}

assert_compose_running() {
  local project="$1"
  local file="$2"
  local start_command="$3"
  local ids
  ids=$(compose_running_ids "$project" "$file")
  if [ -z "$ids" ]; then
    echo "No running containers found for Compose project '$project'. Run '$start_command' first. If endpoints still respond, another Compose project may be holding the same ports." >&2
    exit 1
  fi
}

wait_http() {
  require_curl
  local url="$1"
  local timeout="${2:-90}"
  local end=$(( $(date +%s) + timeout ))
  while [ "$(date +%s)" -lt "$end" ]; do
    if curl -fsS -m 5 -o /dev/null "$url" 2>/dev/null; then
      write_info "OK: $url"
      return 0
    fi
    sleep 2
  done
  echo "Timed out waiting for $url" >&2
  exit 1
}

test_http() {
  require_curl
  local url="$1"
  local error_file="/tmp/talkdeskly-curl-error.$$"
  local code
  code=$(curl -sS -m 5 -o /dev/null -w "%{http_code}" "$url" 2>"$error_file" || true)
  if [ "$code" != "000" ] && [ -n "$code" ]; then
    write_info "$url -> HTTP $code"
  else
    local err
    err=$(cat "$error_file" 2>/dev/null || true)
    write_info "$url -> unavailable ($err)"
  fi
  rm -f "$error_file"
}

should_seed() {
  local default_seed="$1"
  if [ "$NO_SEED" = "1" ]; then
    return 1
  fi
  if [ "$SEED_DEMO" = "1" ]; then
    return 0
  fi
  [ "$default_seed" = "1" ]
}

ensure_npm_deps() {
  require_npm
  local dir="$1"
  local force="${2:-0}"
  local missing_bins=0
  if [ -f "$dir/package.json" ] && grep -q '"vite' "$dir/package.json" && [ ! -x "$dir/node_modules/.bin/vite" ]; then
    missing_bins=1
  fi

  if [ "$force" = "1" ] || [ ! -d "$dir/node_modules" ] || [ "$missing_bins" = "1" ]; then
    run_in "$dir" npm install
  else
    write_info "npm dependencies already installed in $dir"
  fi
}

dispatch_action() {
  case "$DEPLOY_ACTION" in
    start) start_mode ;;
    stop) stop_mode ;;
    restart) stop_mode; start_mode ;;
    status) status_mode ;;
    logs) logs_mode ;;
    seed) seed_mode ;;
    build) build_mode ;;
    reset) reset_mode ;;
    *)
      echo "Unsupported deployment action: $DEPLOY_ACTION" >&2
      exit 2
      ;;
  esac
}
