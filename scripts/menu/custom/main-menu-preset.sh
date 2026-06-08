# MolniOS Main Menu Preset
# This file defines the main menu structure and all submenus
# Version 1.1 (updates for new lua syntax of hyprland)

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
        wezterm)   exists wezterm   && echo "wezterm start --class floating" ;;
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

# wallust backend.
_wallust_apply(){
    local wal_src="$1"
    local borderline_src="$2"

    if ! exists wallust;then
        notify_error "wallust not found"
        return 1
    fi

    wallust run -I background "$wal_src"

    local bscript="$L_PATH/scripts/borderline.sh"
    if [[ -f "$bscript" ]];then
        sh "$bscript" "$borderline_src"
    else
        notify_error "borderline.sh not found at $bscript"
    fi
}

wallust_colors_static(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/static"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_static)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No static images found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Wallust — Pick Source Image" "Select image for color generation:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    _wallust_apply "${paths[$idx]}" "${paths[$idx]}"
    notify "Wallust colors applied from: ${labels[$idx]}"
}

wallust_colors_video(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/video"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_video)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No video files found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Wallust — Pick Source Video" "Select video for color generation:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    local wp="${paths[$idx]}"
    local frame
    frame=$(_pywal_extract_frame "$wp")
    _wallust_apply "$frame" "$wp"
    rm -f "$frame"
    notify "Wallust colors applied from: ${labels[$idx]}"
}

