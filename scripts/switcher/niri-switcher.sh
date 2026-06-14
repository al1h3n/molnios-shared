#!/bin/sh
# Niri window switcher via rofi using niri IPC
WINDOWS=$(niri msg --json windows 2>/dev/null) || exit 1

CHOICE=$(echo "$WINDOWS" \
    | jq -r '.[] | "\(.id)\t\(.app_id // "unknown") — \(.title // "untitled")"' \
    | rofi -dmenu -i -p "󰓩 Switch" -format 's')

[ -z "$CHOICE" ] && exit 0
niri msg action focus-window --id "$(echo "$CHOICE" | cut -f1)"