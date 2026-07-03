#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-dev}"
ACTION="${2:-start}"
if [ $# -gt 0 ]; then shift; fi
if [ $# -gt 0 ]; then shift; fi

SEED_DEMO=0
NO_SEED=0
INSTALL_DEPS=0
FOLLOW=0
TAIL=100

while [ $# -gt 0 ]; do
  case "$1" in
    -SeedDemoData) SEED_DEMO=1 ;;
    -NoSeed) NO_SEED=1 ;;
    -InstallDeps) INSTALL_DEPS=1 ;;
    -Follow) FOLLOW=1 ;;
    -Tail)
      shift
      TAIL="${1:-100}"
      ;;
    *)
      echo "Unsupported option: $1" >&2
      exit 2
      ;;
  esac
  shift
done

case "$MODE" in
  local|dev|prod) ;;
  *)
    echo "Unsupported deployment mode: $MODE" >&2
    exit 2
    ;;
esac

case "$ACTION" in
  start|stop|restart|status|logs|seed|build) ;;
  *)
    echo "Unsupported deployment action: $ACTION" >&2
    exit 2
    ;;
esac

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

export DEPLOY_ACTION="$ACTION"
export SEED_DEMO
export NO_SEED
export INSTALL_DEPS
export FOLLOW
export TAIL

exec bash "$SCRIPT_DIR/deploy-$MODE.sh"
