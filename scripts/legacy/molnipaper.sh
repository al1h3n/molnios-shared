#!/usr/bin/env bash
# molnipaper.sh - Dynamic terminal color theming for MolniOS
# Part of the MolniOS project.
# ==============================================================================
# Called by waypaper as a post_command, or directly from the terminal.
#
# USAGE
#   molnipaper.sh [FLAGS] <wallpaper> [video]
#
# FLAGS
#   -w, --wallust          Force wallust as color backend
#   -p, --pywal            Force pywal16 (wal -i) as color backend
#   -m, --matugen          Force matugen (Material You) as color backend
#                          Backends are mutually exclusive → exits with error if combined.
#   -s, --saturate <val>   Saturate wallust/pywal palette (0.0–1.0).
#                          Values above 0.5 compensate for dim transparent-terminal BGs.
#                          E.g. -s 0.7 is noticeably brighter. Not used by matugen.
#       --scheme <name>    Matugen scheme type (overrides MATUGEN_SCHEME config).
#                          Options: scheme-tonal-spot (default), scheme-vibrant,
#                                   scheme-content, scheme-fidelity, scheme-expressive,
#                                   scheme-fruit-salad, scheme-monochrome, scheme-rainbow
#       --mode <dark|light> Matugen color mode (overrides MATUGEN_MODE config).
#   -nb, --no-borderline   Skip borderline regardless of BORDERLINE config value.
#   -h, --help             Print this help and exit
#
# EXAMPLES
#   # waypaper post_command — backend resolved from BACKEND_PRIORITY in config:
#   post_command = sh ~/.local/share/molnios/scripts/molnipaper.sh $wallpaper $video
#
#   # Force wallust, skip borderline:
#   post_command = sh ~/.local/share/molnios/scripts/molnipaper.sh -w -nb $wallpaper $video
#
#   # Pywal with boosted saturation, no borderline:
#   molnipaper.sh -p -s 0.75 -nb /path/to/wall.jpg
#
#   # Matugen vibrant scheme, dark mode:
#   molnipaper.sh -m --scheme scheme-vibrant --mode dark /path/to/loop.mp4
#
# CONFIG
#   ~/.config/molnios/config/theming/molnios-colors.conf
#     BACKEND_PRIORITY=pywal16,wallust,matugen
#       First installed backend in the list is used when no CLI flag is given.
#     GENERATE_TEMPLATES=yes    # yes | no
#     RELOAD_APPS=yes           # yes | no  — reload waybar, swaync, kitty, dunst
#     BORDERLINE=yes            # yes | no
#     # Optional tuning (can be added to the conf):
#     SATURATE=0.7              # 0.0–1.0; empty = backend default
#     MATUGEN_SCHEME=scheme-tonal-spot
#     MATUGEN_MODE=dark         # dark | light
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
        notify-send -h int:transient:1 "molnipaper" "$1"
}

_notify_err(){
    command -v notify-send &>/dev/null && \
        notify-send -h int:transient:1 -u critical "molnipaper" "$1"
}

_die(){
    local msg="$1"
    echo "molnipaper: error: $msg" >&2
    _notify_err "$msg"
    exit 1
}

_usage(){
    grep '^#' "$0" | grep -v '#!/' | sed 's/^# \{0,1\}//' | \
        sed -n '/^molnipaper\.sh/,/^CONFIG/p'
    exit 0
}

# ── Parse flags ───────────────────────────────────────────────────────────────

