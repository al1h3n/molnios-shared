#!/usr/bin/env bash
set -euo pipefail

root=$(dirname "$(dirname "$(dirname "$(readlink -f "$0")")")")
source "$root/scripts/menu/molnios-menu.sh"
source "$root/scripts/menu/custom/modules/niri.sh"
source "$root/scripts/menu/custom/modules/hyprland.sh"
L_PATH=$root

tmp=$(mktemp -d)
trap 'rm -rf "$tmp" "$STATE_DIR"' EXIT
cp -R "$root/config/niri" "$tmp/niri"
NIRI_CONFIG_PATH="$tmp/niri/niri.kdl"
notify() { :; }
notify_error() { return 1; }
niri() {
    if [[ "$*" == 'msg --json outputs' ]];then
        printf '%s\n' '{"DP-1":{"name":"DP-1","modes":[{"width":1920,"height":1080,"refresh_rate":60000}],"current_mode":0,"logical":{"scale":1.25}}}'
    else
        command niri "$@"
    fi
}

show_input() { :; }
[[ $(show_setting_input "Gaps" "Pixels" 30 8) == 8 ]]
show_input() { return 1; }
if show_setting_input "Gaps" "Pixels" 30 8 >/dev/null; then exit 1; fi

# Simulate gum inside a launched terminal: blank submission and Cancel differ.
_menu_term_cmd() { printf 'env\n'; }
gum() { :; }
export -f gum
[[ -z $(shell_show_input "Gaps" "Pixels" 30) ]]
gum() { return 1; }
export -f gum
if shell_show_input "Gaps" "Pixels" 30 >/dev/null; then exit 1; fi

show_input() { :; }
_niri_set_border_width 40
niri_adjust_border_width
rg -q '^[[:space:]]*off$' "$tmp/niri/modules/layout.kdl"
niri_adjust_gaps
rg -q '^[[:space:]]*gaps 8' "$tmp/niri/modules/layout.kdl"
niri_adjust_focus_ring_width
rg -q '^[[:space:]]*width 2$' "$tmp/niri/modules/layout.kdl"
niri_blur_saturation
rg -q '^[[:space:]]*saturation 1.4$' "$tmp/niri/modules/visual.kdl"
niri_blur_noise
rg -q '^[[:space:]]*noise 0.02$' "$tmp/niri/modules/visual.kdl"
[[ $(_niri_default_scale DP-1) == 1.25 ]]
niri_set_scale
rg -q '^[[:space:]]*scale 1.25$' "$tmp/niri/modules/monitors.kdl"
_niri_set_output_val DP-1 mode '"1920x1080@60.000"'
show_menu() { printf '0\n'; }
niri_set_resolution
if rg -q '^[[:space:]]*mode ' "$tmp/niri/modules/monitors.kdl"; then exit 1; fi
niri validate -c "$NIRI_CONFIG_PATH" >/dev/null

hypr_get_setting() { printf '99\n'; }
hypr_set_setting() { [[ "$*" == *'rounding = 17'* ]]; }
hypr_adjust_rounding
hypr_select_monitor() { printf 'DP-1\n'; }
hypr_get_monitor_scale() { printf '2\n'; }
hyprctl() { [[ "$*" == reload ]]; }
hypr_set_scale
show_input() { return 1; }
hypr_set_setting() { return 99; }
if hypr_adjust_rounding; then exit 1; fi

printf 'menu defaults: OK\n'
