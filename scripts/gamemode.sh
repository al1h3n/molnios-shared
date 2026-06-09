#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/gamemode"
STATE_FILE="$STATE_DIR/enabled"

mkdir -p "$STATE_DIR"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Gamemode" "$1"
    fi
}

detect_compositor() {
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        echo hyprland
    elif [[ -n "${NIRI_SOCKET:-}" ]]; then
        echo niri
    else
        echo unknown
    fi
}

hypr_enable() {
    hyprctl eval '
        hl.config({
            general = {
                gaps_in = 0,
                gaps_out = 0,
                border_size = 0,
            },

            animations = {
                enabled = false,
            },

            decoration = {
                shadow = {
                    enabled = false,
                },
                blur = {
                    enabled = false,
                },
                rounding = 0,
            },
        })
    '

    # Set every monitor to scale 1
    hyprctl monitors -j |
        jq -r '.[].name' |
        while read -r mon; do
            hyprctl keyword monitor "$mon,preferred,auto,1"
        done
    hyprctl notify 1 3000 "rgb(40a02b)" " Gamemode [ON]"
}

hypr_disable() {
    hyprctl reload
    hyprctl notify 1 3000 "rgb(d20f39)" " Gamemode [OFF]"
}

niri_enable() {
    ln -sf $L_PATH/config/niri/modules/gamemode/on.kdl ~/.config/niri/modules/gamemode.kdl

    niri msg action reload-config

    niri msg --json outputs |
        jq -r '.[].name' |
        while read -r output; do
            niri msg output "$output" scale 1
        done

    notify "Enabled (Niri)"
}

niri_disable() {
    ln -sf $L_PATH/config/niri/modules/gamemode/off.kdl ~/.config/niri/modules/gamemode.kdl
    niri msg action reload-config

    notify "Disabled (Niri)"
}

enable_mode() {
    compositor="$(detect_compositor)"

    case "$compositor" in
        hyprland) hypr_enable ;;
        niri)     niri_enable ;;
        *)        echo "Unsupported compositor"; exit 1 ;;
    esac

    touch "$STATE_FILE"
}

disable_mode() {
    compositor="$(detect_compositor)"

    case "$compositor" in
        hyprland) hypr_disable ;;
        niri)     niri_disable ;;
        *)        echo "Unsupported compositor"; exit 1 ;;
    esac

    rm -f "$STATE_FILE"
}

case "${1:-toggle}" in
    enable)
        enable_mode
        ;;
    disable)
        disable_mode
        ;;
    toggle)
        if [[ -f "$STATE_FILE" ]]; then
            disable_mode
        else
            enable_mode
        fi
        ;;
esac