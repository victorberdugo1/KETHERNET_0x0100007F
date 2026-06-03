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
	docker compose run --rm -it pharo --st /pharo/daat.st

# ============================================================
# NAVI — daat.st no se toca
# Squeak: squeak/navi_squeak_daat.st  (servidor :4444)
# Pharo:  pharo/navi_pharo_daat.st    (loop LLM)
#
# FIX 3: memory.md se SIEMPRE sobreescribe desde squeak/memory.md
# para que el volumen persistido no quede varado con una version vieja/vacia.
# El seed se monta en /seed dentro del contenedor Pharo NAVI.
# navi_pharo_daat.st llama seedMemoryIfNeeded: '/seed/memory.md'
# al arrancar, copiando el seed a /navi/memory.md antes de leer el nivel.
# ============================================================
navi:
	xhost +local:docker 2>/dev/null || true
	@echo "KETHERNET :: preparando seed en squeak/..."
	@test -f squeak/memory.md || (test -f memory.md && cp memory.md squeak/memory.md) || echo "# Memoria NAVI" > squeak/memory.md
	@test -f squeak/dataset.json || echo '{"prompt":"inicio","completion":"primera sesion NAVI"}' > squeak/dataset.json
	@echo "KETHERNET :: sembrando dataset en volumen navi-data..."
	docker compose run --rm \
		-v "$$(pwd)/squeak:/seed:ro" \
		pharo eval "| src dst | #('dataset.json') do: [:name | src := ('/seed/' , name) asFileReference. dst := ('/navi/' , name) asFileReference. dst exists ifFalse: [dst writeStreamDo: [:f | f nextPutAll: src contents]]]."
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
	@echo "KETHERNET :: Pharo NAVI conectando (seed montado en /seed)..."
	docker compose run \
		--rm \
		--interactive \
		--tty \
		-v "$$(pwd)/squeak:/seed:ro" \
		pharo --navi

# Inspect: ver el memory.md actual del volumen
navi-memory:
	@echo "=== /navi/memory.md actual ==="
	docker compose run --rm pharo eval "Stdio stdout nextPutAll: '/navi/memory.md' asFileReference contents."

# Inspect: ver el dataset actual
navi-dataset:
	@echo "=== /navi/dataset.json actual ==="
	docker compose run --rm pharo eval "Stdio stdout nextPutAll: '/navi/dataset.json' asFileReference contents."

# Forzar reset del volumen (borra progreso)
navi-reset:
	@echo "KETHERNET :: borrando volumen navi-data..."
	docker compose down --volumes
	@echo "KETHERNET :: volumen borrado. Proxima llamada a 'make navi' parte de cero."

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

.PHONY: build up down logs squeak-gui squeak-cli squeak-eval daat navi navi-repl navi-memory navi-dataset navi-reset pharo pharo-eval pharo-st pharo-test clean purge

navi-repl:
	@echo "KETHERNET :: abriendo REPL manual hacia Squeak..."
	docker compose run \
		--rm \
		--interactive \
		--tty \
		pharo --repl