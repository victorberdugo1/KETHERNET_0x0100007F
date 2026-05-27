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
	docker compose run --rm --name kethernet-squeak -d squeak --gui
	@echo "DAAT :: Squeak lanzado, Pharo conectando..."
	docker compose run --rm -it pharo --eval "$(shell cat smalltalk/daat.st)"
navi:
	xhost +local:docker 2>/dev/null || true
	@echo "KETHERNET :: limpiando contenedor anterior..."
	-docker rm -f kethernet-squeak 2>/dev/null || true
	@echo "KETHERNET :: lanzando Squeak servidor (Da'at :4444)..."
	docker compose run \
		--rm \
		--name kethernet-squeak \
		--detach \
		--volume "$(PWD)/kethernet:/kethernet:ro" \
		squeak \
		--headless /kethernet/navi_squeak_daat.st
	@echo "KETHERNET :: esperando que Squeak abra socket..."
	@sleep 3
	@echo "KETHERNET :: Pharo conectando..."
	docker compose run \
		--rm \
		--interactive \
		--tty \
		--volume "$(PWD)/smalltalk:/smalltalk:ro" \
		pharo \
		--st /smalltalk/navi_pharo_daat.st

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

.PHONY: build up down logs squeak-gui squeak-cli squeak-eval daat pharo pharo-eval pharo-st pharo-test clean purge