FLAG_WALLUST=false
FLAG_PYWAL=false
FLAG_MATUGEN=false
FLAG_NO_BORDERLINE=false
BACKEND_FLAG_GIVEN=false
SATURATE_OVERRIDE=""
MATUGEN_SCHEME_OVERRIDE=""
MATUGEN_MODE_OVERRIDE=""
WALLPAPER=""
VIDEO=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -w|--wallust)
            FLAG_WALLUST=true; BACKEND_FLAG_GIVEN=true; shift ;;
        -p|--pywal|--pywal16)
            FLAG_PYWAL=true; BACKEND_FLAG_GIVEN=true; shift ;;
        -m|--matugen|--material)
            FLAG_MATUGEN=true; BACKEND_FLAG_GIVEN=true; shift ;;
        -s|--saturate)
            [[ -n "${2:-}" ]] || _die "--saturate requires a value (e.g. 0.7)"
            SATURATE_OVERRIDE="$2"; shift 2 ;;
        --scheme)
            [[ -n "${2:-}" ]] || _die "--scheme requires a name (e.g. scheme-vibrant)"
            MATUGEN_SCHEME_OVERRIDE="$2"; shift 2 ;;
        --mode)
            [[ -n "${2:-}" ]] || _die "--mode requires: dark or light"
            MATUGEN_MODE_OVERRIDE="$2"; shift 2 ;;
        -nb|--no-borderline)
            FLAG_NO_BORDERLINE=true; shift ;;
        -h|--help)
            _usage ;;
        -*)
            _die "Unknown flag '$1'. Use -h for help." ;;
        *)
            if   [[ -z "$WALLPAPER" ]]; then WALLPAPER="$1"
            elif [[ -z "$VIDEO"     ]]; then VIDEO="$1"
            else _die "Unexpected extra argument: '$1'"
            fi
            shift ;;
    esac
done

# ── Mutually exclusive backend check ─────────────────────────────────────────

_nbackends=0
if $FLAG_WALLUST; then _nbackends=$(( _nbackends + 1 )); fi
if $FLAG_PYWAL;   then _nbackends=$(( _nbackends + 1 )); fi
if $FLAG_MATUGEN; then _nbackends=$(( _nbackends + 1 )); fi
if [[ $_nbackends -gt 1 ]]; then
    _die "Backend flags (-w/-p/-m) are mutually exclusive. Pick one."
fi

# ── Resolve backend and options from config (only when no CLI backend given) ──

BACKEND="wallust"               # hard default if config absent / empty priority list
RUN_BORDERLINE=true
RELOAD_APPS_FLAG=true
GENERATE_TEMPLATES_FLAG=true    # parsed; template-skip not yet fully implemented
SATURATE=""                     # empty = each backend's own default
MATUGEN_SCHEME="scheme-tonal-spot"
MATUGEN_MODE="dark"

if ! $BACKEND_FLAG_GIVEN; then
    CONF_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/molnios/config/theming/molnios-colors.conf"
    if [[ -f "$CONF_FILE" ]]; then
        # Strip inline comments, trim whitespace/quotes from values
        _read(){
            grep -E "^[[:space:]]*${1}[[:space:]]*=" "$CONF_FILE" \
                | tail -n1 | cut -d= -f2- \
                | sed 's/[[:space:]]*#.*$//;s/^[[:space:]"'"'"']*//;s/[[:space:]"'"'"']*$//'
        }

        # ── BACKEND_PRIORITY: try each entry in order, use first installed ──
        _bp=$(_read BACKEND_PRIORITY)
        if [[ -n "$_bp" ]]; then
            BACKEND=""   # clear default; loop will set it
            IFS=',' read -ra _bp_list <<< "$_bp"
            for _b in "${_bp_list[@]}"; do
                _b="${_b//[[:space:]]/}"          # trim any spaces around commas
                [[ -z "$_b" ]] && continue
                case "$_b" in
                    pywal16|pywal)
                        if command -v wal &>/dev/null;     then BACKEND="pywal";   break; fi ;;
                    wallust)
                        if command -v wallust &>/dev/null; then BACKEND="wallust"; break; fi ;;
                    matugen)
                        if command -v matugen &>/dev/null; then BACKEND="matugen"; break; fi ;;
                    *)
                        echo "molnipaper: warning: unknown backend '$_b' in BACKEND_PRIORITY, skipping" >&2 ;;
                esac
            done
            if [[ -z "$BACKEND" ]]; then
                BACKEND="wallust"
                _notify_err "No backend from BACKEND_PRIORITY is installed. Defaulting to wallust."
            fi
        fi

        # ── Other config keys ────────────────────────────────────────────────
        _bl=$(_read BORDERLINE)
        [[ "$_bl" == "no"  || "$_bl" == "false" || "$_bl" == "0" ]] && RUN_BORDERLINE=false

        _ra=$(_read RELOAD_APPS)
        [[ "$_ra" == "no"  || "$_ra" == "false" || "$_ra" == "0" ]] && RELOAD_APPS_FLAG=false

        _gt=$(_read GENERATE_TEMPLATES)
        [[ "$_gt" == "no"  || "$_gt" == "false" || "$_gt" == "0" ]] && GENERATE_TEMPLATES_FLAG=false

        # Optional tuning keys — not required in the conf, safe to add
        _s=$(_read SATURATE);        [[ -n "$_s"  ]] && SATURATE="$_s"
        _ms=$(_read MATUGEN_SCHEME); [[ -n "$_ms" ]] && MATUGEN_SCHEME="$_ms"
        _mm=$(_read MATUGEN_MODE);   [[ -n "$_mm" ]] && MATUGEN_MODE="$_mm"
    fi
