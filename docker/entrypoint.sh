#!/bin/bash
set -e

SQUEAK_IMAGE=$(cat /opt/squeak/image_path.txt 2>/dev/null || find /opt/squeak -name "*.image" | head -1)
SQUEAK_BIN=$(which squeak 2>/dev/null || find /opt/squeak -name "squeak" -executable | head -1)

banner() {
    echo ""
    echo "╔══════════════════════════════════════╗"
    echo "║  KETHERNET  0x0100007F               ║"
    echo "║  La red que se señala a sí misma     ║"
    echo "╚══════════════════════════════════════╝"
    echo ""
}

filter_vm_noise() {
    grep -v "pthread_setschedparam" \
    | grep -v "heartbeat thread" \
    | grep -v "higher priority" \
    | grep -v "limits.d" \
    | grep -v "rtprio" \
    | grep -v "squeak mailing list" \
    | grep -v "opensmalltalk-vm" \
    | grep -v "log out and log back" \
    | grep -v "vm-sound-pulse" \
    | grep -v "vm-sound-null" \
    | grep -v "libpulse" \
    || true
}

# Auto-detectar DISPLAY para WSL2
detect_display() {
    # Si ya hay DISPLAY configurado, usarlo
    if [ -n "$DISPLAY" ]; then
        echo "$DISPLAY"
        return
    fi
    # WSL2: el host Windows es la gateway de la red
    local WSL_HOST
    WSL_HOST=$(cat /etc/resolv.conf 2>/dev/null | grep nameserver | awk '{print $2}' | head -1)
    if [ -n "$WSL_HOST" ]; then
        echo "${WSL_HOST}:0.0"
        return
    fi
    # Fallback Linux nativo
    echo ":0"
}

HEADLESS_FLAGS="-vm-sound-null -vm-display-null"

banner

case "$1" in

    --gui)
        DETECTED_DISPLAY=$(detect_display)
        echo "Modo: GUI (Morphic)"
        echo "Display: $DETECTED_DISPLAY"
        echo ""
        exec "$SQUEAK_BIN" -vm-sound-null \
            -display "$DETECTED_DISPLAY" \
            "$SQUEAK_IMAGE" \
            2> >(filter_vm_noise >&2)
        ;;

    --cli)
        echo "Modo: CLI (headless)"
        echo ""
        "$SQUEAK_BIN" $HEADLESS_FLAGS -headless "$SQUEAK_IMAGE" \
            -e "
| st src |
[
    st := FileStream readOnlyFileNamed: '/kethernet/kethernet.st'.
    src := st contents.
    st close.
    Compiler evaluate: src.
] on: Error do: [:e |
    FileStream stdout nextPutAll: 'Error: '; nextPutAll: e messageText; nl.
].
Smalltalk exit.
            " \
            2> >(filter_vm_noise >&2)
        ;;

    --eval)
        shift
        echo "→ $*"
        echo ""
        "$SQUEAK_BIN" $HEADLESS_FLAGS -headless "$SQUEAK_IMAGE" \
            -e "
| out |
out := FileStream stdout.
[ out nextPutAll: ($*) printString; nl. ]
    on: Error do: [:e | out nextPutAll: 'Error: '; nextPutAll: e messageText; nl. ].
Smalltalk exit.
            " \
            2> >(filter_vm_noise >&2)
        ;;

    *)
        echo "Comandos:"
        echo ""
        echo "  GUI (entorno Squeak completo):"
        echo "    # Desde WSL — asegúrate de tener VcXsrv corriendo en Windows:"
        echo "    docker run --rm -e DISPLAY=\$(cat /etc/resolv.conf | grep nameserver | awk '{print \$2}'):0.0 \\"
        echo "               -v /tmp/.X11-unix:/tmp/.X11-unix \\"
        echo "               kethernet --gui"
        echo ""
        echo "  CLI (solo output de texto):"
        echo "    docker run --rm kethernet --cli"
        echo ""
        echo "  Evaluar expresión:"
        echo "    docker run --rm kethernet --eval '3 + 4'"
        echo ""
        ;;
esac