#!/usr/bin/env bash
# termcolors.sh - Dynamic terminal color theming for MolniOS
# Part of the MolniOS project.
# ==============================================================================
# Called by waypaper as a post_command, or directly from the terminal.
#
# USAGE
#   termcolors.sh [FLAGS] <wallpaper> [video]
#
# FLAGS
#   -w, --wallust          Use wallust as color backend  (default if neither given)
#   -p, --pywal            Use pywal16 (wal -i) as color backend
#                          Cannot be combined with -w/--wallust → exits with error
#   -nb, --no-borderline   Skip borderline after the color backend runs.
#                          By default borderline always runs unless this flag is set.
#   -h, --help             Print this help and exit
#
# EXAMPLES
#   # waypaper post_command (reads config as default when no backend flag given):
#   post_command = sh ~/.local/share/molnios/scripts/termcolors.sh $wallpaper $video
#
#   # Explicit waypaper post_command (ignores config, wallust + borderline):
#   post_command = sh ~/.local/share/molnios/scripts/termcolors.sh -w $wallpaper $video
#
#   # Terminal: pywal only, no borderline, static image:
#   termcolors.sh -p -nb /path/to/wall.jpg
#
#   # Terminal: wallust + borderline, video file:
#   termcolors.sh -w /path/to/wallpapers/loop.mp4
#
# CONFIG (used only when no -w/-p flag is passed)
#   ~/.config/molnios/termcolors.conf
#     BACKEND=wallust   # wallust | pywal | none
#     BORDERLINE=yes    # yes | no
# ==============================================================================

set -euo pipefail

# ── Resolve L_PATH ────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
L_PATH="$(dirname "$SCRIPT_DIR")"   # ~/.local/share/molnios

# ── Load NixOS / home-manager environment if needed ──────────────────────────

if [ -f /etc/profiles/per-user/"$(whoami)"/etc/profile.d/hm-session-vars.sh ]; then
    . /etc/profiles/per-user/"$(whoami)"/etc/profile.d/hm-session-vars.sh
fi
[ -f ~/.nix-profile/etc/profile.d/nix.sh ] && \
    . ~/.nix-profile/etc/profile.d/nix.sh
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# ── Notification helpers ──────────────────────────────────────────────────────

_notify(){
    command -v notify-send &>/dev/null && \
        notify-send -h int:transient:1 "termcolors" "$1"
}

_notify_err(){
    command -v notify-send &>/dev/null && \
        notify-send -h int:transient:1 -u critical "termcolors" "$1"
}

_die(){
    local msg="$1"
    echo "termcolors: error: $msg" >&2
    _notify_err "$msg"
    exit 1
}

_usage(){
    grep '^#' "$0" | grep -v '#!/' | sed 's/^# \{0,1\}//' | \
        sed -n '/^termcolors\.sh/,/^CONFIG/p'
    exit 0
}

# ── Parse flags ───────────────────────────────────────────────────────────────

FLAG_WALLUST=false
FLAG_PYWAL=false
FLAG_NO_BORDERLINE=false
BACKEND_FLAG_GIVEN=false
WALLPAPER=""
VIDEO=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -w|--wallust)
            FLAG_WALLUST=true
            BACKEND_FLAG_GIVEN=true
            shift
            ;;
        -p|--pywal|--pywal16)
            FLAG_PYWAL=true
            BACKEND_FLAG_GIVEN=true
            shift
            ;;
        -nb|--no-borderline)
            FLAG_NO_BORDERLINE=true
            shift
            ;;
        -h|--help)
            _usage
            ;;
        -*)
            _die "Unknown flag '$1'. Use -h for help."
            ;;
        *)
            # Positional: first non-flag = wallpaper, second = video
            if [[ -z "$WALLPAPER" ]]; then
                WALLPAPER="$1"
            elif [[ -z "$VIDEO" ]]; then
                VIDEO="$1"
            else
                _die "Unexpected extra argument: '$1'"
            fi
            shift
            ;;
    esac
done

# ── Mutually exclusive backend check ─────────────────────────────────────────

if $FLAG_WALLUST && $FLAG_PYWAL; then
    _die "--wallust (-w) and --pywal (-p) are mutually exclusive. Pick one."
