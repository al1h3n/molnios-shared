#!/bin/sh
# Fastfetch logo script
# Usage: fetch [-a|-b|-f] [-m FILE] [extra args...]
#   -a        Force anifetch
#   -b        Force brrtfetch
#   -f        Force fastfetch
#   -m FILE   Media file (video/gif/image) to use as logo
#   No flags  Autodetect best available tool

CONFIG="$L_PATH/config"
ASCII="$CONFIG/fastfetch-ascii"
FASTFETCH_CONF="$CONFIG/fastfetch.jsonc"

# --- Defaults per tool ---
ANIFETCH_W=60
ANIFETCH_H=30
BRRT_WIDTH=60
BRRT_FPS=17
BRRT_OFFSET=2

# --- Parse flags ---
FORCE_TOOL=""
MEDIA_FILE=""

while getopts "abfm:" opt; do
    case "$opt" in
        a) FORCE_TOOL="anifetch" ;;
        b) FORCE_TOOL="brrtfetch" ;;
        f) FORCE_TOOL="fastfetch" ;;
        m) MEDIA_FILE="$OPTARG" ;;
        *) echo "Usage: fetch [-a|-b|-f] [-m FILE] [extra args]"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))
# Remaining $@ are passed through to the chosen tool

# --- Autodetect tool if none forced ---
if [ -z "$FORCE_TOOL" ]; then
    if command -v anifetch > /dev/null 2>&1; then
        FORCE_TOOL="anifetch"
    elif command -v brrtfetch > /dev/null 2>&1; then
        FORCE_TOOL="brrtfetch"
    elif command -v fastfetch > /dev/null 2>&1; then
        FORCE_TOOL="fastfetch"
    else
        echo "Error: No fetch tool found (anifetch, brrtfetch, fastfetch)." >&2
        exit 1
    fi
fi

# --- Validate media file for animated tools ---
run_anifetch() {
    if [ -z "$MEDIA_FILE" ]; then
        echo "Error: -a (anifetch) requires a media file via -m FILE" >&2
        exit 1
    fi
    anifetch \
        -c "$FASTFETCH_CONF" \
        -W "$ANIFETCH_W" \
        -H "$ANIFETCH_H" \
        "$@" \
        "$MEDIA_FILE"
}

run_brrtfetch() {
    if [ -z "$MEDIA_FILE" ]; then
        echo "Error: -b (brrtfetch) requires a GIF file via -m FILE" >&2
        exit 1
    fi
    brrtfetch \
        -width "$BRRT_WIDTH" \
        -fps "$BRRT_FPS" \
        -offset "$BRRT_OFFSET" \
        -info "fastfetch --logo-type none --config $FASTFETCH_CONF" \
        "$@" \
        "$MEDIA_FILE"
}

run_fastfetch() {
    if [ -n "$MEDIA_FILE" ]; then
        # Detect media type by extension
        case "$MEDIA_FILE" in
            *.gif|*.mp4|*.webm|*.mkv|*.avi)
                echo "Warning: fastfetch doesn't support animated files, using as static image." >&2
                fastfetch --logo "$MEDIA_FILE" -c "$FASTFETCH_CONF" "$@"
                ;;
            *.png|*.jpg|*.jpeg|*.svg)
                fastfetch --logo "$MEDIA_FILE" -c "$FASTFETCH_CONF" "$@"
                ;;
            *)
                fastfetch --logo "$MEDIA_FILE" -c "$FASTFETCH_CONF" "$@"
                ;;
        esac
    else
        fastfetch --logo "$ASCII" -c "$FASTFETCH_CONF" "$@"
    fi
}

# --- Dispatch ---
case "$FORCE_TOOL" in
    anifetch)  run_anifetch "$@" ;;
    brrtfetch) run_brrtfetch "$@" ;;
    fastfetch) run_fastfetch "$@" ;;
esac