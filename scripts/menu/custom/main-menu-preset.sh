# MolniOS Main Menu Preset
# This file defines the main menu structure and all submenus.

case "$0" in
  */*) SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd) ;;
  *)   SCRIPT_DIR=$(pwd) ;;
esac
. "$SCRIPT_DIR/custom/modules/wallpaper.sh"
. "$SCRIPT_DIR/custom/modules/hyprland.sh"
. "$SCRIPT_DIR/custom/modules/niri.sh"

# CONFIGURATION
# Icon spacing configuration (number of spaces after icons)
ICON_SPACING="${ICON_SPACING:-1}"  # Default: 1 space
ICON_SPACING_FALLBACK="${ICON_SPACING_FALLBACK:-1}"  # Fallback: 1 space

# Helper to add consistent spacing after icons
add_icon_spacing(){
    local text="$1"
    local spacing_count="${ICON_SPACING:-$ICON_SPACING_FALLBACK}"

    # Check if text starts with an emoji/icon (Unicode character)
    if [[ "$text" =~ ^[^[:ascii:]] ]];then
        # Extract icon and rest of text
        local icon="${text:0:2}"  # Most emojis are 2 bytes in UTF-8
        local rest="${text:2}"

        # Remove existing spaces after icon
        rest="${rest#"${rest%%[![:space:]]*}"}"

        # Add configured spacing
        local spaces=""
        for ((i=0; i<spacing_count; i++));do
            spaces+=" "
        done

        echo "${icon}${spaces}${rest}"
    else
        echo "$text"
    fi
}

# HELPER FUNCTIONS

exists(){
	command -v "$1" &>/dev/null
}

# Notification helper
notify(){
    if exists notify-send;then
        notify-send -h int:transient:1 "MolniOS Manager" "$1"
    fi
}

notify_error(){
    if exists notify-send;then
        notify-send -h int:transient:1 -u critical "MolniOS Manager" "$1"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# TERMINAL HELPERS
# ─────────────────────────────────────────────────────────────────────────────

# Priority order: WezTerm → Kitty → Ghostty → Alacritty → xterm (fallback)
_TERM_PRIORITY=(wezterm kitty ghostty alacritty xterm)

# Return the launch prefix for a given terminal name, or empty if not installed.
_term_launch_prefix(){
    local term="$1"
    case "$term" in
        wezterm)   exists wezterm   && echo "wezterm --config-file $L_PATH/config/wezterm/wezterm.lua start --class floating --" ;;
        kitty)     exists kitty     && echo "kitty --class floating -e" ;;
        ghostty)   exists ghostty   && echo "ghostty -e" ;;
        alacritty) exists alacritty && echo "alacritty -e" ;;
        xterm)     exists xterm     && echo "xterm -e" ;;
    esac
}

# Returns the launch prefix for the highest-priority available terminal.
_term_auto(){
    for t in "${_TERM_PRIORITY[@]}";do
        local prefix
        prefix=$(_term_launch_prefix "$t")
        if [[ -n "$prefix" ]];then
            echo "$prefix"
            return 0
        fi
    done
    return 1
}

# Build the list of installed terminals for the menu.
_term_installed_list(){
    local list=()
    for t in "${_TERM_PRIORITY[@]}";do
        exists "$t" && list+=("$t")
    done
    echo "${list[@]}"
}

# Interactive terminal picker.
# Presents only installed terminals; if only one is available it is chosen
# immediately without showing a menu. Prints the launch prefix on stdout.
_term_pick(){
    local -a installed
    mapfile -t installed < <(_term_installed_list | tr ' ' '\n')

    if [[ ${#installed[@]} -eq 0 ]];then
        notify_error "No supported terminal emulator found"
        return 1
    fi

    if [[ ${#installed[@]} -eq 1 ]];then
        _term_launch_prefix "${installed[0]}"
        return 0
    fi

    local idx
    idx=$(show_menu "Choose Terminal" "Select terminal emulator:" "${installed[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return 1

    _term_launch_prefix "${installed[$idx]}"
}

# ─────────────────────────────────────────────────────────────────────────────
# OPEN TERMINAL ACTION
# ─────────────────────────────────────────────────────────────────────────────

open_terminal(){
    local prefix
    prefix=$(_term_pick) || return

    case "$prefix" in
        "wezterm start --")
            wezterm start &
            ;;
        *)
            local bin="${prefix%% *}"
            $bin &
            ;;
    esac
}

# POWER OPTIONS ACTIONS
power_lock(){
    notify "Locking session..."
    hyprlock -q -c "$L_PATH/config/hypr/hyprlock.conf"
}

power_shutdown(){
    poweroff
}

power_reboot(){
    reboot
}

power_logout(){
    loginctl terminate-session "$XDG_SESSION_ID"
}

power_suspend(){
    systemctl suspend
}

power_hibernate(){
    systemctl hibernate
}

power_sleep(){
    systemctl sleep
}

power_brightness(){
    local input
    input=$(show_input "Brightness" "Percentage (e.g. 50%) or relative (+10% / -10%):" "")

    [[ -z "$input" ]] && return 0  # cancelled

    input="${input// /}"  # drop stray spaces

    if [[ ! "$input" =~ ^[+-]?[0-9]{1,3}%?$ ]];then
        notify_error "Invalid brightness value: $input"
        return 1
    fi

    if sh "$L_PATH/scripts/brightness.sh" "$input";then
        notify "Brightness: $input"
    else
        notify_error "Brightness adjustment failed"
    fi
}

# CONNECTION OPTIONS ACTIONS
connection_wifi(){
    if exists nmtui;then
        local prefix
        prefix=$(_term_pick) || return
        $prefix nmtui
    else
        notify_error "nmtui not found"
    fi
}

connection_nm_applet(){
    if exists nm-connection-editor;then
        nm-connection-editor &
    else
        notify_error "Network Manager not found"
    fi
}

connection_bluetooth(){
    if exists blueman-manager;then
        blueman-manager &
    elif exists blueberry;then
        blueberry &
    else
        notify_error "Bluetooth manager not found"
    fi
}

# THEMES & COLORS ACTIONS
theme_list_themes(){
    local theme_dir="$L_PATH/molnios-themes"
    if [[ -d "$theme_dir" ]];then
        find "$theme_dir" -maxdepth 1 -type d -not -path "$theme_dir" -printf "%f\n" | sort
    else
        echo "default"
    fi
}

theme_apply(){
    local theme_name="$1"
    notify "Applying theme: $theme_name"

    # Apply to GTK (using pipe delimiter to prevent sed errors on slashes)
    if [[ -f "$HOME/.config/gtk-3.0/settings.ini" ]];then
        sed -i "s|^gtk-theme-name=.*|gtk-theme-name=$theme_name|" "$HOME/.config/gtk-3.0/settings.ini"
    fi

    # Apply to waybar
    if exists killall && pgrep -x waybar;then
        killall -SIGUSR2 waybar
    fi

    # Apply to hyprland borders
    if exists hyprctl;then
        hyprctl reload
    fi

    # Apply to kitty
    if [[ -f "$HOME/.config/kitty/kitty.conf" ]];then
        killall -SIGUSR1 kitty 2>/dev/null || true
    fi

    notify "Theme applied: $theme_name"
}

theme_random(){
    local themes
    mapfile -t themes < <(theme_list_themes)
    if [[ ${#themes[@]} -gt 0 ]];then
        local random_theme="${themes[$RANDOM % ${#themes[@]}]}"
        theme_apply "$random_theme"
    fi
}

# COMPOSITOR SETTINGS ACTIONS
current_compositor() {
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        echo hyprland
    elif [[ -n "${NIRI_SOCKET:-}" ]]; then
        echo niri
    else
        echo unknown
    fi
}

open_active_compositor_menu() {
    local compositor

    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        compositor="hyprland"
    elif [[ -n "${NIRI_SOCKET:-}" ]]; then
        compositor="niri"
    else
        notify_error "No supported compositor detected"
        return 1
    fi

    show_menu_by_id "$compositor"
}

compositor_reload(){
    sh "$L_PATH/scripts/reloadus.sh"
}

gamemode(){
    sh $L_PATH/scripts/gamemode.sh
}

# SOFTWARE UPDATE ACTION
software_update(){
    notify "Starting system update..."

    local term_cmd
    term_cmd=$(_term_auto)

    if [[ -n "$term_cmd" ]]; then
        $term_cmd bash -c "
            echo 'Starting system update...'
            if command -v nixos-rebuild &>/dev/null;then
                if command -v doas &>/dev/null;then
                    doas sh /usr/local/bin/molnios.sh -f -dp -nb
                else
                    sudo sh /usr/local/bin/molnios.sh -f -dp -nb
                fi
            fi
            sudo sh sweeper
            echo 'Update complete. Press Enter to close...'
            read
        "
    else
        notify_error "No terminal emulator found"
    fi
}


# MENU DEFINITIONS

# Main Menu
register_menu "main" \
    "MolniOS Main Menu" \
    "Select an option:" \
    "󰌘 Connection" "menu:connection" \
    "󰚥 Power Options" "menu:power" \
    "󰏘 Themes & Colors" "menu:themes" \
    "󰹑 Compositor Settings" "menu:compositor" \
    "󰚰 Software Update" "cmd:software_update" \
    " Open terminal" "cmd:open_terminal"

# Power Options Menu
register_menu "power" \
    "Power Options" \
    "Select power action:" \
    "󰳲 Brightness" "cmd:power_brightness"  \
    " Lock" "cmd:power_lock" \
    "⏻ Shutdown" "cmd:power_shutdown" \
    " Reboot" "cmd:power_reboot" \
    "󰈆 Logout" "cmd:power_logout" \
    "󰤄 Suspend" "cmd:power_suspend" \
    " Hibernate" "cmd:power_hibernate" \
    "󰨣 Hybrid Sleep" "cmd:power_sleep"

# Connection Menu
register_menu "connection" \
    "Connection Options" \
    "Select connection option:" \
    "  Wi-Fi Settings" "cmd:connection_wifi" \
    "  Network Manager" "cmd:connection_nm_applet" \
    "  Bluetooth Manager" "cmd:connection_bluetooth"

# Themes & Colors Menu
register_menu "themes" \
    "Themes & Colors" \
    "Select theme option:" \
    " Select Theme" "menu:theme_select" \
    "󰇎 Random Theme" "cmd:theme_random" \
    "󰟾 Select Wallpaper" "menu:wallpaper_select" \
    " Random Wallpaper" "cmd:wallpaper_random_static_matugen" \
    " Terminal theme" "menu:term_colors"

register_menu "term_colors" \
    "Terminal Colors" \
    "Pick a source image to generate colors from:" \
    "matugen"  "cmd:matugen_colors_static" \
    "matugen (video)"   "cmd:matugen_colors_video" \
    "wallust"    "cmd:wallust_colors_static" \
    "wallust (video)"   "cmd:wallust_colors_video"

# Theme Selection
register_menu "theme_select" \
    "Select Theme" \
    "Choose a theme:" \
    "Default" "cmd:theme_apply default"

register_menu "wallpaper_select" \
    "Select Wallpaper" \
    "Choose color backend:" \
    "Regular" "menu:wallpaper_regular" \
    "Pywal" "menu:wallpaper_pywal" \
    "Wallust" "menu:wallpaper_wallust" \
    "Matugen" "menu:wallpaper_matugen"

register_menu "wallpaper_regular" \
    "Regular Wallpaper" \
    "Set wallpaper without color theming:" \
    " Static Images"  "cmd:wallpaper_menu_static" \
    "󰈫 Video Wallpapers" "cmd:wallpaper_menu_video" \
    " Random Static"  "cmd:wallpaper_random" \
    " Random Video"   "cmd:wallpaper_random_video"

register_menu "wallpaper_pywal" \
    "Wallpaper + Pywal" \
    "Set wallpaper and generate pywal theme:" \
    " Static Images"       "cmd:wallpaper_menu_static_pywal" \
    "󰈫 Video Wallpapers"   "cmd:wallpaper_menu_video_pywal" \
    " Random Static"       "cmd:wallpaper_random_static_pywal" \
    " Random Video"        "cmd:wallpaper_random_video_pywal"

register_menu "wallpaper_wallust" \
    "Wallpaper + Wallust" \
    "Set wallpaper and generate pywal theme:" \
    " Static Images"       "cmd:wallpaper_menu_static_wallust" \
    "󰈫 Video Wallpapers"   "cmd:wallpaper_menu_video_wallust" \
    " Random Static"       "cmd:wallpaper_random_static_wallust" \
    " Random Video"        "cmd:wallpaper_random_video_wallust"

register_menu "wallpaper_matugen" \
    "Wallpaper + Matugen" \
    "Set wallpaper and generate Material You theme:" \
    " Static Images" "cmd:wallpaper_menu_static_matugen" \
    "󰈫 Video Wallpapers" "cmd:wallpaper_menu_video_matugen" \
    " Random Static" "cmd:wallpaper_random_static_matugen" \
    " Random Video" "cmd:wallpaper_random_video_matugen"

# Compositor Settings Menu
register_menu "compositor" \
    "Compositor Settings" \
    "Select compositor:" \
    "󰑓 Active Compositor Settings" "cmd:open_active_compositor_menu" \
    " Hyprland" "menu:hyprland" \
    "󰂔 Niri" "menu:niri" \
    "󰑓 Reload All Configs" "cmd:compositor_reload" \
    "󰖺 Toggle gamemode" "cmd:gamemode"

# Hyprland Menu
register_menu "hyprland" \
    "Hyprland Settings" \
    "Select category:" \
    " General" "menu:hyprland_general" \
    " Decorations" "menu:hyprland_decorations" \
    "󰿉 Animations" "menu:hyprland_animations" \
    "󰍹 Display" "menu:hyprland_display" \
    " Misc" "menu:hyprland_misc"

# Hyprland General
register_menu "hyprland_general" \
    "Hyprland General" \
    "Adjust general settings:" \
    " Gaps In" "cmd:hypr_adjust_gaps_in" \
    " Gaps Out" "cmd:hypr_adjust_gaps_out" \
    " Border Size" "cmd:hypr_adjust_border_size"

# Hyprland Decorations
register_menu "hyprland_decorations" \
    "Hyprland Decorations" \
    "Adjust decoration settings:" \
    "󰘇 Rounding" "cmd:hypr_adjust_rounding" \
    "󰘷 Toggle Shadows" "cmd:hypr_toggle_shadows" \
    "󰂵 Toggle Blur" "cmd:hypr_toggle_blur"

# Hyprland Animations
register_menu "hyprland_animations" \
    "Hyprland Animations" \
    "Animation settings:" \
    "󰗘 Toggle Animations" "cmd:hypr_toggle_animations"

# Hyprland Display
register_menu "hyprland_display" \
    "Hyprland Display" \
    "Select display setting:" \
    "󰹑 Resolution" "cmd:hypr_set_resolution" \
    "󰑒 Scale" "cmd:hypr_set_scale" \
    "󰙵 Test Mode"  "cmd:hypr_test_resolution" \
    " Toggle VRR" "cmd:hypr_toggle_vrr"

# Hyprland Misc
register_menu "hyprland_misc" \
    "Hyprland Misc" \
    "Miscellaneous settings:" \
    " Toggle Cursor Zoom" "cmd:hypr_toggle_cursor_zoom" \
    "󱡕 Toggle Tearing" "cmd:hypr_toggle_tearing"

# Niri Menu
register_menu "niri" \
    "Niri Settings" \
    "Select category:" \
    " Layout" "menu:niri_layout" \
    " Effects" "menu:niri_effects" \
    "󰍹 Display" "menu:niri_display" \
    "󰋜 Overview" "menu:niri_overview" \
    " Misc" "menu:niri_misc"

register_menu "niri_layout" \
    "Niri Layout" \
    "Adjust layout settings:" \
    " Gaps" "cmd:niri_adjust_gaps" \
    " Border Width" "cmd:niri_adjust_border_width" \
    "󰘇 Focus Ring Width" "cmd:niri_adjust_focus_ring_width"

register_menu "niri_effects" \
    "Niri Effects" \
    "Adjust visual effects:" \
    "󰂵 Toggle Blur" "cmd:niri_toggle_blur" \
    "󰘷 Toggle Shadows" "cmd:niri_toggle_shadow" \
    "󰂶 Toggle Xray Blur" "cmd:niri_toggle_xray" \
    "󰍉 Blur Saturation" "cmd:niri_blur_saturation" \
    "󰍉 Blur Noise" "cmd:niri_blur_noise"

register_menu "niri_display" \
    "Niri Display" \
    "Display settings:" \
    "󰑒 Scale" "cmd:niri_set_scale" \
    "󰹑 Resolution" "cmd:niri_set_resolution"

register_menu "niri_overview" \
    "Niri Overview" \
    "Overview settings:" \
    "󰋜 Toggle Backdrop Blur" "cmd:niri_toggle_overview_blur" \
    "󰋜 Toggle Overview Effects" "cmd:niri_toggle_overview_effects"

register_menu "niri_misc" \
    "Niri Misc" \
    "Miscellaneous settings:" \
    "󰖲 Toggle Center Focused Column" "cmd:niri_toggle_center_column" \
    "󰍹 Toggle Single Column Centering" "cmd:niri_toggle_single_column_center" \
    "󰖰 Toggle Prefer No CSD" "cmd:niri_toggle_prefer_no_csd"

# " Info" "cmd:notify 'Coming soon'"