fi

# ── Resolve backend from config (only when no CLI backend flag given) ─────────

BACKEND="wallust"       # hard default
RUN_BORDERLINE=true     # hard default

if ! $BACKEND_FLAG_GIVEN; then
    CONF_FILE=$L_PATH/config/termcolors.conf
    if [[ -f "$CONF_FILE" ]]; then
        _read(){ grep -E "^[[:space:]]*${1}[[:space:]]*=" "$CONF_FILE" \
                 | tail -n1 | cut -d= -f2- \
                 | sed "s/^[[:space:]\"']*//;s/[[:space:]\"']*$//"; }
        _b=$(_read BACKEND); [[ -n "$_b" ]] && BACKEND="$_b"
        _bl=$(_read BORDERLINE)
        [[ "$_bl" == "no" || "$_bl" == "false" || "$_bl" == "0" ]] && \
            RUN_BORDERLINE=false
    fi
else
    # CLI flags win — map them to backend/borderline vars
    $FLAG_WALLUST && BACKEND="wallust"
    $FLAG_PYWAL   && BACKEND="pywal"
fi

# -nb flag always overrides, regardless of config or defaults
$FLAG_NO_BORDERLINE && RUN_BORDERLINE=false

# ── Validate source file ──────────────────────────────────────────────────────

if [[ -n "$VIDEO" && -f "$VIDEO" ]]; then
    SOURCE_FILE="$VIDEO"
    IS_VIDEO=true
elif [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]]; then
    SOURCE_FILE="$WALLPAPER"
    # Auto-detect video by mime type
    if command -v file &>/dev/null && \
       file --mime-type -b "$SOURCE_FILE" 2>/dev/null | grep -q "^video/"; then
        IS_VIDEO=true
    else
        IS_VIDEO=false
    fi
else
    _die "No valid file found.\n  wallpaper='${WALLPAPER:-<empty>}'\n  video='${VIDEO:-<empty>}'"
fi

# ── Frame extractor (wallust needs a still image; pywal/borderline don't) ────

_extract_frame(){
    local video="$1"
    local tmp
    tmp=$(mktemp /tmp/termcolors_XXXXXX.png)
    # 480×270: enough colour diversity, fast to process
    ffmpeg -i "$video" -y -vframes 1 -vf "scale=480:270" -v quiet "$tmp" 2>/dev/null \
        || { rm -f "$tmp"; _die "ffmpeg failed to extract frame from: $video"; }
    echo "$tmp"
}

# ── Backend runners ───────────────────────────────────────────────────────────

run_wallust(){
    command -v wallust &>/dev/null || _die "wallust not found. Is it installed?"

    local wal_src tmp_frame=""

    if $IS_VIDEO; then
        command -v ffmpeg &>/dev/null || \
            _die "ffmpeg is required for video support with wallust."
        tmp_frame=$(_extract_frame "$SOURCE_FILE")
        wal_src="$tmp_frame"
    else
        wal_src="$SOURCE_FILE"
    fi

    wallust run "$wal_src"
    local ret=$?
    [[ -n "$tmp_frame" ]] && rm -f "$tmp_frame"
    return $ret
}

run_pywal(){
    # pywal16 accepts video natively via -i, no frame extraction needed
    command -v wal &>/dev/null || _die "pywal16 (wal) not found. Is it installed?"
    wal --recursive -i "$SOURCE_FILE"
}

run_borderline(){
    local bscript="$L_PATH/scripts/borderline.sh"
    [[ -f "$bscript" ]] || _die "borderline.sh not found at: $bscript"
    sh "$bscript" "$SOURCE_FILE"
}

# ── Execute ───────────────────────────────────────────────────────────────────

case "$BACKEND" in
    wallust)
        run_wallust
        ;;
    pywal|pywal16)
        run_pywal
        ;;
    none|borderline)
        # No color backend — borderline-only mode (config: BACKEND=none)
        ;;
    *)
        _notify_err "Unknown BACKEND '$BACKEND' in termcolors.conf. Falling back to wallust."
        run_wallust
        ;;
esac

$RUN_BORDERLINE && run_borderline

exit 0