else
    # CLI backend flag given — map directly
    if $FLAG_WALLUST; then BACKEND="wallust"; fi
    if $FLAG_PYWAL;   then BACKEND="pywal";   fi
    if $FLAG_MATUGEN; then BACKEND="matugen"; fi
fi

# CLI flags always win over config
$FLAG_NO_BORDERLINE                   && RUN_BORDERLINE=false
[[ -n "$SATURATE_OVERRIDE" ]]         && SATURATE="$SATURATE_OVERRIDE"
[[ -n "$MATUGEN_SCHEME_OVERRIDE" ]]   && MATUGEN_SCHEME="$MATUGEN_SCHEME_OVERRIDE"
[[ -n "$MATUGEN_MODE_OVERRIDE" ]]     && MATUGEN_MODE="$MATUGEN_MODE_OVERRIDE"

# ── Validate source file ──────────────────────────────────────────────────────

if [[ -n "$VIDEO" && -f "$VIDEO" ]]; then
    SOURCE_FILE="$VIDEO"
    IS_VIDEO=true
elif [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]]; then
    SOURCE_FILE="$WALLPAPER"
    if command -v file &>/dev/null && \
       file --mime-type -b "$SOURCE_FILE" 2>/dev/null | grep -q "^video/"; then
        IS_VIDEO=true
    else
        IS_VIDEO=false
    fi
else
    _die "No valid file found.\n  wallpaper='${WALLPAPER:-<empty>}'\n  video='${VIDEO:-<empty>}'"
fi

# ── Frame extractor (wallust/matugen need a still image; pywal doesn't) ──────

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

_broadcast_sequences(){
    local seq_file="$1"
    [[ -f "$seq_file" ]] || return 0
    local pts_dir="/dev/pts"
    [[ -d "$pts_dir" ]] || return 0
    for pts in "$pts_dir"/[0-9]*; do
        [[ -w "$pts" ]] || continue
        [[ "$(stat -c '%u' "$pts" 2>/dev/null)" == "$(id -u)" ]] || continue
        cat "$seq_file" > "$pts" 2>/dev/null || true
    done
}

_save_state(){
    local seq_file="$1"
    local state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/molnios"
    mkdir -p "$state_dir"
    echo "$seq_file" > "$state_dir/colors"
}

# Reload running applications so they pick up new colors from templates.
# Called when RELOAD_APPS=yes (default). Each reload is fire-and-forget;
# missing processes are silently skipped.
_reload_apps(){
    # Waybar: SIGUSR2 → full style + config reload
    pgrep -x waybar  &>/dev/null && killall -SIGUSR2 waybar  2>/dev/null || true
    # Swaync: reload notification-center CSS
    command -v swaync-client &>/dev/null && \
        swaync-client --reload-css 2>/dev/null || true
    # Kitty: SIGUSR1 → reload config
    pgrep -x kitty   &>/dev/null && killall -SIGUSR1 kitty   2>/dev/null || true
    # Dunst: SIGHUP → reload config
    pgrep -x dunst   &>/dev/null && killall -SIGHUP  dunst   2>/dev/null || true
}

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

    local sat_args=()
    [[ -n "$SATURATE" ]] && sat_args=(--saturate "$SATURATE")

    wallust run "${sat_args[@]}" "$wal_src"
    local ret=$?
    [[ -n "$tmp_frame" ]] && rm -f "$tmp_frame"

    _broadcast_sequences "${XDG_CACHE_HOME:-$HOME/.cache}/wallust/sequences"
    _save_state "${XDG_CACHE_HOME:-$HOME/.cache}/wallust/sequences"

    return $ret
}

