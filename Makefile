build:
	docker compose build

up:
	xhost +local:docker 2>/dev/null || true
	docker compose up -d

down:
	docker compose down

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
	docker compose down --rmi all --volumes

.PHONY: build up down squeak-gui squeak-cli squeak-eval daat pharo pharo-eval pharo-st pharo-test logs clean