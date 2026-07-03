ifeq ($(OS),Windows_NT)
DEPLOY := powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\deploy-dispatcher.ps1
else
DEPLOY := pwsh -NoProfile -ExecutionPolicy Bypass -File ./scripts/deploy-dispatcher.ps1
endif

MODE ?= dev
ACTION ?= start
TAIL ?= 100

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
FLAGS += -Tail $(TAIL)

.PHONY: help deploy local dev prod \
	local-stop dev-stop prod-stop \
	local-restart dev-restart prod-restart \
	local-status dev-status prod-status \
	local-logs dev-logs prod-logs \
	local-seed dev-seed prod-seed \
	local-build dev-build prod-build \
	logs seed build status stop restart

help:
	@echo TalkDeskly deployment targets
	@echo.
	@echo   make local                 Start host-run local mode
	@echo   make dev                   Start Docker development mode
	@echo   make prod                  Start production mode
	@echo.
	@echo   make local-status          Check local mode
	@echo   make dev-status            Check Docker development mode
	@echo   make prod-status           Check production mode
	@echo.
	@echo   make local-logs            Show local logs
	@echo   make dev-logs              Show Docker development logs
	@echo   make prod-logs             Show production logs
	@echo.
	@echo   make local-seed            Seed local demo data
	@echo   make dev-seed              Seed Docker development demo data
	@echo   make prod-seed             Seed production demo data
	@echo.
	@echo   make local-build           Install local frontend/widget deps
	@echo   make dev-build             Build Docker development images
	@echo   make prod-build            Build frontend/widget assets and production image
	@echo.
	@echo   make local-stop            Stop local host processes
	@echo   make dev-stop              Stop Docker development mode
	@echo   make prod-stop             Stop production mode
	@echo.
	@echo   make deploy MODE=dev ACTION=restart
	@echo   make deploy MODE=dev ACTION=logs FOLLOW=1 TAIL=200
	@echo   make dev NO_SEED=1
	@echo   make prod SEED=1
	@echo   make local INSTALL_DEPS=1

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

logs:
	$(DEPLOY) $(MODE) logs $(FLAGS)

seed:
	$(DEPLOY) $(MODE) seed

build:
	$(DEPLOY) $(MODE) build $(FLAGS)
