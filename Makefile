# ============================================================
# KETHERNET Makefile
# ============================================================

build:
	docker compose build

up:
	xhost +local:docker 2>/dev/null || true
	docker compose up -d

down:
	docker compose down --remove-orphans

logs:
	docker compose logs -f

squeak-gui:
	xhost +local:docker 2>/dev/null || true
	docker compose run --rm squeak --gui-clean

squeak-cli:
	docker compose run --rm squeak --cli

squeak-eval:
	@test -n "$(EXPR)" || (echo "EXPR required"; exit 1)
	docker compose run --rm squeak --eval "$(EXPR)"

daat:
	xhost +local:docker 2>/dev/null || true
	-docker rm -f kethernet-squeak 2>/dev/null || true
	docker compose run --rm --name kethernet-squeak -d squeak --gui
	@echo "DAAT :: Squeak lanzado — esperando Pharo..."
	@sleep 2
	docker compose run --rm -it pharo --st /smalltalk/daat.st

# ============================================================
# NAVI — daat.st no se toca
# Squeak: kethernet/navi_squeak_daat.st  (servidor :4444 + Qwen)
# Pharo:  smalltalk/navi_pharo_daat.st   (cliente interactivo)
# ============================================================
navi:
	xhost +local:docker 2>/dev/null || true
	@echo "KETHERNET :: sembrando volumen navi-data desde host..."
	@test -f kethernet/memory.md || (test -f memory.md && cp memory.md kethernet/memory.md) || echo "# Memoria NAVI" > kethernet/memory.md
	@test -f kethernet/dataset.jsonl || echo '{"prompt":"inicio","completion":"primera sesion NAVI"}' > kethernet/dataset.jsonl
	docker compose run --rm \
		-v "$$(pwd)/kethernet:/seed:ro" \
		pharo eval "| src dst | #('memory.md' 'dataset.jsonl') do: [:name | src := ('/seed/' , name) asFileReference. dst := ('/navi/' , name) asFileReference. dst exists ifFalse: [dst writeStreamDo: [:f | f nextPutAll: src contents]]]."
	@echo "KETHERNET :: limpiando contenedor anterior..."
	-docker rm -f kethernet-squeak 2>/dev/null || true
	@echo "KETHERNET :: lanzando Squeak NAVI servidor TCP :4444..."
	docker compose run \
		--rm \
		--name kethernet-squeak \
		--detach \
		squeak --navi
	@echo "KETHERNET :: esperando que Squeak abra socket..."
	@sleep 3
	@echo "KETHERNET :: Pharo NAVI conectando..."
	docker compose run \
		--rm \
		--interactive \
		--tty \
		pharo --navi

pharo:
	docker compose run --rm pharo

pharo-eval:
	@test -n "$(EXPR)" || (echo "EXPR required"; exit 1)
	docker compose run --rm pharo --eval "$(EXPR)"

pharo-st:
	@test -n "$(FILE)" || (echo "FILE required"; exit 1)
	docker compose run --rm pharo --st /$(FILE)

pharo-test:
	@test -n "$(PKG)" || (echo "PKG required"; exit 1)
	docker compose run --rm pharo --test "$(PKG)"

clean:
	docker compose down --rmi all --volumes --remove-orphans

purge:
	@echo "KETHERNET :: PURGING DOCKER REALITY"
	-docker compose down --rmi all --volumes --remove-orphans
	-docker rm -f $$(docker ps -aq) 2>/dev/null || true
	-docker network prune -f
	-docker volume prune -f
	-docker image prune -af
	-docker container prune -f
	@echo "KETHERNET :: VOID STATE REACHED"

.PHONY: build up down logs squeak-gui squeak-cli squeak-eval daat navi navi-repl pharo pharo-eval pharo-st pharo-test clean purge
navi-repl:
	@echo "KETHERNET :: abriendo REPL manual hacia Squeak..."
	docker compose run \
		--rm \
		--interactive \
		--tty \
		pharo --repl