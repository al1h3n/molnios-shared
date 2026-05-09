# MolniOS Main Menu Preset
# This file defines the main menu structure and all submenus

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
        for ((i=0; i<spacing_count; i++)); do
            spaces+=" "
        done
        
        echo "${icon}${spaces}${rest}"
    else
        echo "$text"
    fi
}

# HELPER FUNCTIONS

exists(){
	command -v $1&>/dev/null
}

# Notification helper
notify(){
    if exists notify-send;then
        notify-send -h int:transient:1 MolniOS "$1"
    fi
}

# POWER OPTIONS ACTIONS
power_lock(){
    notify "Locking session..."
    # loginctl lock-session
    hyprlock -q -c $L_PATH/config/hyprlock
}

power_shutdown(){
    poweroff
}

power_reboot(){
    reboot
}

power_logout(){
    loginctl terminate-session $XDG_SESSION_ID
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

# CONNECTION OPTIONS ACTIONS
connection_wifi(){
    if exists nmtui;then
        if exists kitty;then
            kitty --class floating -e nmtui
        elif exists kitty;then
            wezterm start -- nmtui
        else
            xterm -e nmtui
        fi
    else
        notify "nmtui not found"
    fi
}

connection_nm_applet(){
    if exists nm-connection-editor;then
        nm-connection-editor &
    else
        notify "Network Manager not found"
    fi
}

connection_bluetooth(){
    if exists blueman-manager;then
        blueman-manager &
    elif exists blueberry;then
        blueberry &
    else
        notify "Bluetooth manager not found"
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
    
    # Apply to GTK
    if [[ -f "$HOME/.config/gtk-3.0/settings.ini" ]];then
        sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$theme_name/" "$HOME/.config/gtk-3.0/settings.ini"
    fi
    
    # Apply to waybar
    if exists killall && pgrep -x waybar;then
        killall -SIGUSR2 waybar
    fi
    
    # Apply to hyprland borders
    if exists hyprctl; then
        hyprctl reload
    fi
    
    # Apply to kitty
    if [[ -f "$HOME/.config/kitty/kitty.conf" ]]; then
        killall -SIGUSR1 kitty 2>/dev/null || true
    fi
    
    notify "Theme applied: $theme_name"
}

theme_random(){
    local themes
    mapfile -t themes < <(theme_list_themes)
    if [[ ${#themes[@]} -gt 0 ]]; then
        local random_theme="${themes[$RANDOM % ${#themes[@]}]}"
        theme_apply "$random_theme"
    fi
}

wallpaper_list_static(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/static"
    if [[ -d "$wallpaper_dir" ]]; then
        find "$wallpaper_dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) -printf "%f\n" | sort
    fi
}

wallpaper_list_video(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/video"
    if [[ -d "$wallpaper_dir" ]]; then
        find "$wallpaper_dir" -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.gif" \) -printf "%f\n" | sort
    fi
}

wallpaper_apply(){
    local wallpaper_path="$1"
    notify "Applying wallpaper..."
    
    if exists waypaper;then
        waypaper --wallpaper "$wallpaper_path"
    elif exists hyprctl; then
        hyprctl hyprpaper preload "$wallpaper_path"
        hyprctl hyprpaper wallpaper ",$wallpaper_path"
    elif exists swaybg; then
        killall swaybg 2>/dev/null || true
        swaybg -i "$wallpaper_path" &
    elif exists feh; then
        feh --bg-fill "$wallpaper_path"
    fi
    
    notify "Wallpaper applied"
}

wallpaper_random(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_static)
    if [[ ${#wallpapers[@]} -gt 0 ]]; then
        local random_wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
        wallpaper_apply "$L_PATH/molnios-media/wallpapers/static/$random_wp"
    fi
}


# COMPOSITOR SETTINGS ACTIONS
compositor_reload(){
    notify "Reloading configurations..."
    
    # Reload Hyprland
    if exists hyprctl; then
        hyprctl reload
    fi
    
    # Reload Niri
    if exists niri && pgrep -x niri;then
        niri msg action reload-config
    fi
    
    # Reload waybar
    if pgrep -x waybar; then
        killall -SIGUSR2 waybar
    fi
    
    notify "Configurations reloaded"
}

# Hyprland settings helpers
hypr_get_setting(){
    local setting="$1"
    local output
    output=$(hyprctl getoption "$setting" 2>/dev/null)
    
    # Try to extract int value
    local value
    value=$(echo "$output" | grep "int:" | sed -n 's/.*int: \([0-9-]*\).*/\1/p')
    
    # If no int found, try float
    if [[ -z "$value" ]]; then
        value=$(echo "$output" | grep "float:" | sed -n 's/.*float: \([0-9.-]*\).*/\1/p')
    fi
    
    # If still no value, return 0
    if [[ -z "$value" ]]; then
        echo "0"
    else
        echo "$value"
    fi
}

hypr_set_setting(){
    local setting="$1"
    local value="$2"
    hyprctl keyword "$setting" "$value"
}

hypr_adjust_gaps_in(){
    local current
    current=$(hypr_get_setting "general:gaps_in")
    local new_value
    new_value=$(show_input "Gaps In" "Enter gaps in value:" "$current")
    if [[ -n "$new_value" ]]; then
        hypr_set_setting "general:gaps_in" "$new_value"
        notify "Gaps in set to: $new_value"
    fi
}

hypr_adjust_gaps_out(){
    local current
    current=$(hypr_get_setting "general:gaps_out")
    local new_value
    new_value=$(show_input "Gaps Out" "Enter gaps out value:" "$current")
    if [[ -n "$new_value" ]]; then
        hypr_set_setting "general:gaps_out" "$new_value"
        notify "Gaps out set to: $new_value"
    fi
}

hypr_adjust_border_size(){
    local current
    current=$(hypr_get_setting "general:border_size")
    local new_value
    new_value=$(show_input "Border Size" "Enter border size:" "$current")
    if [[ -n "$new_value" ]]; then
        hypr_set_setting "general:border_size" "$new_value"
        notify "Border size set to: $new_value"
    fi
}

hypr_adjust_rounding(){
    local current
    current=$(hypr_get_setting "decoration:rounding")
    local new_value
    new_value=$(show_input "Rounding" "Enter rounding value:" "$current")
    if [[ -n "$new_value" ]]; then
        hypr_set_setting "decoration:rounding" "$new_value"
        notify "Rounding set to: $new_value"
    fi
}

hypr_toggle_animations(){
    local current
    current=$(hypr_get_setting "animations:enabled")
    local new_value=$((1 - current))
    hypr_set_setting "animations:enabled" "$new_value"
    notify "Animations: $([ $new_value -eq 1 ] && echo 'enabled' || echo 'disabled')"
}

hypr_toggle_blur(){
    local current
    current=$(hypr_get_setting "decoration:blur:enabled")
    local new_value=$((1 - current))
    hypr_set_setting "decoration:blur:enabled" "$new_value"
    notify "Blur: $([ $new_value -eq 1 ] && echo 'enabled' || echo 'disabled')"
}

hypr_toggle_shadows(){
    local current
    current=$(hypr_get_setting "decoration:drop_shadow")
    local new_value=$((1 - current))
    hypr_set_setting "decoration:drop_shadow" "$new_value"
    notify "Shadows: $([ $new_value -eq 1 ] && echo 'enabled' || echo 'disabled')"
}

# SOFTWARE UPDATE ACTION
software_update(){
    notify "Starting system update..."
    
    if exists kitty; then
        kitty --class floating -e bash -c "
            echo 'Starting system update...'
            if command -v nixos-rebuild &>/dev/null; then
                sudo sh molnios.sh
            fi
            sudo sh sweeper
            echo 'Update complete. Press Enter to close...'
            read
        "
    else
        notify "Terminal not found"
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
    "󰚰 Software Update" "cmd:software_update"

# Power Options Menu
register_menu "power" \
    "Power Options" \
    "Select power action:" \
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
    " Random Wallpaper" "cmd:wallpaper_random"

# Theme Selection (placeholder - will be dynamically populated)
register_menu "theme_select" \
    "Select Theme" \
    "Choose a theme:" \
    "Default" "cmd:theme_apply default"

# Wallpaper Selection (placeholder)
register_menu "wallpaper_select" \
    "Select Wallpaper" \
    "Choose wallpaper type:" \
    " Static Images" "menu:wallpaper_static" \
    "󰈫 Video Wallpapers" "menu:wallpaper_video"

register_menu "wallpaper_static" \
    "Static Wallpapers" \
    "Select a wallpaper:" \
    "No wallpapers found" "cmd:notify 'No wallpapers found'"

register_menu "wallpaper_video" \
    "Video Wallpapers" \
    "Select a video wallpaper:" \
    "No video wallpapers found" "cmd:notify 'No video wallpapers found'"

# Compositor Settings Menu
register_menu "compositor" \
    "Compositor Settings" \
    "Select compositor:" \
    " Hyprland" "menu:hyprland" \
    "󰂔 Niri" "menu:niri" \
    "󰑓 Reload All Configs" "cmd:compositor_reload"

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
    "Display settings:" \
    " Info" "cmd:notify 'Use hyprctl monitors for display info'"

# Hyprland Misc
register_menu "hyprland_misc" \
    "Hyprland Misc" \
    "Miscellaneous settings:" \
    " Info" "cmd:notify 'Additional settings coming soon'"

# Niri Menu (placeholder)
register_menu "niri" \
    "Niri Settings" \
    "Niri compositor settings:" \
    " Info" "cmd:notify 'Niri settings coming soon'"