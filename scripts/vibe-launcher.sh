#!/usr/bin/env bash
# Open a terminal in a directory and run a command there (claude, opencode, ...).
#
#   launcher.sh                          # pick everything interactively
#   launcher.sh ~/src/app                # pick the rest interactively
#   launcher.sh -d ~/src/app -a opencode -t kitty
#
# Settings come from launcher.conf next to this script; flags override them.
set -euo pipefail

CONF=$L_PATH/config/vibe-launcher.conf

TERMINALS="wezterm kitty ghostty alacritty xterm macterm powershell cmd custom"
APPS="claude opencode"

die() { printf 'launcher: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
    cat <<EOF
Usage: launcher.sh [DIR] [flags]

Opens a terminal in DIR and runs a command there. Anything not supplied is
asked for interactively (gum, else fzf, else a plain prompt).

  -d, --dir PATH        Directory to open. Same as the positional DIR.
  -a, --app CMD         Command to run in it. Default: claude. Any command
                        works: "opencode", "nvim .", "claude --resume".
  -t, --terminal NAME   auto | ask | $TERMINALS
                        auto walks the precedence list, ask prompts.
  -c, --custom-cmd TPL  Terminal command template; implies --terminal custom.
                        Tokens: @DIR@ (directory), @CMD@ (the command).
  -s, --start-dir PATH  Where the directory picker starts browsing.
      --dry-run         Print what would be launched, launch nothing.
  -h, --help            This text.
EOF
}

# --- flags ------------------------------------------------------------------

ARG_DIR=""; ARG_APP=""; ARG_TERM=""; ARG_CUSTOM=""; ARG_START=""; DRY_RUN=0
while [ $# -gt 0 ]; do
    case "$1" in
        --*=*)           set -- "${1%%=*}" "${1#*=}" "${@:2}"; continue ;;
        -d|--dir)        [ $# -ge 2 ] || die "$1 needs a value"; ARG_DIR="$2";    shift 2 ;;
        -a|--app)        [ $# -ge 2 ] || die "$1 needs a value"; ARG_APP="$2";    shift 2 ;;
        -t|--terminal)   [ $# -ge 2 ] || die "$1 needs a value"; ARG_TERM="$2";   shift 2 ;;
        -s|--start-dir)  [ $# -ge 2 ] || die "$1 needs a value"; ARG_START="$2";  shift 2 ;;
        -c|--custom-cmd) [ $# -ge 2 ] || die "$1 needs a value"; ARG_CUSTOM="$2"
                         ARG_TERM=custom; shift 2 ;;
        --dry-run)       DRY_RUN=1; shift ;;
        -h|--help)       usage; exit 0 ;;
        --)              shift; [ $# -gt 0 ] || break
                         [ -z "$ARG_DIR" ] || die "unexpected argument: $1"
                         ARG_DIR="$1"; shift ;;
        -?*)             die "unknown flag: $1 (try --help)" ;;
        *)               [ -z "$ARG_DIR" ] || die "unexpected argument: $1"
                         ARG_DIR="$1"; shift ;;
    esac
done

# --- config -----------------------------------------------------------------

TERMINAL=auto; CUSTOM_CMD=""; START_DIR=""; APP=""
if [ -f "$CONF" ]; then
    # The case below is the filter: comment lines key off as "#   NAME" and so
    # never match. Values keep any "=" they contain; a trailing CR is dropped
    # so a config saved with Windows line endings still parses.
    while IFS='=' read -r key val || [ -n "$key" ]; do
        val="${val%$'\r'}"
        case "$key" in
            TERMINAL)   TERMINAL="$val" ;;
            CUSTOM_CMD) CUSTOM_CMD="$val" ;;
            START_DIR)  START_DIR="$val" ;;
            APP)        APP="$val" ;;
        esac
    done < "$CONF"
fi
[ -n "$ARG_TERM" ]   && TERMINAL="$ARG_TERM"
[ -n "$ARG_CUSTOM" ] && CUSTOM_CMD="$ARG_CUSTOM"
[ -n "$ARG_START" ]  && START_DIR="$ARG_START"
[ -n "$ARG_APP" ]    && APP="$ARG_APP"
[ -n "$START_DIR" ]  || START_DIR="$HOME"

# --- pickers ----------------------------------------------------------------

# Prints the chosen line, or nothing when the user cancels. gum and fzf both
# exit non-zero on cancel, which under "set -e" would kill the script from
# inside a command substitution, so every branch swallows that status and lets
# the caller decide what an empty answer means.
choose() {
    local header="$1"; shift
    if have gum; then
        printf '%s\n' "$@" | gum choose --header="$header" || true
    elif have fzf; then
        printf '%s\n' "$@" | fzf --prompt="$header> " || true
    else
        local reply=""
        read -rp "$header ($*): " reply || true
        printf '%s' "$reply"
    fi
}

