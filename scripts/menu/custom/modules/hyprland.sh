# Hyprland modules.
hypr_get_setting() {
    local setting="$1"

    hyprctl getoption -j "$setting" 2>/dev/null \
        | jq -r '
            .data //
            .bool //
            .int //
            .float //
            empty
        '
}

hypr_set_setting(){
    hyprctl eval "$*"
}

_bool_toggle() {
    case "$1" in
        1|true|TRUE|on|enabled)
            echo false
            ;;
        *)
            echo true
            ;;
    esac
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
    local new_state=$(_bool_toggle "$current")
    hypr_set_setting "hl.config({ animations = { enabled = $new_state } })"
    notify "Animations: $new_state"
}

hypr_toggle_blur(){
    local current=$(hypr_get_setting "decoration:blur:enabled")
    local new_state=$(_bool_toggle "$current")
    hypr_set_setting "hl.config({ decoration = { blur = { enabled = $new_state } } })"
    notify "Blur: $new_state"
}

hypr_toggle_shadows(){
    local current=$(hypr_get_setting "decoration:shadow:enabled")
    local new_state=$(_bool_toggle "$current")
    hypr_set_setting "hl.config({ decoration = { shadow = { enabled = $new_state } } })"
    notify "Shadows: $new_state"
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

hypr_toggle_vrr(){
    local -a labels=(
        "0 — Disabled"
        "1 — Always on"
        "2 — Fullscreen only"
    )
    local idx
    idx=$(show_menu "Hyprland — VRR" "Select VRR mode:" "${labels[@]}")
    [[ -z "$idx" || ! "$idx" =~ ^[0-9]+$ ]] && return
    hypr_set_setting "hl.config({ misc = { vrr = $idx } })"
    notify "VRR: ${labels[$idx]}"
}

hypr_toggle_tearing(){
    local current
    current=$(hypr_get_setting "general:allow_tearing")
    local new_state
    new_state=$(_bool_toggle "$current")
    hypr_set_setting "hl.config({ general = { allow_tearing = $new_state } })"
    notify "Tearing: $new_state"
}

hypr_toggle_cursor_zoom(){
    local current
    current=$(hypr_get_setting "cursor:zoom_factor")
    # At 1.0 (no zoom) → ask for a factor.  Otherwise → toggle off.
    if [[ -z "$current" ]] || awk "BEGIN{exit !($current <= 1.05)}"; then
        local new_val
        new_val=$(show_input "Cursor Zoom" \
            "Enter zoom factor (e.g. 1.5, 2.0).\nSet to 1 to disable." \
            "${current:-2.0}")
        [[ -z "$new_val" ]] && return
        [[ ! "$new_val" =~ ^[0-9]+(\.[0-9]+)?$ ]] && {
            notify_error "Invalid zoom factor: $new_val"
            return
        }
        hypr_set_setting "hl.config({ cursor = { zoom_factor = $new_val } })"
        notify "Cursor zoom: ${new_val}x"
    else
        hypr_set_setting "hl.config({ cursor = { zoom_factor = 1.0 } })"
        notify "Cursor zoom: off"
    fi
}