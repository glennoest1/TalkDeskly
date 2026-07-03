#!/usr/bin/env bash
set -euo pipefail

. "$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/deploy-common.sh"

start_process() {
  local name="$1"
  local dir="$2"
  shift 2
  ensure_state_dir
  local stdout="$LOG_DIR/$name.out.log"
  local stderr="$LOG_DIR/$name.err.log"
  (cd "$dir" && "$@") >"$stdout" 2>"$stderr" &
  local pid=$!
  write_info "Started $name pid=$pid"
  printf '%s|%s|%s|%s|%s\n' "$name" "$pid" "$dir" "$stdout" "$stderr" >> "$PID_FILE"
}

stop_local_processes() {
  write_step "Stopping local host processes"
  if [ ! -f "$PID_FILE" ]; then
    write_info "No local process state found."
    return
  fi

  while IFS='|' read -r name pid cwd stdout stderr; do
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      write_info "Stopped $name pid=$pid"
    else
      write_info "Already stopped: $name pid=$pid"
    fi
  done < "$PID_FILE"
  rm -f "$PID_FILE"
}

seed_mode() {
  write_step "Seeding local demo data"
  require_go
  run_in "$REPO_ROOT/backend" go run . seed run
}

start_mode() {
  write_step "Starting local dependency containers"
  compose "talkdeskly-local" "docker-compose.dev.yml" up -d postgres redis mailhog

  write_step "Preparing local host processes"
  ensure_npm_deps "$REPO_ROOT/frontend" "$INSTALL_DEPS"
  ensure_npm_deps "$REPO_ROOT/chat-bubble" "$INSTALL_DEPS"

  stop_local_processes
  ensure_state_dir
  : > "$PID_FILE"
  require_go
  require_npm
  start_process "backend" "$REPO_ROOT/backend" go run .
  start_process "frontend" "$REPO_ROOT/frontend" npm run dev -- --host 0.0.0.0
  start_process "chat-bubble" "$REPO_ROOT/chat-bubble" npm run dev -- --host 0.0.0.0 --port 3000

  write_step "Waiting for local HTTP endpoints"
  wait_http "http://localhost:6721/health"
  wait_http "http://localhost:5173/"
  wait_http "http://localhost:3000/"
  wait_http "http://localhost:8025/"

  if should_seed 1; then
    seed_mode
  fi

  write_step "Local deployment ready"
  write_info "Admin frontend: http://localhost:5173"
  write_info "Chat widget:    http://localhost:3000"
  write_info "Backend:        http://localhost:6721"
  write_info "MailHog:        http://localhost:8025"
  write_info "Logs:           $LOG_DIR"
}

stop_mode() {
  stop_local_processes
}

status_mode() {
  write_step "Local process status"
  if [ ! -f "$PID_FILE" ]; then
    write_info "No local process state found."
  else
    while IFS='|' read -r name pid cwd stdout stderr; do
      if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        running=true
      else
        running=false
      fi
      write_info "$name pid=$pid running=$running"
      write_info "logs: $stdout | $stderr"
    done < "$PID_FILE"
  fi

  test_http "http://localhost:6721/health"
  test_http "http://localhost:5173/"
  test_http "http://localhost:3000/"
  test_http "http://localhost:8025/"
}

logs_mode() {
  write_step "Local deployment logs"
  ensure_state_dir
  mapfile -t files < <(find "$LOG_DIR" -maxdepth 1 -type f \( -name "*.out.log" -o -name "*.err.log" \) 2>/dev/null | sort)
  if [ "${#files[@]}" -eq 0 ]; then
    write_info "No local logs found. Run make local first."
    return
  fi
  if [ "$FOLLOW" = "1" ]; then
    tail -n "$TAIL" -f "${files[@]}"
  else
    for file in "${files[@]}"; do
      printf '\n--- %s\n' "$file"
      tail -n "$TAIL" "$file"
    done
  fi
}

build_mode() {
  write_step "Preparing local dependencies"
  ensure_npm_deps "$REPO_ROOT/frontend" 1
  ensure_npm_deps "$REPO_ROOT/chat-bubble" 1
  write_info "Go dependencies are resolved by go run/go build from backend/."
}

dispatch_action
