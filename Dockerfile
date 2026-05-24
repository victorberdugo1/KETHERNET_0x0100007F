# KETHERNET — Entorno Squeak Smalltalk
# La red que se señala a sí misma.
#
# CLI (por defecto):
#   docker run --rm kethernet
#
# GUI (Morphic, requiere display):
#   docker run --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix kethernet --gui
#
# Evaluar una expresión:
#   docker run --rm kethernet --eval "3 + 4 printString"

FROM debian:bookworm-slim

LABEL description="Squeak Smalltalk environment for KETHERNET — 0x0100007F"

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    # X11 + SM — necesarias incluso en headless porque el VM las linkea al arrancar
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxrandr2 \
    libxt6 \
    libsm6 \
    libice6 \
    # OpenGL (fallback software)
    libgl1-mesa-glx \
    # Audio (el VM intenta abrir ALSA/Pulse incluso sin sonido)
    libasound2 \
    libpulse0 \
    libpulsedsp \
    # SSL
    libssl3 \
    # Locale
    locales \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

WORKDIR /opt/squeak

ENV SQUEAK_BUNDLE=Squeak6.0-22148-64bit-202312181441-Linux-x64.tar.gz
ENV SQUEAK_URL=https://files.squeak.org/6.0/Squeak6.0-22148-64bit/${SQUEAK_BUNDLE}

RUN wget --no-verbose "$SQUEAK_URL" -O squeak.tar.gz \
    && tar -xzf squeak.tar.gz \
    && rm squeak.tar.gz \
    && find /opt/squeak -maxdepth 4 | sort

RUN SQUEAK_BIN=$(find /opt/squeak -name "squeak" -type f -executable | head -1) \
    && SQUEAK_IMAGE=$(find /opt/squeak -name "*.image" | head -1) \
    && echo "VM:    $SQUEAK_BIN" \
    && echo "Image: $SQUEAK_IMAGE" \
    && test -n "$SQUEAK_BIN"  || (echo "ERROR: VM no encontrado";    exit 1) \
    && test -n "$SQUEAK_IMAGE" || (echo "ERROR: .image no encontrado"; exit 1) \
    && ln -sf "$SQUEAK_BIN" /usr/local/bin/squeak \
    && echo "$SQUEAK_IMAGE" > /opt/squeak/image_path.txt

WORKDIR /kethernet
COPY . .
RUN chmod +x /kethernet/docker/entrypoint.sh

ENTRYPOINT ["/kethernet/docker/entrypoint.sh"]
CMD []