wallpaper_random_static_wallust(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_static)
    if [[ ${#wallpapers[@]} -eq 0 ]];then
        notify_error "No static wallpapers found"
        return
    fi
    local wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
    wallpaper_apply "$wp"
    _wallust_apply "$wp" "$wp"
    notify "Random static (wallust): $(basename "$wp")"
}

wallpaper_random_video_wallust(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_video)
    if [[ ${#wallpapers[@]} -eq 0 ]];then
        notify_error "No video wallpapers found"
        return
    fi
    local wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
    wallpaper_apply "$wp"
    local frame
    frame=$(_pywal_extract_frame "$wp")
    _wallust_apply "$frame" "$wp"
    rm -f "$frame"
    notify "Random video (wallust): $(basename "$wp")"
}

wallpaper_menu_static_wallust(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/static"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_static)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No static wallpapers found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Static Wallpapers + Wallust" "Select a wallpaper:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    local wp="${paths[$idx]}"
    wallpaper_apply "$wp"
    _wallust_apply "$wp" "$wp"
    notify "Wallpaper set (wallust): ${labels[$idx]}"
}

wallpaper_menu_video_wallust(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/video"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_video)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No video wallpapers found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Video Wallpapers + Wallust" "Select a video wallpaper:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    local wp="${paths[$idx]}"
    wallpaper_apply "$wp"
    local frame
    frame=$(_pywal_extract_frame "$wp")
    _wallust_apply "$frame" "$wp"
    rm -f "$frame"
    notify "Video wallpaper set (wallust): ${labels[$idx]}"
}

# pywal16 (pywal) backend.

# Extract first video frame for pywal
_pywal_extract_frame(){
    local video="$1"
    local tmp=$(mktemp /tmp/molnios_wal_XXXXXX.png)
    # Fixed missing space before 2>/dev/null
    ffmpeg -i "$video" -y -vframes 1 -vf scale=480:270 -v quiet "$tmp" 2>/dev/null
    echo "$tmp"
}

# Core: run pywal then borderline.
_pywal_apply(){
    local wal_src="$1"
    local borderline_src="$2"

    if ! exists wal;then
        notify_error "pywal (wal) not found"
        return 1
    fi

    wal --recursive -i "$wal_src"

    local bscript="$L_PATH/scripts/borderline.sh"
    if [[ -f "$bscript" ]];then
        sh "$bscript" "$borderline_src"
    else
        notify_error "borderline.sh not found at $bscript"
    fi
}

wallpaper_random_static_pywal(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_static)
    if [[ ${#wallpapers[@]} -eq 0 ]];then
        notify_error "No static wallpapers found"
        return
    fi
    local wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
    wallpaper_apply "$wp"
    _pywal_apply "$wp" "$wp"
    notify "Random static (pywal): $(basename "$wp")"
}

wallpaper_random_video_pywal(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_video)
    if [[ ${#wallpapers[@]} -eq 0 ]];then
        notify_error "No video wallpapers found"
        return
    fi
    local wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
    wallpaper_apply "$wp"
    local frame
    frame=$(_pywal_extract_frame "$wp")
    _pywal_apply "$frame" "$wp"
    rm -f "$frame"
    notify "Random video (pywal): $(basename "$wp")"
}

wallpaper_menu_static_pywal(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/static"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_static)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No static wallpapers found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx=$(show_menu "Static Wallpapers + Pywal" "Select a wallpaper:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    local wp="${paths[$idx]}"
    wallpaper_apply "$wp"
    _pywal_apply "$wp" "$wp"
    notify "Wallpaper set (pywal): ${labels[$idx]}"
}

wallpaper_menu_video_pywal(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/video"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_video)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No video wallpapers found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx=$(show_menu "Video Wallpapers + Pywal" "Select a video wallpaper:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    local wp="${paths[$idx]}"
    wallpaper_apply "$wp"
    local frame=$(_pywal_extract_frame "$wp")
    _pywal_apply "$frame" "$wp"
    rm -f "$frame"
    notify "Video wallpaper set (pywal): ${labels[$idx]}"
}

wallpaper_list_static(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/static"
    if [[ -d "$wallpaper_dir" ]];then
        find "$wallpaper_dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | sort
    fi
}

wallpaper_list_video(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/video"
    if [[ -d "$wallpaper_dir" ]];then
        find "$wallpaper_dir" -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.gif" \) | sort
    fi
}

wallpaper_apply(){
    local wallpaper_path="$1"

    if exists waypaper;then
        waypaper --wallpaper "$wallpaper_path"
    elif exists hyprctl;then
        hyprctl hyprpaper preload "$wallpaper_path"
        hyprctl hyprpaper wallpaper ",$wallpaper_path"
    elif exists swaybg;then
        killall swaybg 2>/dev/null || true
        swaybg -i "$wallpaper_path" &
    elif exists feh;then
        feh --bg-fill "$wallpaper_path"
    fi
}

wallpaper_random(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_static)
    if [[ ${#wallpapers[@]} -gt 0 ]];then
        local random_wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
        wallpaper_apply "$random_wp"
        notify "Random wallpaper: $(basename "$random_wp") ($(basename "$(dirname "$random_wp")"))"
    else
        notify_error "No static wallpapers found"
    fi
}

wallpaper_random_video(){
    local wallpapers
    mapfile -t wallpapers < <(wallpaper_list_video)
    if [[ ${#wallpapers[@]} -gt 0 ]];then
        local random_wp="${wallpapers[$RANDOM % ${#wallpapers[@]}]}"
        wallpaper_apply "$random_wp"
        notify "Random video wallpaper: $(basename "$random_wp") ($(basename "$(dirname "$random_wp")"))"
    else
        notify_error "No video wallpapers found"
    fi
}

wallpaper_menu_static(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/static"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_static)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No static wallpapers were found"
        return
    fi
    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Static Wallpapers" "Select a wallpaper:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    wallpaper_apply "${paths[$idx]}"
    notify "Wallpaper set: ${labels[$idx]}"
}

wallpaper_menu_video(){
    local wallpaper_dir="$L_PATH/molnios-media/wallpapers/video"
    local -a paths labels
    mapfile -t paths < <(wallpaper_list_video)
    if [[ ${#paths[@]} -eq 0 ]];then
        notify_error "No video wallpapers were found"
        return
    fi

    for p in "${paths[@]}";do
        labels+=("${p#"$wallpaper_dir/"}")
    done

    local idx
    idx=$(show_menu "Video Wallpapers" "Select a video wallpaper:" "${labels[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    wallpaper_apply "${paths[$idx]}"
    notify "Video wallpaper set: ${labels[$idx]}"
}

# COMPOSITOR SETTINGS ACTIONS
compositor_reload(){
    sh "$L_PATH/scripts/reloadus.sh"
}

# Fixed logic to properly retrieve values from "custom" properties like gaps
hypr_get_setting(){
    local setting="$1"
    local output
    output=$(hyprctl getoption "$setting" 2>/dev/null)

    # 1. Try to extract 'data:' first (Hyprland stores custom values like gaps here)
    local data_val
    data_val=$(echo "$output" | grep "data:" | sed -n 's/.*data:[[:space:]]*\(.*\)/\1/p' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Check if data_val is populated and is not an unparsed object
    if [[ -n "$data_val" && "$data_val" != "<class "* && "$data_val" != "<Hyprlang::"* ]]; then
        echo "$data_val"
        return
    fi

    # 2. Try to extract standard int
    local int_val
    int_val=$(echo "$output" | grep "int:" | sed -n 's/.*int:[[:space:]]*\([0-9-]*\).*/\1/p')

    # 3. Try to extract standard float
    local float_val
    float_val=$(echo "$output" | grep "float:" | sed -n 's/.*float:[[:space:]]*\([0-9.-]*\).*/\1/p')

    # Figure out the most reasonable value to return
    if [[ -n "$int_val" && "$int_val" != "0" ]]; then
        echo "$int_val"
    elif [[ -n "$float_val" && "$float_val" != "0.000000" && "$float_val" != "0" ]]; then
        echo "$float_val"
    elif [[ -n "$int_val" ]]; then
        echo "$int_val"
    else
        echo "0"
    fi
}

hypr_set_setting(){
    hyprctl eval "$*"
}

# Helper to convert CSS-style gaps into Hyprland 0.55+ Lua tables
_format_css_gaps() {
    # Replace commas with spaces, trim extra spaces, and read into an array
    local cleaned=$(echo "$1" | tr ',' ' ' | tr -s ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    read -ra arr <<< "$cleaned"

    local count=${#arr[@]}

    if [[ $count -eq 0 ]]; then
        echo "0"
    elif [[ $count -eq 1 ]]; then
        # Lua accepts a raw integer if all sides are equal
        echo "${arr[0]}"
    elif [[ $count -eq 2 ]]; then
        # Top/Bottom = 1st | Right/Left = 2nd
        echo "{ top = ${arr[0]}, right = ${arr[1]}, bottom = ${arr[0]}, left = ${arr[1]} }"
    elif [[ $count -eq 3 ]]; then
        # Top = 1st | Right/Left = 2nd | Bottom = 3rd
        echo "{ top = ${arr[0]}, right = ${arr[1]}, bottom = ${arr[2]}, left = ${arr[1]} }"
    else
        # Top = 1st | Right = 2nd | Bottom = 3rd | Left = 4th
        echo "{ top = ${arr[0]}, right = ${arr[1]}, bottom = ${arr[2]}, left = ${arr[3]} }"
    fi
}

hypr_adjust_gaps_in(){
    local current=$(hypr_get_setting "general:gaps_in")
    local new_value=$(show_input "Gaps In" "Enter gaps (e.g. 10 20):" "$current")
    [[ -z "$new_value" ]] && return

    local lua_gaps=$(_format_css_gaps "$new_value")
    hypr_set_setting "hl.config({ general = { gaps_in = $lua_gaps } })"
    notify "Gaps in set to: $new_value"
}

hypr_adjust_gaps_out(){
    local current=$(hypr_get_setting "general:gaps_out")
    local new_value=$(show_input "Gaps Out" "Enter gaps (e.g. 10 20):" "$current")
    [[ -z "$new_value" ]] && return

    local lua_gaps=$(_format_css_gaps "$new_value")
    hypr_set_setting "hl.config({ general = { gaps_out = $lua_gaps } })"
    notify "Gaps out set to: $new_value"
}

hypr_adjust_border_size(){
    local current=$(hypr_get_setting "general:border_size")
    local new_value=$(show_input "Border Size" "Enter border size:" "$current")
    [[ -z "$new_value" ]] && return
    hypr_set_setting "hl.config({ general = { border_size = $new_value } })"
    notify "Border size set to: $new_value"
}

hypr_adjust_rounding(){
    local current=$(hypr_get_setting "decoration:rounding")
    local new_value=$(show_input "Rounding" "Enter rounding value:" "$current")
    [[ -z "$new_value" ]] && return
    hypr_set_setting "hl.config({ decoration = { rounding = $new_value } })"
    notify "Rounding set to: $new_value"
}

hypr_toggle_animations(){
    local current=$(hypr_get_setting "animations:enabled")
    local new_value=$((1 - current))
    local lua_bool=$([[ $new_value -eq 1 ]] && echo "true" || echo "false")
    hypr_set_setting "hl.config({ animations = { enabled = $lua_bool } })"
    notify "Animations: $([[ $new_value -eq 1 ]] && echo 'enabled' || echo 'disabled')"
}

hypr_toggle_blur(){
    local current=$(hypr_get_setting "decoration:blur:enabled")
    local new_value=$((1 - current))
    local lua_bool=$([[ $new_value -eq 1 ]] && echo "true" || echo "false")
    hypr_set_setting "hl.config({ decoration = { blur = { enabled = $lua_bool } } })"
    notify "Blur: $([[ $new_value -eq 1 ]] && echo 'enabled' || echo 'disabled')"
}

hypr_toggle_shadows(){
    local current=$(hypr_get_setting "decoration:shadow:enabled")
    local new_value=$((1 - current))
    local lua_bool=$([[ $new_value -eq 1 ]] && echo "true" || echo "false")
    hypr_set_setting "hl.config({ decoration = { shadow = { enabled = $lua_bool } } })"
    notify "Shadows: $([[ $new_value -eq 1 ]] && echo 'enabled' || echo 'disabled')"
}

# Monitor helpers (backend).
_hypr_display_term_cmd(){
    if exists wezterm;then echo "wezterm start --";return;fi
    if exists kitty;then echo "kitty --class floating -e";return;fi
    if exists alacritty;then echo "alacritty -e";return;fi
    if exists ghostty;then echo "ghostty -e";return;fi
    echo
}

hypr_get_monitors(){
    if exists jq;then
        hyprctl monitors -j 2>/dev/null | jq -r '.[].name'
    else
        hyprctl monitors 2>/dev/null | awk '/^Monitor/{print $2}'
    fi
}

hypr_select_monitor(){
    local monitors=()
    mapfile -t monitors < <(hypr_get_monitors)

    if [[ ${#monitors[@]} -eq 0 ]];then
        notify_error "No monitors detected by hyprctl"
        return 1
    fi

    if [[ ${#monitors[@]} -eq 1 ]];then
        echo "${monitors[0]}"
        return 0
    fi

    if exists gum;then
        local list_file="/tmp/molnios-mon-list-$$"
        local out_file="/tmp/molnios-mon-out-$$"
        local sel_script="/tmp/molnios-mon-sel-$$.sh"

        printf '%s\n' "${monitors[@]}" > "$list_file"

        cat > "$sel_script" << GUMEOF
echo "================================="
echo "  Select Monitor"
echo "================================="
selected=\$(gum choose --header "Available monitors:" < "$list_file")
echo "\$selected" > "$out_file"
GUMEOF
        chmod +x "$sel_script"

        local term_cmd=$(_hypr_display_term_cmd)

        if [[ -n "$term_cmd" ]];then
            $term_cmd bash "$sel_script"
            sleep 0.3
        else
            sh "$sel_script"
        fi

        local result
        if [[ -f "$out_file" ]];then
            result=$(cat "$out_file")
            rm -f "$out_file"
        fi
        rm -f "$list_file" "$sel_script"

        echo "$result"
        return 0
    fi

    local idx
    idx=$(show_menu "Select Monitor" "Choose a monitor:" "${monitors[@]}")
    if [[ -n "$idx" ]] && [[ "$idx" =~ ^[0-9]+$ ]];then
        echo "${monitors[$idx]}"
    else
        echo
    fi
}

hypr_get_monitor_scale(){
    local monitor=$1
    if exists jq;then
        hyprctl monitors -j 2>/dev/null \
            | jq -r --arg m "$monitor" '.[] | select(.name==$m) | .scale'
    else
        hyprctl monitors 2>/dev/null \
            | awk -v mon="$monitor" '
                /^Monitor/{found=($2==mon)}
                found && /scale:/{print $2; exit}
              '
    fi
}

hypr_get_monitor_resolution(){
    local monitor=$1
    if exists jq;then
        hyprctl monitors -j 2>/dev/null \
            | jq -r --arg m "$monitor" '.[] | select(.name==$m) | "\(.width)x\(.height)"'
    else
        hyprctl monitors 2>/dev/null \
            | awk -v mon="$monitor" '
                /^Monitor/{found=($2==mon)}
                found && /[0-9]+x[0-9]+/{print $1; exit}
              '
    fi
}

hypr_get_best_rr_for_res(){
    local monitor=$1
    local resolution=$2
    local w="${resolution%x*}"
    local h="${resolution#*x}"

    if exists jq; then
        hyprctl monitors -j 2>/dev/null \
            | jq -r --arg m "$monitor" --argjson w "$w" --argjson h "$h" \
              '.[] | select(.name==$m) | .availableModes[]
               | select(startswith("\($w)x\($h)@"))
               | ltrimstr("\($w)x\($h)@") | rtrimstr("Hz")
               | tonumber' \
            | sort -rn | head -1
    else
        hyprctl monitors 2>/dev/null \
            | grep "availableModes" \
            | grep -oE "${resolution}@[0-9.]+" \
            | sed "s/${resolution}@//" \
            | sort -rn | head -1
    fi
}

hypr_set_resolution(){
    local monitor=$(hypr_select_monitor)
    [[ -z "$monitor" ]] && return

    local current_res=$(hypr_get_monitor_resolution "$monitor")
    local current_scale=$(hypr_get_monitor_scale "$monitor")
    [[ -z "$current_scale" ]] && current_scale="1"

    local prompt
    prompt="Enter resolution:
  WxH or W H  (e.g. 2560x1440  or  2560 1440)
  0           restore from config file
 -1           highres@highrr (native best mode)

Current: ${current_res:-unknown}, scale: ${current_scale}
Best available refresh rate will be used automatically."

    local new_res=$(show_input "Resolution — $monitor" "$prompt" "")
    [[ -z "$new_res" ]] && return
    new_res=$(printf '%s' "$new_res" | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    case $new_res in
        "0")
            hyprctl reload
            notify "Monitor config restored from config file"
            ;;
        "-1")
            hypr_set_setting "hl.monitor({ output = '$monitor', mode = 'highres@highrr', position = '0x0', scale = $current_scale })"
            notify "$monitor → highres@highrr, scale=$current_scale"
            ;;
        *)
            new_res="${new_res// /x}"
            if [[ ! "$new_res" =~ ^[0-9]+x[0-9]+$ ]]; then
                notify_error "Invalid format. Use WxH (e.g. 2560x1440)"
                return
            fi

            local best_rr
            best_rr=$(hypr_get_best_rr_for_res "$monitor" "$new_res")

            local mode_str
            if [[ -n "$best_rr" ]]; then
                mode_str="${new_res}@${best_rr}"
            else
                mode_str="$new_res"
            fi

            if hypr_set_setting "hl.monitor({ output = '$monitor', mode = '${mode_str}', position = '0x0', scale = $current_scale })" 2>/dev/null; then
                notify "$monitor → ${mode_str}, scale=$current_scale"
            else
                notify_error "Could not set resolution: ${new_res} on $monitor"
            fi
            ;;
    esac
}

hypr_test_resolution(){
    local monitor=$(hypr_select_monitor)
    [[ -z "$monitor" ]] && return

    local current_res=$(hypr_get_monitor_resolution "$monitor")
    local current_scale=$(hypr_get_monitor_scale "$monitor")
    [[ -z "$current_scale" ]] && current_scale="1"

    local available
    available=$(hyprctl monitors 2>/dev/null | grep "availableModes" | sed 's/.*availableModes: //' | tr ' ' '\n' | grep -v '^$')
    if [[ -z "$available" ]]; then
        notify_error "Could not read available modes"
        return
    fi

    local -a modes
    mapfile -t modes <<< "$available"

    local idx
    idx=$(show_menu "Test Resolution — $monitor" \
        "Select a mode to test (auto-restores in 10s):" \
        "${modes[@]}")
    [[ -z "$idx" ]] || [[ ! "$idx" =~ ^[0-9]+$ ]] && return

    local chosen="${modes[$idx]}"
    local mode_str="${chosen%Hz}"

    notify "Testing $mode_str — restoring in 10 seconds..."

    hypr_set_setting "hl.monitor({ output = '$monitor', mode = '${mode_str}', position = '0x0', scale = $current_scale })"
    sleep 10
    hyprctl reload
    notify "Restored to config settings"
}

hypr_set_scale(){
    local monitor=$(hypr_select_monitor)
    [[ -z "$monitor" ]] && return

    local current_scale
    current_scale=$(hypr_get_monitor_scale "$monitor")
    [[ -z "$current_scale" ]] && current_scale="1"

    local prompt="Enter scale factor:
Examples: 1, 1.6, 2, 3.5
0 - Restore from config file."

    local new_scale
    new_scale=$(show_input "Scale — $monitor" "$prompt" "$current_scale")
    [[ -z "$new_scale" ]] && return

    new_scale=$(printf '%s' "$new_scale" \
        | tr -d '\r\n' \
        | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    case "$new_scale" in
        "0")
            hyprctl reload
            notify "Monitor config restored from config file"
            ;;
        *)
            if [[ ! "$new_scale" =~ ^[0-9]+(\.[0-9]+)?$ ]];then
                notify_error "Invalid scale. Use a decimal number (e.g. 1.25)"
                return
            fi
            hypr_set_setting "hl.monitor({ output = '$monitor', mode = 'preferred@highrr', position = '0x0', scale = $new_scale })"
            notify "$monitor → preferred@highrr, scale=$new_scale"
            ;;
    esac
}

# SOFTWARE UPDATE ACTION
software_update(){
    notify "Starting system update..."

    local term_cmd
    term_cmd=$(_term_auto)

    if [[ -n "$term_cmd" ]]; then
        $term_cmd bash -c "
            echo 'Starting system update...'
            if command -v nixos-rebuild &>/dev/null; then
                sudo sh /usr/local/bin/molnios.sh -f -dp -nb -np
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
    " Random Wallpaper" "cmd:wallpaper_random_static_wallust" \
    " Terminal theme" "menu:wallust_colors"

register_menu "wallust_colors" \
    "Terminal Colors" \
    "Pick a source image to generate colors from:" \
    " From Static Image" "cmd:wallust_colors_static" \
    "󰈫 From Video Frame"  "cmd:wallust_colors_video"

# Theme Selection
register_menu "theme_select" \
    "Select Theme" \
    "Choose a theme:" \
    "Default" "cmd:theme_apply default"

register_menu "wallpaper_select" \
    "Select Wallpaper" \
    "Choose color backend:" \
    "Regular"  "menu:wallpaper_regular" \
    "Pywal"    "menu:wallpaper_pywal" \
    "Wallust"  "menu:wallpaper_wallust"

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
    "Select display setting:" \
    "󰹑 Resolution" "cmd:hypr_set_resolution" \
    "󰑒 Scale" "cmd:hypr_set_scale" \
    "󰙵 Test Mode"  "cmd:hypr_test_resolution"

# Hyprland Misc
register_menu "hyprland_misc" \
    "Hyprland Misc" \
    "Miscellaneous settings:" \
    " Info" "cmd:notify 'Additional settings coming soon'"

# Niri Menu
register_menu "niri" \
    "Niri Settings" \
    "Niri compositor settings:" \
    " Info" "cmd:notify 'Niri settings coming soon'"