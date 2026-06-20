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
    echo "  $0 -m DP-1 auto  # Restore calibrated/saved default brightness"
    echo "  $0 -m DP-1 save  # Save current brightness as default for this monitor"
    echo "  $0 -g            # Get active monitor brightness value"
    echo "  $0 -g -m DP-1    # Get a specific monitor brightness value"
    echo "  $0 --default     # Get default brightness value from OS/DE/Hardware"
    echo ""
    echo "Options:"
    echo "  -m, --monitor <name>   Manually specify monitor name/connector (e.g., eDP-1, DP-2)"
    echo "  -h, --help             Show this help screen"
    echo "  -g, --get              Get monitor brightness value"
    echo "  -d, --default          Get default brightness value from OS/WM or hardware"
    exit 0
}

# --- PARSE ARGUMENTS ---
MANUAL_MONITOR=""
VALUE=""
GET_MODE=false
DEFAULT_MODE=false

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
        -d|--default)
            DEFAULT_MODE=true
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

if [ "$GET_MODE" = false ] && [ "$DEFAULT_MODE" = false ] && [ -z "$VALUE" ]; then
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

# --- AUTO / SAVE VALUE HANDLING ---

get_auto_brightness() {
    local monitor="$1"

    # Tier 1: ICC target luminance via colord
    if command -v colormgr >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        local device_id
        device_id=$(colormgr get-devices 2>/dev/null \
            | grep "^Device ID:" | grep "$monitor" | head -1 | awk '{print $NF}' || true)

        if [[ -n "$device_id" ]]; then
            local profile_file
            profile_file=$(colormgr device-get-default-profile "$device_id" 2>/dev/null \
                | grep "^Filename:" | head -1 | awk '{print $NF}' || true)

            if [[ -n "$profile_file" && -f "$profile_file" ]]; then
                local target_lumi
                target_lumi=$(ICC_PROFILE="$profile_file" python3 <<'PYEOF'
import struct, os
path = os.environ['ICC_PROFILE']
try:
    with open(path, 'rb') as f:
        data = f.read()
    n = struct.unpack_from('>I', data, 128)[0]
    for i in range(n):
        base = 132 + i * 12
        if data[base:base+4] == b'lumi':
            off = struct.unpack_from('>I', data, base+4)[0]
            y = struct.unpack_from('>i', data, off+12)[0] / 65536.0
            print(int(round(y)))
            break
except Exception:
    pass
PYEOF
                )

                if [[ -n "$target_lumi" && "$target_lumi" -gt 0 ]]; then
                    local env_key="MOLNIOS_PEAK_LUMI_${monitor//-/_}"
                    local max_lumi="${!env_key:-250}"

                    local pct=$(( target_lumi * 100 / max_lumi ))

                    echo "$(( pct < 1 ? 1 : pct > 100 ? 100 : pct ))"
                    return 0
                fi
            fi
        fi
    fi

    # Tier 2: saved config
    local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/molnios/brightness.conf"

    if [[ -f "$cfg" ]]; then
        local saved
        saved=$(grep -m1 "^${monitor}=" "$cfg" 2>/dev/null | cut -d= -f2- || true)

        [[ -n "$saved" ]] && {
            echo "$saved"
            return 0
        }
    fi

    # Tier 3 fallback
    echo "50"
}