# pywal16 accepts videos natively.
run_pywal(){
    command -v wal &>/dev/null || _die "pywal16 (wal) not found. Is it installed?"

    local sat_args=()
    [[ -n "$SATURATE" ]] && sat_args=(--saturate "$SATURATE")

    wal --recursive -i "$SOURCE_FILE" "${sat_args[@]}"

    _broadcast_sequences "${XDG_CACHE_HOME:-$HOME/.cache}/wal/sequences"
    _save_state "${XDG_CACHE_HOME:-$HOME/.cache}/wal/sequences"
}

# matugen applies colors system-wide via its template system.
# For terminal recoloring add a sequences template to ~/.config/matugen/config.toml:
#
#   [config.custom_templates]
#   sequences = { input_path = "~/.config/matugen/templates/sequences",
#                 output_path = "~/.cache/matugen/sequences" }
#
# The template should emit OSC escape codes (same format as pywal's sequences file).
# Use scheme-vibrant for the most saturated output on dark / transparent terminals.
run_matugen(){
    command -v matugen &>/dev/null || _die "matugen not found. Is it installed?"

    local wal_src tmp_frame=""

    if $IS_VIDEO; then
        command -v ffmpeg &>/dev/null || \
            _die "ffmpeg is required for video support with matugen."
        tmp_frame=$(_extract_frame "$SOURCE_FILE")
        wal_src="$tmp_frame"
    else
        wal_src="$SOURCE_FILE"
    fi

    # --type and --mode are global matugen options (before the subcommand)
    matugen --type "${MATUGEN_SCHEME:-scheme-tonal-spot}" \
            --mode "${MATUGEN_MODE:-dark}" \
            image "$wal_src"
    local ret=$?
    [[ -n "$tmp_frame" ]] && rm -f "$tmp_frame"

    # Broadcast terminal sequences if a sequences template is configured
    local seq="${XDG_CACHE_HOME:-$HOME/.cache}/matugen/sequences"
    if [[ -f "$seq" ]]; then
        _broadcast_sequences "$seq"
        _save_state "$seq"
    else
        # Fallback: a pywal-compat template may write to the wal path instead
        local wal_seq="${XDG_CACHE_HOME:-$HOME/.cache}/wal/sequences"
        if [[ -f "$wal_seq" ]]; then
            _broadcast_sequences "$wal_seq"
            _save_state "$wal_seq"
        fi
    fi

    return $ret
}

run_borderline(){
    local bscript="$L_PATH/scripts/colors/borderline.sh"
    [[ -f "$bscript" ]] || _die "borderline.sh not found at: $bscript"
    sh "$bscript" "$SOURCE_FILE"
}

# ── Execute ───────────────────────────────────────────────────────────────────

case "$BACKEND" in
    wallust)
        run_wallust ;;
    pywal|pywal16)
        run_pywal ;;
    matugen|material)
        run_matugen ;;
    none|borderline)
        # No color backend — borderline-only or dry-run mode
        ;;
    *)
        _notify_err "Unknown BACKEND '$BACKEND' in molnios-colors.conf. Falling back to wallust."
        run_wallust ;;
esac

$RUN_BORDERLINE && run_borderline

# Reload apps unless RELOAD_APPS=no or GENERATE_TEMPLATES=no (nothing to reload)
if $RELOAD_APPS_FLAG && $GENERATE_TEMPLATES_FLAG; then
    _reload_apps
fi

exit 0