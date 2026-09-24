#!/usr/bin/env bash
# noctalia-live-colors - pushes Noctalia's generated Kitty theme into every
# running Kitty window as soon as it changes, so terminal colors follow the
# wallpaper/accent live instead of only after a manual reload/restart.
#
# Noctalia rewrites ~/.config/kitty/themes/noctalia.conf via an atomic
# replace (write temp file, rename over the target). A watch on that single
# file's inode would silently stop seeing changes after the first rename, so
# this watches the parent *directory* and reacts to the filename instead.
#
# Requires kitty.conf to have `allow_remote_control yes` and
# `listen_on unix:${XDG_RUNTIME_DIR}/kitty-borderline-{kitty_pid}` (see
# molnios-shared/config/kitty/kitty.conf) - that's what creates the sockets
# this script pushes colors through.
# Part of the MolniOS project.
# ==============================================================================

set -uo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/themes"
THEME_FILE="$THEME_DIR/noctalia.conf"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

for cmd in inotifywait kitty; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "noctalia-live-colors: missing dependency: $cmd" >&2
        exit 1
    fi
done

mkdir -p "$THEME_DIR"

push(){
    [ -f "$THEME_FILE" ] || return 0
    shopt -s nullglob
    local sockets=("$RUNTIME_DIR"/kitty-borderline-*)
    shopt -u nullglob
    local socket
    for socket in "${sockets[@]}"; do
        [ -S "$socket" ] || continue
        kitty @ --to "unix:$socket" set-colors -a "$THEME_FILE" &>/dev/null
    done
}

# Apply once at startup in case the theme changed while this service was down
# (e.g. wallpaper switched before login).
push

inotifywait -m -q -e close_write -e moved_to --format '%f' "$THEME_DIR" |
while read -r changed; do
    [ "$changed" = "noctalia.conf" ] && push
done