pick_dir() {
    local start="$START_DIR" sel=""
    [ -d "$start" ] || start="$PWD"
    if have gum; then
        sel="$(gum file "$start" --directory --header=Directory || true)"
    elif have fzf; then
        sel="$(find "$start" -maxdepth 6 -type d 2>/dev/null | fzf --prompt='Directory> ' || true)"
    else
        read -rp 'Directory: ' sel || true
    fi
    # gum's --directory allows picking directories but does not forbid files,
    # so a file can come back; fall back to the directory holding it. dirname
    # splits on "/" only, so backslash paths (gum.exe under git-bash) are
    # trimmed by hand, keeping "C:\" rather than a bare "C:".
    if [ -n "$sel" ] && [ ! -d "$sel" ]; then
        case "$sel" in
            *\\*) sel="${sel%\\*}"; case "$sel" in *:) sel="$sel\\" ;; esac ;;
            *)    sel="$(dirname "$sel")" ;;
        esac
    fi
    printf '%s' "$sel"
}

detect_terminal() {
    local t
    for t in wezterm kitty ghostty alacritty; do
        have "$t" && { printf '%s' "$t"; return 0; }
    done
    if [ "$(uname -s)" = Darwin ]; then printf 'macterm'
    elif have xterm;   then printf 'xterm'
    elif have cmd.exe; then printf 'cmd'
    else printf 'none'
    fi
}

# --- resolve ----------------------------------------------------------------

DIR="$ARG_DIR"
[ -n "$DIR" ] || DIR="$(pick_dir)"
[ -n "$DIR" ] || die "no directory chosen"
[ -d "$DIR" ] || die "not a directory: $DIR"
DIR="$(cd "$DIR" && pwd)"

# APPS and TERMINALS are deliberately word-split into separate options.
# shellcheck disable=SC2086
[ -n "$APP" ] || APP="$(choose Command $APPS)"
[ -n "$APP" ] || die "no command chosen"

if [ "$TERMINAL" = ask ]; then
    # shellcheck disable=SC2086
    TERMINAL="$(choose Terminal $TERMINALS)"
    [ -n "$TERMINAL" ] || die "no terminal chosen"
fi
[ "$TERMINAL" = auto ] && TERMINAL="$(detect_terminal)"

# --- launch -----------------------------------------------------------------

# Native path for the terminals that are Windows programs: under git-bash $DIR
# is a /c/... path they cannot open. On Linux and macOS cygpath is absent and
# this is the identity.
win_path() { if have cygpath; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
DIR_NATIVE="$(win_path "$DIR")"
SHELL_BIN="${SHELL:-/bin/bash}"
INNER_CMD="cd $(printf '%q' "$DIR") && $APP"

if [ "$DRY_RUN" = 1 ]; then
    printf 'terminal : %s\ndir      : %s\ncommand  : %s\ninner    : %s\n' \
        "$TERMINAL" "$DIR" "$APP" "$INNER_CMD"
    exit 0
fi

# Detached on purpose. Run in the foreground and the terminal becomes a child
# of the shell that started the launcher: that shell stays blocked for the
# whole session, and closing it takes the terminal and whatever is running
# inside it down too.
spawn() { nohup "$@" >/dev/null 2>&1 & disown; }

case "$TERMINAL" in
    wezterm)   spawn wezterm-gui start --cwd "$DIR_NATIVE" -- "$SHELL_BIN" -lc "$INNER_CMD" ;;
    kitty)     spawn kitty --directory "$DIR" "$SHELL_BIN" -lc "$INNER_CMD" ;;
    ghostty)   spawn ghostty --working-directory="$DIR" -e "$SHELL_BIN" -lc "$INNER_CMD" ;;
    alacritty) spawn alacritty --working-directory "$DIR" -e "$SHELL_BIN" -lc "$INNER_CMD" ;;
    xterm)     spawn xterm -e "$SHELL_BIN" -lc "$INNER_CMD" ;;
    macterm)
        # Goes inside an AppleScript string literal, so backslashes and double
        # quotes have to be escaped first.
        ESCAPED="$(printf '%s' "$INNER_CMD" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
        osascript -e "tell application \"Terminal\" to do script \"$ESCAPED\"" ;;
    powershell)
        # PowerShell, not bash: no "&&", and it needs the native path.
        PS_DIR="$(printf '%s' "$DIR_NATIVE" | sed "s/'/''/g")"
        cmd //c start "" powershell -NoExit -Command "Set-Location -LiteralPath '$PS_DIR'; $APP" ;;
    cmd)
        # "//" keeps git-bash from rewriting /c and /k into drive paths.
        cmd //c start "" cmd //k "cd /d \"$DIR_NATIVE\" && $APP" ;;
    custom)
        [ -n "$CUSTOM_CMD" ] || die "terminal is custom but no CUSTOM_CMD or --custom-cmd"
        LINE="${CUSTOM_CMD//@DIR@/$DIR}"
        LINE="${LINE//@CMD@/$INNER_CMD}"
        # The template is your own line of shell, so it is run as shell. Prefer
        # $LAUNCH_DIR / $LAUNCH_CMD over @DIR@ / @CMD@ when a path may contain
        # characters the shell treats specially.
        LAUNCH_DIR="$DIR" LAUNCH_CMD="$APP" eval "$LINE" ;;
    none|*)
        printf 'launcher: no supported terminal found, running here\n' >&2
        eval "$INNER_CMD" ;;
esac
