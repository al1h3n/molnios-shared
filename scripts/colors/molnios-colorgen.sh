#!/usr/bin/env bash
# molnios-colorgen.sh - Universal color system for MolniOS
# Part of the MolniOS project.
# ==============================================================================
# Unified color generation with configurable backend priority.
# Supports: pywal16, wallust, matugen with automatic fallback.
# Generates templates for all applications from a single color source.
#
# USAGE
#   molnios-colorgen.sh [FLAGS] <wallpaper> [video]
#
# FLAGS
#   -b, --backend <name>   Force specific backend (pywal16|wallust|matugen)
#   -nb, --no-borderline   Skip borderline extraction
#   -nt, --no-templates    Skip template generation
#   -nr, --no-reload       Skip application reload
#   -h, --help             Print this help and exit
#
# EXAMPLES
#   molnios-colorgen.sh /path/to/wallpaper.jpg
#   molnios-colorgen.sh -b pywal16 /path/to/video.mp4
#   molnios-colorgen.sh -nt -nr /path/to/image.png
#
# CONFIG
#   $L_PATH/config/theming/molnios-colors.conf
#     BACKEND_PRIORITY=pywal16,wallust,matugen
#     GENERATE_TEMPLATES=yes
#     RELOAD_APPS=yes
#     BORDERLINE=yes
# ==============================================================================

set -euo pipefail

# ── Resolve paths ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
L_PATH="$(dirname "$SCRIPT_DIR")"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
STATE_DIR="$CACHE_DIR/molnios"
COLORS_CACHE="$STATE_DIR/colors"

# ── Load environment ──────────────────────────────────────────────────────────

if [ -f /etc/profiles/per-user/"$(whoami)"/etc/profile.d/hm-session-vars.sh ];then
    . /etc/profiles/per-user/"$(whoami)"/etc/profile.d/hm-session-vars.sh
fi
[ -f ~/.nix-profile/etc/profile.d/nix.sh ] && . ~/.nix-profile/etc/profile.d/nix.sh
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# ── Notification helpers ──────────────────────────────────────────────────────

_notify(){
    command -v notify-send &>/dev/null && \
        notify-send -h int:transient:1 "MolniOS Colors" "$1"
}

_notify_err(){
    command -v notify-send &>/dev/null && \
        notify-send -h int:transient:1 -u critical "MolniOS Colors" "$1"
}

_die(){
    local msg="$1"
    echo "molnios-colorgen: error: $msg" >&2
    _notify_err "$msg"
    exit 1
}

_usage(){
    grep '^#' "$0" | grep -v '#!/' | sed 's/^# \{0,1\}//' | \
        sed -n '/^molnios-colorgen\.sh/,/^CONFIG/p'
    exit 0
}

# ── Parse flags ───────────────────────────────────────────────────────────────

FLAG_BACKEND=""
FLAG_NO_BORDERLINE=false
FLAG_NO_TEMPLATES=false
FLAG_NO_RELOAD=false
WALLPAPER=""
VIDEO=""

while [[ $# -gt 0 ]];do
    case "$1" in
        -b|--backend)
            [[ -z "${2:-}" ]] && _die "--backend requires an argument"
            FLAG_BACKEND="$2"
            shift 2
            ;;
        -nb|--no-borderline)
            FLAG_NO_BORDERLINE=true
            shift
            ;;
        -nt|--no-templates)
            FLAG_NO_TEMPLATES=true
            shift
            ;;
        -nr|--no-reload)
            FLAG_NO_RELOAD=true
            shift
            ;;
        -h|--help)
            _usage
            ;;
        -*)
            _die "Unknown flag '$1'. Use -h for help."
            ;;
        *)
            if [[ -z "$WALLPAPER" ]];then
                WALLPAPER="$1"
            elif [[ -z "$VIDEO" ]];then
                VIDEO="$1"
            else
                _die "Unexpected extra argument: '$1'"
            fi
            shift
            ;;
    esac
done

# ── Load configuration ────────────────────────────────────────────────────────

BACKEND_PRIORITY="pywal16,wallust,matugen"
GENERATE_TEMPLATES=true
RELOAD_APPS=true
RUN_BORDERLINE=true

