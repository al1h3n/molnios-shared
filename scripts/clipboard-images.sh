#!/usr/bin/env bash
# Rofi clipboard picker with image preview support
set -o pipefail

if [[ -n ${NIRI_SOCKET:-} ]]; then
    target=$(niri msg -j focused-window 2>/dev/null | jq -r '.id // empty')
elif [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    target=$(hyprctl -j activewindow 2>/dev/null | jq -r '.address // empty')
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

selection=$(cliphist list | while IFS=$'\t' read -r id rest; do
    if [[ "$rest" == "[[ binary data"* ]]; then
        img="$tmp_dir/$id.png"
        cliphist decode <<< "$id	$rest" > "$img" 2>/dev/null
        printf '%s\t%s\0icon\x1f%s\n' "$id" "$rest" "$img"
    else
        printf '%s\t%s\n' "$id" "$rest"
    fi
done | rofi -dmenu -display-columns 2 -show-icons) || exit 0
[[ -n $selection ]] || exit 0
cliphist decode <<< "$selection" | wl-copy || exit 1

if [[ -n ${NIRI_SOCKET:-} && -n $target ]]; then
    current=$(niri msg -j focused-window 2>/dev/null | jq -r '.id // empty')
    if [[ $current != "$target" ]]; then
        niri msg action focus-window --id "$target" || exit 0
        sleep 0.1
    fi
elif [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} && -n $target ]]; then
    current=$(hyprctl -j activewindow 2>/dev/null | jq -r '.address // empty')
    if [[ $current != "$target" ]]; then
        hyprctl dispatch focuswindow "address:$target" || exit 0
        sleep 0.1
    fi
fi
sleep 0.1
wtype -M ctrl -k v -m ctrl
