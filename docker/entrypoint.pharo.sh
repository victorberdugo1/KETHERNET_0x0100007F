#!/bin/bash
set -e
PHARO_IMAGE=/opt/pharo/Pharo.image
PHARO_BIN=/opt/pharo/vm/bin/pharo

# Copiar archivos de configuracion al volumen si no existen todavia
if [ ! -f /navi/navi.config ]; then
  cp /navi.config.default /navi/navi.config
  echo "NAVI :: navi.config copiado al volumen"
fi

if [ ! -f /navi/reshimu.json ]; then
  cp /reshimu.json.default /navi/reshimu.json
  echo "NAVI :: reshimu.jsonl copiado al volumen"
fi

case "$1" in
  --eval)
    shift
    exec "$PHARO_BIN" "$PHARO_IMAGE" eval "$*"
    ;;
  --st)
    shift
    exec "$PHARO_BIN" "$PHARO_IMAGE" st "$1"
    ;;
  --navi)
    exec "$PHARO_BIN" "$PHARO_IMAGE" st /smalltalk/navi_pharo_daat.st
    ;;
  --test)
    shift
    exec "$PHARO_BIN" "$PHARO_IMAGE" test "$*"
    ;;
  *)
    exec "$PHARO_BIN" "$PHARO_IMAGE" eval "Stdio stdout nextPutAll: 'Pharo OK'; lf."
    ;;
esac