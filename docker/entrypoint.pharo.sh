#!/bin/sh
set -e

PHARO_IMAGE=/opt/pharo/Pharo.image
PHARO_BIN=/opt/pharo/vm/bin/pharo

case "$1" in
  --eval)
    shift
    exec "$PHARO_BIN" "$PHARO_IMAGE" eval "$*"
    ;;
  --st)
    shift
    FILE="$1"
    exec "$PHARO_BIN" "$PHARO_IMAGE" eval "
| code |
code := '$FILE' asFileReference readStream contents.
Smalltalk compiler evaluate: code.
"
    ;;
  --test)
    shift
    exec "$PHARO_BIN" "$PHARO_IMAGE" test "$*"
    ;;
  *)
    exec "$PHARO_BIN" "$PHARO_IMAGE" eval "Stdio stdout nextPutAll: 'Pharo headless OK'; lf."
    ;;
esac
