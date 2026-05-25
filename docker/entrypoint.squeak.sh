#!/bin/bash
set -e

SQUEAK_IMAGE=$(cat /opt/squeak/image_path.txt)
SQUEAK_BIN=$(which squeak)

case "$1" in
  --gui)
    echo "Squeak GUI + DAAT"
    exec "$SQUEAK_BIN" "$SQUEAK_IMAGE" /kethernet/daat.st
    ;;
  --gui-clean)
    echo "Squeak GUI limpio"
    exec "$SQUEAK_BIN" "$SQUEAK_IMAGE"
    ;;
  --cli)
    echo "Squeak CLI"
    exec "$SQUEAK_BIN" -headless "$SQUEAK_IMAGE"
    ;;
  --eval)
    shift
    exec "$SQUEAK_BIN" -headless "$SQUEAK_IMAGE" -e "$*"
    ;;
  *)
    exec "$SQUEAK_BIN" "$SQUEAK_IMAGE"
    ;;
esac