CONF_FILE=$L_PATH/config/theming/molnios-colors.conf
if [[ -f "$CONF_FILE" ]];then
    _read(){ grep -E "^[[:space:]]*${1}[[:space:]]*=" "$CONF_FILE" \
             | tail -n1 | cut -d= -f2- \
             | sed "s/^[[:space:]\"']*//;s/[[:space:]\"']*$//"; }

    _bp=$(_read BACKEND_PRIORITY); [[ -n "$_bp" ]] && BACKEND_PRIORITY="$_bp"
    _gt=$(_read GENERATE_TEMPLATES)
    [[ "$_gt" == "no" || "$_gt" == "false" || "$_gt" == "0" ]] && GENERATE_TEMPLATES=false
    _ra=$(_read RELOAD_APPS)
    [[ "$_ra" == "no" || "$_ra" == "false" || "$_ra" == "0" ]] && RELOAD_APPS=false
    _bl=$(_read BORDERLINE)
    [[ "$_bl" == "no" || "$_bl" == "false" || "$_bl" == "0" ]] && RUN_BORDERLINE=false
fi

# CLI flags override config
$FLAG_NO_BORDERLINE && RUN_BORDERLINE=false
$FLAG_NO_TEMPLATES && GENERATE_TEMPLATES=false
$FLAG_NO_RELOAD && RELOAD_APPS=false

# ── Validate source file ──────────────────────────────────────────────────────

if [[ -n "$VIDEO" && -f "$VIDEO" ]];then
    SOURCE_FILE="$VIDEO"
    IS_VIDEO=true
elif [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]];then
    SOURCE_FILE="$WALLPAPER"
    if command -v file &>/dev/null && \
       file --mime-type -b "$SOURCE_FILE" 2>/dev/null | grep -q "^video/";then
        IS_VIDEO=true
    else
        IS_VIDEO=false
    fi
else
    _die "No valid file found.\n  wallpaper='${WALLPAPER:-<empty>}'\n  video='${VIDEO:-<empty>}'"
fi

# ── Frame extraction helper ───────────────────────────────────────────────────

_extract_frame(){
    local video="$1"
    local tmp
    tmp=$(mktemp /tmp/colorgen_XXXXXX.png)
    ffmpeg -i "$video" -y -vframes 1 -vf "scale=480:270" -v quiet "$tmp" 2>/dev/null \
        || { rm -f "$tmp"; _die "ffmpeg failed to extract frame from: $video"; }
    echo "$tmp"
}

# ── Backend detection ─────────────────────────────────────────────────────────

_backend_available(){
    case "$1" in
        pywal16) command -v wal &>/dev/null ;;
        wallust) command -v wallust &>/dev/null ;;
        matugen) command -v matugen &>/dev/null ;;
        *) return 1 ;;
    esac
}

_select_backend(){
    if [[ -n "$FLAG_BACKEND" ]];then
        if _backend_available "$FLAG_BACKEND";then
            echo "$FLAG_BACKEND"
            return 0
        else
            _die "Requested backend '$FLAG_BACKEND' not available"
        fi
    fi

    IFS=',' read -ra backends <<< "$BACKEND_PRIORITY"
    for backend in "${backends[@]}";do
        backend=$(echo "$backend" | xargs)
        if _backend_available "$backend";then
            echo "$backend"
            return 0
        fi
    done

    _die "No color backend available. Install pywal16, wallust, or matugen."
}

BACKEND=$(_select_backend)

# ── Backend runners ───────────────────────────────────────────────────────────

_broadcast_sequences(){
    local seq_file="$1"
    [[ -f "$seq_file" ]] || return 0
    local pts_dir="/dev/pts"
    [[ -d "$pts_dir" ]] || return 0
    for pts in "$pts_dir"/[0-9]*;do
        [[ -w "$pts" ]] || continue
        [[ "$(stat -c '%u' "$pts" 2>/dev/null)" == "$(id -u)" ]] || continue
        cat "$seq_file" > "$pts" 2>/dev/null || true
    done
}

_save_state(){
    local seq_file="$1"
    mkdir -p "$STATE_DIR"
    echo "$seq_file" > "$COLORS_CACHE"
}

