#!/bin/sh
# Fastfetch logo script
# Usage: fetch [-a|-b|-f] [-m FILE] [extra args...]
#   -a        Force anifetch
#   -b        Force brrtfetch
#   -f        Force fastfetch
#   -m FILE   Media file (video/gif/image) to use as logo
#   -w        Set custom width to media file
#   -h        Set custom height to media file
#   -p        Position of media file (top/left/right/bottom)
#   No flags  Autodetect best available tool

CONFIG="$L_PATH/config"
ASCII="$CONFIG/fastfetch-ascii"
FASTFETCH_CONF="$CONFIG/fastfetch.jsonc"

# --- Defaults per tool ---
ANIFETCH_W=60
ANIFETCH_H=$ANIFETCH_W
BRRT_W=60
BRRT_H=$BRRT_W
BRRT_FPS=17
BRRT_OFFSET=2

WIDTH=""
HEIGHT=""
POSITION=""

# --- Parse flags ---
FORCE_TOOL=""
MEDIA_FILE=""

while getopts "abfm:w:h:p:" opt; do
    case "$opt" in
        a) FORCE_TOOL="anifetch" ;;
        b) FORCE_TOOL="brrtfetch" ;;
        f) FORCE_TOOL="fastfetch" ;;
        m) MEDIA_FILE="$OPTARG" ;;
        w) WIDTH="$OPTARG" ;;
        h) HEIGHT="$OPTARG" ;;
        p) POSITION="$OPTARG" ;;
        *) echo "Usage: fetch.sh [-a|-b|-f] [-m FILE] [-w WIDTH] [-h HEIGHT] [extra args]"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))
# Remaining $@ are passed through to the chosen tool

# Set width & height to each tool.
[ -n "$WIDTH" ] && ANIFETCH_W="$WIDTH"
[ -n "$HEIGHT" ] && ANIFETCH_H="$HEIGHT"

[ -n "$WIDTH" ] && BRRT_WIDTH="$WIDTH"
[ -n "$HEIGHT" ] && BRRT_HEIGHT="$HEIGHT"

FASTFETCH_W="$WIDTH"
FASTFETCH_H="$HEIGHT"

if [ -n "$POSITION" ]; then
    case "$POSITION" in
        left|right|top|bottom) ;;
        *)
            echo "Error: invalid position '$POSITION' (must be left, right, top, or bottom)" >&2
            exit 1
            ;;
    esac
fi

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
        -width "$BRRT_W" \
        -height "$BRRT_H" \
        -fps "$BRRT_FPS" \
        -offset "$BRRT_OFFSET" \
        -info "fastfetch --logo-type none --config $FASTFETCH_CONF" \
        "$@" \
        "$MEDIA_FILE"
}

run_fastfetch() {
    LOGO_ARGS=""

    [ -n "$FASTFETCH_W" ] && LOGO_ARGS="$LOGO_ARGS --logo-width $FASTFETCH_W"
    [ -n "$FASTFETCH_H" ] && LOGO_ARGS="$LOGO_ARGS --logo-height $FASTFETCH_H"
    [ -n "$POSITION" ] && LOGO_ARGS="$LOGO_ARGS --logo-position $POSITION"

    if [ -n "$MEDIA_FILE" ]; then
        fastfetch --logo "$MEDIA_FILE" $LOGO_ARGS -c "$FASTFETCH_CONF" "$@"
    else
        fastfetch --logo "$ASCII" $LOGO_ARGS -c "$FASTFETCH_CONF" "$@"
    fi
}

# --- Dispatch ---
case "$FORCE_TOOL" in
    anifetch)  run_anifetch "$@" ;;
    brrtfetch) run_brrtfetch "$@" ;;
    fastfetch) run_fastfetch "$@" ;;
esac