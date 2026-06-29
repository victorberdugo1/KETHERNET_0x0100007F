#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
BRIDGE_DIR="$ROOT_DIR/daat-bridge"
SEND="$BRIDGE_DIR/daat-send.txt"
RECV="$BRIDGE_DIR/daat-recv.txt"

SQUEAK_NAME="${SQUEAK_NAME:-kethernet-squeak}"
PHARO_CMD="${PHARO_CMD:-docker compose run --rm -T pharo --st /pharo/daat.st}"
SQUEAK_CMD="${SQUEAK_CMD:-docker compose run --rm -d --name kethernet-squeak squeak --gui}"

C_RESET=$'\033[0m'
C_CYAN=$'\033[0;36m'
C_GREEN=$'\033[0;32m'
C_YELLOW=$'\033[1;33m'
C_DIM=$'\033[2m'
C_BOLD=$'\033[1m'

READY_FLAG="$(mktemp /tmp/daat-ready.XXXXXX)"
PHARO_BG_PID=""

cleanup() {
  rm -f "$READY_FLAG"
  kill "$PHARO_BG_PID" 2>/dev/null || true
  docker rm -f "$SQUEAK_NAME" >/dev/null 2>&1 || true
}

on_exit() {
  cleanup
  echo ""
  echo -e "${C_DIM}Da'at :: canal cerrado${C_RESET}"
}

trap on_exit EXIT
trap 'exit 130' INT TERM

cd "$ROOT_DIR"

mkdir -p "$BRIDGE_DIR"
: > "$SEND"
: > "$RECV"

xhost +local:docker 2>/dev/null || true

echo -e "${C_BOLD}╔══════════════════════════════════════════╗${C_RESET}"
echo -e "${C_BOLD}║       Da'at :: canal bidireccional       ║${C_RESET}"
echo -e "${C_BOLD}║    Pharo [Region III]  ↔  Squeak [I]     ║${C_RESET}"
echo -e "${C_BOLD}╚══════════════════════════════════════════╝${C_RESET}"
echo ""

echo "DAAT :: Squeak lanzado — esperando Pharo..."
docker rm -f "$SQUEAK_NAME" >/dev/null 2>&1 || true
eval "$SQUEAK_CMD" >/dev/null
sleep 2

{
  eval "$PHARO_CMD" 2>&1 | while IFS= read -r line; do
    case "$line" in
      "PHARO_STATUS conectando")
        echo -e "${C_DIM}  iniciando sockets...${C_RESET}"
        ;;
      "PHARO_STATUS listo")
        echo -e "${C_DIM}  conectado. iniciando curriculum...${C_RESET}"
        ;;
      "PHARO_STATUS timeout_rx"|"PHARO_STATUS timeout_tx"|"PHARO_STATUS timeout"*)
        echo -e "${C_YELLOW}  ERROR: timeout conectando con Squeak${C_RESET}"
        touch "$READY_FLAG.failed"
        ;;
      "PHARO_STATUS curriculum_done")
        echo ""
        echo -e "${C_BOLD}════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}  Da'at :: canal interactivo abierto${C_RESET}"
        echo -e "${C_DIM}  escribe un mensaje y presiona Enter${C_RESET}"
        echo -e "${C_DIM}  Ctrl+C para salir${C_RESET}"
        echo -e "${C_BOLD}════════════════════════════════════════${C_RESET}"
        echo ""
        touch "$READY_FLAG"
        ;;
      CURRICULUM_SEND\ *)
        echo -e "  ${C_DIM}▸ ${line#CURRICULUM_SEND }${C_RESET}"
        ;;
      SQUEAK\ \>\>\ *)
        echo -e "  ${C_GREEN}SQUEAK${C_RESET} ${C_GREEN}>>${C_RESET} ${line#SQUEAK >> }"
        ;;
      DAAT_SENT\ *)
        : ;;
      PHARO_STATUS\ cerrado)
        break
        ;;
      *)
        [[ -n "$line" ]] && echo "$line"
        ;;
    esac
  done
} &
PHARO_BG_PID=$!

while [[ ! -f "$READY_FLAG" && ! -f "$READY_FLAG.failed" ]] && kill -0 "$PHARO_BG_PID" 2>/dev/null; do
  sleep 0.2
done

if [[ -f "$READY_FLAG.failed" ]] || ! kill -0 "$PHARO_BG_PID" 2>/dev/null; then
  echo -e "${C_YELLOW}Da'at :: Pharo terminó inesperadamente${C_RESET}"
  exit 1
fi

while kill -0 "$PHARO_BG_PID" 2>/dev/null; do
  printf "${C_CYAN}DAAT${C_RESET} ${C_BOLD}>>${C_RESET} "
  if ! IFS= read -r input < /dev/tty; then
    break
  fi

  input="$(printf '%s' "$input" | xargs 2>/dev/null || true)"
  [[ -z "$input" ]] && continue

  printf '%s\n' "$input" > "$SEND"
done