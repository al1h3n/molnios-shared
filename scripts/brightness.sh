#!/usr/bin/env bash

# Exit immediately if a command fails
set -euo pipefail

show_help() {
    echo "Usage: $0 [options] <value>"
    echo "Examples:"
    echo "  $0 +10%          # Increase active monitor brightness by 10%"
    echo "  $0 -10%          # Decrease active monitor brightness by 10%"
    echo "  $0 50%           # Set active monitor brightness straight to 50%"
    echo "  $0 -m eDP-1 +10% # Force adjust a specific monitor manually"
    echo "  $0 -g            # Get active monitor brightness value"
    echo "  $0 -g -m DP-1    # Get a specific monitor brightness value"
    echo ""
    echo "Options:"
    echo "  -m, --monitor <name>   Manually specify monitor name/connector (e.g., eDP-1, DP-2)"
    echo "  -h, --help             Show this help screen"
    echo "  -g, --get              Get monitor brightness value"
    exit 0
}

# --- PARSE ARGUMENTS ---
MANUAL_MONITOR=""
VALUE=""
GET_MODE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--monitor)
            MANUAL_MONITOR="$2"
            shift 2
            ;;
        -g|--get)
            GET_MODE=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            VALUE="$1"
            shift
            ;;
    esac
done

if [ "$GET_MODE" = false ] && [ -z "$VALUE" ]; then
    echo "Error: Missing adjustment value (e.g., +10%, -10%, 50%)."
    show_help
fi

# --- AUTOMATIC DETECT ACTIVE MONITOR CONTEXT ---
get_active_monitor() {
    # 1. Hyprland
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
        return
    fi

    # 2. Niri
    if [ -n "${NIRI_SOCKET:-}" ]; then
        niri msg --json focused-output | jq -r '.name'
        return
    fi

    # 3. GNOME (Wayland via bus request)
    if [ "${XDG_CURRENT_DESKTOP:-}" = "GNOME" ]; then
        # GNOME handles display routing dynamically; fall back to checking mouse cursor if needed
        # But for generic script parsing, fallback to primary default window rule or standard eDP detection
        echo "AUTO"
        return
    fi

    # 4. Generic fallback via xrandr (For X11: Plasma X11, i3, bspwm)
    if command -v xrandr >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
        xrandr --listmonitors | awk '/^\s*[0-9]+/ {print $4; exit}'
        return
    fi

    echo "AUTO"
}

# Decide target monitor
TARGET_MONITOR="${MANUAL_MONITOR:-$(get_active_monitor)}"

# Evaluate if target is internal laptop display (standard naming conventions)
IS_INTERNAL=false
if [[ "$TARGET_MONITOR" =~ ^(eDP|LVDS|eDP-)[0-9]+$ ]] ||
   [[ "$TARGET_MONITOR" == "AUTO" && ( -d /sys/class/backlight/intel_backlight || -d /sys/class/backlight/amdgpu_bl0 ) ]]; then
    IS_INTERNAL=true
fi

# --- GET MODE IMPLEMENTATION ---
if [ "$GET_MODE" = true ]; then
    if [ "$IS_INTERNAL" = true ]; then
        b_val=$(brightnessctl -c backlight -m 2>/dev/null | awk -F, 'NR==1 {print $4}')
        echo "${b_val:-0%}"
    else
        BUS_INDEX="1"
        if [ "$TARGET_MONITOR" != "AUTO" ]; then
            BUS_INDEX=$(ddcutil detect | grep -B 3 "$TARGET_MONITOR" | grep "I2C bus:" | awk -F'-' '{print $2}' || echo "1")
        fi

        b_val=$(ddcutil -b "$BUS_INDEX" getvcp 10 2>/dev/null | sed -n 's/.*current value = *\([0-9]*\).*/\1%/p')
        echo "${b_val:-0%}"
    fi
    exit 0
fi

# --- PARSE VALUE INTO FORMATS ---
# Strip %, extract absolute integer numbers, and sign
DIGITS=$(echo "$VALUE" | tr -cd '0-9')
IS_RELATIVE=false
IS_DECREASE=false

if [[ "$VALUE" == *"+"* ]]; then
    IS_RELATIVE=true
elif [[ "$VALUE" == *"-"* ]]; then
    IS_RELATIVE=true
    IS_DECREASE=true
fi

# --- EXECUTION ENGINE ---
if [ "$IS_INTERNAL" = true ]; then
    # Internal Display -> Use brightnessctl
    if [ "$IS_RELATIVE" = true ]; then
        if [ "$IS_DECREASE" = true ]; then
            BRIGHTNESSCTL_ARG="${DIGITS}%-"
        else
            BRIGHTNESSCTL_ARG="${DIGITS}%+"
        fi
    else
        BRIGHTNESSCTL_ARG="${DIGITS}%"
    fi

    echo "Adjusting internal display using brightnessctl ($BRIGHTNESSCTL_ARG)..."
    brightnessctl set "$BRIGHTNESSCTL_ARG"
else
    # External Display -> Use ddcutil
    BUS_INDEX="1"
    if [ "$TARGET_MONITOR" != "AUTO" ]; then
        # Parse ddcutil output to find which bus maps to our video connector
        BUS_INDEX=$(ddcutil detect | grep -B 3 "$TARGET_MONITOR" | grep "I2C bus:" | awk -F'-' '{print $2}' || echo "1")
    fi

    # ddcutil setvcp expects format: 'value' or '+ value' or '- value'
    if [ "$IS_RELATIVE" = true ]; then
        if [ "$IS_DECREASE" = true ]; then
            DDCUTIL_ARG="- $DIGITS"
        else
            DDCUTIL_ARG="+ $DIGITS"
        fi
    else
        DDCUTIL_ARG="$DIGITS"
    fi

    echo "Adjusting external display (Bus $BUS_INDEX) using ddcutil ($DDCUTIL_ARG)..."
    ddcutil -b "$BUS_INDEX" setvcp 10 $DDCUTIL_ARG
fi