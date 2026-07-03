DEPLOY := bash ./scripts/deploy-dispatcher.sh

MODE ?= dev
ACTION ?= start
TAIL ?= 100
SERVICE ?=

FLAGS :=
ifeq ($(NO_SEED),1)
FLAGS += -NoSeed
endif
ifeq ($(SEED),1)
FLAGS += -SeedDemoData
endif
ifeq ($(INSTALL_DEPS),1)
FLAGS += -InstallDeps
endif
ifeq ($(FOLLOW),1)
FLAGS += -Follow
endif
ifneq ($(SERVICE),)
FLAGS += -Service $(SERVICE)
endif
FLAGS += -Tail $(TAIL)

.PHONY: help deploy local dev prod \
	local-stop dev-stop prod-stop \
	local-restart dev-restart prod-restart \
	local-reset dev-reset prod-reset \
	local-status dev-status prod-status \
	local-logs dev-logs prod-logs \
	local-seed dev-seed prod-seed \
	local-build dev-build prod-build \
	logs seed build status stop restart reset

help:
	@printf '%s\n' 'TalkDeskly deployment targets'
	@printf '%s\n' ''
	@printf '%s\n' '  make local                 Start host-run local mode'
	@printf '%s\n' '  make dev                   Start Docker development mode'
	@printf '%s\n' '  make prod                  Start production mode'
	@printf '%s\n' ''
	@printf '%s\n' '  make local-status          Check local mode'
	@printf '%s\n' '  make dev-status            Check Docker development mode'
	@printf '%s\n' '  make prod-status           Check production mode'
	@printf '%s\n' ''
	@printf '%s\n' '  make local-logs            Show local logs'
	@printf '%s\n' '  make dev-logs              Show Docker development logs'
	@printf '%s\n' '  make prod-logs             Show production logs'
	@printf '%s\n' ''
	@printf '%s\n' '  make local-seed            Seed local demo data'
	@printf '%s\n' '  make dev-seed              Seed Docker development demo data'
	@printf '%s\n' '  make prod-seed             Seed production demo data'
	@printf '%s\n' ''
	@printf '%s\n' '  make local-build           Install local frontend/widget deps'
	@printf '%s\n' '  make dev-build             Build Docker development images'
	@printf '%s\n' '  make prod-build            Build frontend/widget assets and production image'
	@printf '%s\n' ''
	@printf '%s\n' '  make local-stop            Stop local host processes'
	@printf '%s\n' '  make dev-stop              Stop Docker development mode'
	@printf '%s\n' '  make prod-stop             Stop production mode'
	@printf '%s\n' ''
	@printf '%s\n' '  make local-reset SERVICE=frontend'
	@printf '%s\n' '  make dev-reset SERVICE=backend'
	@printf '%s\n' '  make prod-reset SERVICE=backend'
	@printf '%s\n' ''
	@printf '%s\n' '  make deploy MODE=dev ACTION=restart'
	@printf '%s\n' '  make deploy MODE=dev ACTION=reset SERVICE=backend'
	@printf '%s\n' '  make deploy MODE=dev ACTION=logs FOLLOW=1 TAIL=200'
	@printf '%s\n' '  make dev NO_SEED=1'
	@printf '%s\n' '  make prod SEED=1'
	@printf '%s\n' '  make local INSTALL_DEPS=1'

deploy:
	$(DEPLOY) $(MODE) $(ACTION) $(FLAGS)

local:
	$(DEPLOY) local start $(FLAGS)

dev:
	$(DEPLOY) dev start $(FLAGS)

prod:
	$(DEPLOY) prod start $(FLAGS)

local-stop:
	$(DEPLOY) local stop

dev-stop:
	$(DEPLOY) dev stop

prod-stop:
	$(DEPLOY) prod stop

local-restart:
	$(DEPLOY) local restart $(FLAGS)

dev-restart:
	$(DEPLOY) dev restart $(FLAGS)

prod-restart:
	$(DEPLOY) prod restart $(FLAGS)

local-reset:
	$(DEPLOY) local reset $(FLAGS)

dev-reset:
	$(DEPLOY) dev reset $(FLAGS)

prod-reset:
	$(DEPLOY) prod reset $(FLAGS)

local-status:
	$(DEPLOY) local status

dev-status:
	$(DEPLOY) dev status

prod-status:
	$(DEPLOY) prod status

local-logs:
	$(DEPLOY) local logs $(FLAGS)

dev-logs:
	$(DEPLOY) dev logs $(FLAGS)

prod-logs:
	$(DEPLOY) prod logs $(FLAGS)

local-seed:
	$(DEPLOY) local seed

dev-seed:
	$(DEPLOY) dev seed

prod-seed:
	$(DEPLOY) prod seed

local-build:
	$(DEPLOY) local build $(FLAGS)

dev-build:
	$(DEPLOY) dev build $(FLAGS)

prod-build:
	$(DEPLOY) prod build $(FLAGS)

status:
	$(DEPLOY) $(MODE) status

stop:
	$(DEPLOY) $(MODE) stop

restart:
	$(DEPLOY) $(MODE) restart $(FLAGS)

reset:
	$(DEPLOY) $(MODE) reset $(FLAGS)

logs:
	$(DEPLOY) $(MODE) logs $(FLAGS)

seed:
	$(DEPLOY) $(MODE) seed

build:
	$(DEPLOY) $(MODE) build $(FLAGS)
