IMAGE   := kethernet
DISPLAY ?= :0
XSOCK   := /tmp/.X11-unix

# ─── build ───────────────────────────────────────────────────────────────────

build:
	docker build -t $(IMAGE) .

rebuild:
	docker build --no-cache -t $(IMAGE) .

# ─── compose (up / down) ─────────────────────────────────────────────────────

up:
	docker compose --profile cli up -d

up-gui:
	xhost +local:docker 2>/dev/null || true
	docker compose --profile gui up -d

up-dev:
	docker compose --profile dev up -d

down:
	docker compose --profile cli --profile gui --profile dev down

restart: down up

# ─── run (one-shot, sin compose) ─────────────────────────────────────────────

cli: build
	docker run --rm --cap-add SYS_NICE $(IMAGE) --cli

gui: build
	xhost +local:docker 2>/dev/null || true
	docker run --rm --cap-add SYS_NICE \
		-e DISPLAY=$(DISPLAY) \
		-v $(XSOCK):$(XSOCK):rw \
		$(IMAGE) --gui

eval: build
	@test -n "$(EXPR)" || (echo 'Uso: make eval EXPR="3 + 4"'; exit 1)
	docker run --rm --cap-add SYS_NICE $(IMAGE) --eval '$(EXPR)'

# ─── dev ─────────────────────────────────────────────────────────────────────

dev: build
	docker run --rm -it --cap-add SYS_NICE \
		-v $(PWD)/smalltalk:/kethernet/smalltalk:rw \
		-v $(PWD)/docs:/kethernet/docs:ro \
		$(IMAGE) --shell

shell: build
	docker run --rm -it --cap-add SYS_NICE $(IMAGE) bash

# ─── util ────────────────────────────────────────────────────────────────────

ps:
	docker compose ps

logs:
	docker compose --profile cli --profile gui --profile dev logs --tail=50

clean:
	docker compose --profile cli --profile gui --profile dev down --rmi local 2>/dev/null || true
	docker rmi -f $(IMAGE) 2>/dev/null || true

help:
	@echo ""
	@echo "  make up          → compose CLI en background"
	@echo "  make up-gui      → compose GUI en background"
	@echo "  make down        → para y elimina todos los contenedores"
	@echo "  make restart     → down + up"
	@echo "  make ps          → estado de los contenedores"
	@echo "  make logs        → logs de todos los perfiles"
	@echo ""
	@echo "  make cli         → one-shot headless (sin compose)"
	@echo "  make gui         → one-shot GUI (sin compose)"
	@echo "  make eval EXPR=\"3 + 4\""
	@echo ""
	@echo "  make build       → construye la imagen"
	@echo "  make rebuild     → rebuild sin caché"
	@echo "  make shell       → bash dentro del contenedor"
	@echo "  make clean       → elimina imagen y contenedores"
	@echo ""

.PHONY: build rebuild up up-gui up-dev down restart cli gui eval dev shell ps logs clean help