run_pywal16(){
    _notify "Generating colors with pywal16..."
    wal --recursive -i "$SOURCE_FILE" -q

    _broadcast_sequences "$CACHE_DIR/wal/sequences"
    _save_state "$CACHE_DIR/wal/sequences"
}

run_wallust(){
    local wal_src tmp_frame=""

    if $IS_VIDEO;then
        command -v ffmpeg &>/dev/null || \
            _die "ffmpeg is required for video support with wallust."
        _notify "Extracting frame for wallust..."
        tmp_frame=$(_extract_frame "$SOURCE_FILE")
        wal_src="$tmp_frame"
    else
        wal_src="$SOURCE_FILE"
    fi

    _notify "Generating colors with wallust..."
    wallust run "$wal_src" -q $L_PATH/config/theming/wallust.toml
    local ret=$?
    [[ -n "$tmp_frame" ]] && rm -f "$tmp_frame"

    _broadcast_sequences "$CACHE_DIR/wallust/sequences"
    _save_state "$CACHE_DIR/wallust/sequences"

    return $ret
}

run_matugen(){
    local wal_src tmp_frame=""

    if $IS_VIDEO;then
        command -v ffmpeg &>/dev/null || \
            _die "ffmpeg is required for video support with matugen."
        _notify "Extracting frame for matugen..."
        tmp_frame=$(_extract_frame "$SOURCE_FILE")
        wal_src="$tmp_frame"
    else
        wal_src="$SOURCE_FILE"
    fi

    _notify "Generating colors with matugen..."
    matugen image "$wal_src" -q -c $L_PATH/config/theming/matugen.toml
    local ret=$?
    [[ -n "$tmp_frame" ]] && rm -f "$tmp_frame"

    # Matugen generates to ~/.cache/wal/ via template
    if [[ -f "$CACHE_DIR/wal/sequences" ]];then
        _broadcast_sequences "$CACHE_DIR/wal/sequences"
        _save_state "$CACHE_DIR/wal/sequences"
    fi

    return $ret
}

# ── Template generation ───────────────────────────────────────────────────────

generate_templates(){
    local template_script="$L_PATH/scripts/colors/molnios-templates.sh"
    if [[ -f "$template_script" ]];then
        _notify "Generating application templates..."
        bash "$template_script" || _notify_err "Template generation failed"
    else
        _notify_err "Template script not found: $template_script"
    fi
}

# ── Application reload ────────────────────────────────────────────────────────

reload_applications(){
    _notify "Reloading applications..."

    # Waybar
    if command -v killall &>/dev/null && pgrep -x waybar &>/dev/null;then
        killall -SIGUSR2 waybar 2>/dev/null || true
    fi

    # Dunst
    if command -v dunstctl &>/dev/null && pgrep -x dunst &>/dev/null;then
        dunstctl reload 2>/dev/null || true
    fi

    # SwayNC
    if pgrep -x swaync &>/dev/null;then
        pkill -SIGUSR2 swaync 2>/dev/null || true
    fi

    # Kitty
    if pgrep -x kitty &>/dev/null;then
        killall -SIGUSR1 kitty 2>/dev/null || true
    fi

    # Rofi (no reload needed - reads on launch)
    # Hyprland borders (handled by borderline)
    # GTK (no reload needed - reads on app launch)
}

# ── Borderline runner ─────────────────────────────────────────────────────────

run_borderline(){
    local bscript="$L_PATH/scripts/colors/borderline.sh"
    [[ -f "$bscript" ]] || {
        _notify_err "borderline.sh not found at: $bscript"
        return 1
    }
    bash "$bscript" "$SOURCE_FILE"
}

# ── Execute ───────────────────────────────────────────────────────────────────

case "$BACKEND" in
    pywal16)
        run_pywal16
        ;;
    wallust)
        run_wallust
        ;;
    matugen)
        run_matugen
        ;;
    *)
        _die "Unknown backend: $BACKEND"
        ;;
esac

$GENERATE_TEMPLATES && generate_templates
$RUN_BORDERLINE && run_borderline
$RELOAD_APPS && reload_applications

_notify "Color system applied with $BACKEND"
exit 0
