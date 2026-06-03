#!/bin/bash
set -e

# Usa imagen checkpoint si existe en el volumen /navi
if [ -f /navi/squeak_navi.image ]; then
    SQUEAK_IMAGE=/navi/squeak_navi.image
    echo "KETHERNET :: reanudando desde /navi/squeak_navi.image"
else
    SQUEAK_IMAGE=$(cat /opt/squeak/image_path.txt)
    echo "KETHERNET :: imagen base: $SQUEAK_IMAGE"
fi

SQUEAK_BIN=$(which squeak)

case "$1" in
  --gui)
    echo "Squeak GUI + DAAT"
    exec "$SQUEAK_BIN" "$SQUEAK_IMAGE" /squeak/daat.st
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
  --navi)
    echo "KETHERNET :: Squeak NAVI servidor TCP :4444"
    exec "$SQUEAK_BIN" "$SQUEAK_IMAGE" /squeak/navi_squeak_daat.st
    ;;
  *)
    exec "$SQUEAK_BIN" "$SQUEAK_IMAGE"
    ;;
esac