get_os_default_brightness() {
    local monitor="$1"
    local is_internal="$2"

    # 1. Desktop Environment Native Defaults (KDE Plasma)
    if [[ "${XDG_CURRENT_DESKTOP:-}" == *"KDE"* ]] && [[ "$is_internal" == true ]]; then
        local kde_bright=""
        if command -v kreadconfig6 >/dev/null 2>&1; then
            kde_bright=$(kreadconfig6 --file powermanagementprofilesrc --group AC --group Display --key Brightness 2>/dev/null || true)
        elif command -v kreadconfig5 >/dev/null 2>&1; then
            kde_bright=$(kreadconfig5 --file powermanagementprofilesrc --group AC --group Display --key Brightness 2>/dev/null || true)
        fi

        if [[ -n "$kde_bright" ]]; then
            echo "${kde_bright}%"
            return 0
        fi
    fi

    # 2. OS Level / Systemd Backlight Best-Effort (Internal Displays)
    # Checks the systemd state daemon file where the OS natively saves brightness per boot
    if [[ "$is_internal" == true && -d /sys/class/backlight ]]; then
        local backlight_dir
        backlight_dir=$(ls -1d /sys/class/backlight/* 2>/dev/null | head -1 || true)

        if [[ -n "$backlight_dir" && -d /var/lib/systemd/backlight ]]; then
            local bl_name
            bl_name=$(basename "$backlight_dir")
            local matched_file
            matched_file=$(find /var/lib/systemd/backlight/ -type f -name "*${bl_name}*" 2>/dev/null | head -1 || true)

            if [[ -n "$matched_file" && -r "$matched_file" ]]; then
                local saved_val max_val
                saved_val=$(grep -Eo '^[0-9]+' "$matched_file" 2>/dev/null | head -1 || true)
                max_val=$(cat "${backlight_dir}/max_brightness" 2>/dev/null || true)

                if [[ -n "$saved_val" && -n "$max_val" && "$max_val" -gt 0 ]]; then
                    local pct=$(( saved_val * 100 / max_val ))
                    echo "${pct}%"
                    return 0
                fi
            fi
        fi
    fi

    # 3. Hardware Vendor / ICC profile / Custom Script Config
    # If no OS-specific profile is found, query via ICC profile luminance metrics
    local auto_val
    auto_val=$(get_auto_brightness "$monitor")
    echo "${auto_val}%"
}

save_default_brightness() {
    local monitor="$1"
    local is_internal="$2"
    local current_pct

    if [[ "$is_internal" == true ]]; then
        current_pct=$(brightnessctl -c backlight -m 2>/dev/null \
            | awk -F, 'NR==1 {print $4}' | tr -d '%' || true)
    else
        local bus=1

        [[ "$monitor" != "AUTO" ]] && \
            bus=$(ddcutil detect 2>/dev/null | grep -B 3 "$monitor" | grep "I2C bus:" \
                | awk -F'-' '{print $2}' || echo 1)

        current_pct=$(ddcutil -b "$bus" getvcp 10 2>/dev/null \
            | sed -n 's/.*current value = *\([0-9]*\).*/\1/p' || true)
    fi

    [[ -z "$current_pct" ]] && {
        echo "Error: cannot read current brightness for '$monitor'." >&2
        exit 1
    }

    local cfg="${XDG_CONFIG_HOME:-$HOME/.config}/molnios/brightness.conf"

    mkdir -p "$(dirname "$cfg")"

    if grep -q "^${monitor}=" "$cfg" 2>/dev/null; then
        sed -i "s|^${monitor}=.*|${monitor}=${current_pct}|" "$cfg"
    else
        echo "${monitor}=${current_pct}" >> "$cfg"
    fi

    echo "Saved brightness default for '$monitor': ${current_pct}%"
    exit 0
}

# --- DEFAULT MODE IMPLEMENTATION ---
if [ "$DEFAULT_MODE" = true ]; then
    get_os_default_brightness "$TARGET_MONITOR" "$IS_INTERNAL"
    exit 0
fi

# --- GET MODE IMPLEMENTATION ---
if [ "$GET_MODE" = true ]; then
    if [ "$IS_INTERNAL" = true ]; then
        b_val=$(brightnessctl -c backlight -m 2>/dev/null | awk -F, 'NR==1 {print $4}')
        echo "${b_val:-0%}"
    else
        BUS_INDEX="1"
        if [ "$TARGET_MONITOR" != "AUTO" ]; then
            BUS_INDEX=$(ddcutil detect 2>/dev/null | grep -B 3 "$TARGET_MONITOR" | grep "I2C bus:" | awk -F'-' '{print $2}' || echo "1")
        fi

        b_val=$(ddcutil -b "$BUS_INDEX" getvcp 10 2>/dev/null | sed -n 's/.*current value = *\([0-9]*\).*/\1%/p')
        echo "${b_val:-0%}"
    fi
    exit 0
fi

[[ "$VALUE" == "save" ]] && save_default_brightness "$TARGET_MONITOR" "$IS_INTERNAL"
[[ "$VALUE" == "auto" ]] && VALUE="$(get_auto_brightness "$TARGET_MONITOR")%"

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
        BUS_INDEX=$(ddcutil detect 2>/dev/null | grep -B 3 "$TARGET_MONITOR" | grep "I2C bus:" | awk -F'-' '{print $2}' || echo "1")
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