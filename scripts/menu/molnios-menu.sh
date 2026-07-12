#!/usr/bin/env bash

# MolniOS Menu System
# A recursive menu framework supporting rofi, yad, and GUI backends.
# Version: 1.0.0

set -euo pipefail

# 1. Global variables.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_STACK=()
DEBUG_MODE=0
BACKEND="auto"
L_PATH="${L_PATH:-$HOME/.local/share/molnios}"
ROFI_CONFIG=""

# Temporary state directory (cleared on reboot)
STATE_DIR="/tmp/molnios-menu-$$"
mkdir -p "$STATE_DIR"

# 2. Debug functions.
debug() {
    if [[ $DEBUG_MODE -eq 1 ]];then
        echo "[DEBUG] $*" >&2
    fi
}

debug_var() {
    if [[ $DEBUG_MODE -eq 1 ]];then
        local var_name="$1"
        echo "[DEBUG] $var_name = ${!var_name}" >&2
    fi
}

# 3. Detection of backends: ROFI, YAD & TUI (gum/fzf).
detect_backend() {
    if [[ "$BACKEND" != "auto" ]];then
        echo "$BACKEND"
        return
    fi

    if command -v rofi &>/dev/null;then
        echo "rofi"
    elif command -v yad &>/dev/null;then
        echo "yad"
    elif [[ -t 0 && -t 1 ]] && { command -v gum &>/dev/null || command -v fzf &>/dev/null;};then
        # Only auto-pick the terminal UI when we actually have a tty to draw
        # into (e.g. run by hand from a shell). A keybind-triggered launch
        # with no controlling terminal still falls through to "none" below
        # instead of hanging waiting for input nobody can see.
        echo "tui"
    else
        echo "none"
    fi
}

# 4. Shell window renderer.
shell_show_input() {
    local title="$1"
    local prompt="$2"
    local default="$3"

    local input_script="$STATE_DIR/input_dialog.sh"
    local output_file="$STATE_DIR/input_result.txt"

    # Write the interactive script with full color support
    cat > "$input_script" << 'SHELL_INPUT_EOF'
#!/usr/bin/env bash
title="$1"
prompt="$2"
default="$3"
output_file="$4"

# Gruvbox Dark – true color
GRV_BG="\033[48;2;40;40;40m"         # bg  #282828
GRV_RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# Foreground palette
FG="\033[38;2;235;219;178m"           # fg     #ebdbb2  – title text
YELLOW="\033[38;2;250;189;47m"        # yellow #fabd2f  – frame / borders
AQUA="\033[38;2;142;192;124m"         # aqua   #8ec07c  – prompt lines
ORANGE="\033[38;2;254;128;25m"        # orange #fe8019  – current value
GREEN="\033[38;2;184;187;38m"         # green  #b8bb26  – input caret
GRAY="\033[38;2;146;131;116m"         # gray   #928374  – "Current:" label

box_width=44

# ── title box ────────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}${BOLD}┌──────────────────────────────────────────────┐${GRV_RESET}"
printf "${YELLOW}${BOLD}│${GRV_RESET}  ${FG}${BOLD}%-44s${GRV_RESET}${YELLOW}${BOLD}│${GRV_RESET}\n" "$title"
echo -e "${YELLOW}${BOLD}└──────────────────────────────────────────────┘${GRV_RESET}"
echo ""

# ── prompt lines ─────────────────────────────────────────────────────────────
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        echo -e "  ${AQUA}${DIM}${line}${GRV_RESET}"
    else
        echo
    fi
done <<< "$prompt"

# ── current value ─────────────────────────────────────────────────────────────
echo ""
if [[ -n "$default" ]]; then
    echo -e "  ${GRAY}Current:${GRV_RESET}  ${ORANGE}${BOLD}${default}${GRV_RESET}"
    echo ""
fi

# ── input caret ───────────────────────────────────────────────────────────────
read -r -p "$(echo -e "  ${GREEN}${BOLD}❯${GRV_RESET} ")" -e -i "$default" user_input
printf '%s' "$user_input" > "$output_file"
SHELL_INPUT_EOF

    chmod +x "$input_script"
    rm -f "$output_file"

    local term_cmd=""
    if command -v wezterm&>/dev/null;then term_cmd="wezterm --config-file $L_PATH/config/wezterm/wezterm.lua start --class floating --"
    elif command -v kitty&>/dev/null;then term_cmd="kitty -c $L_PATH/config/kitty/kitty.conf --class floating -e"
    elif command -v ghostty&>/dev/null;then term_cmd="ghostty -e"
    elif command -v alacritty&>/dev/null;then term_cmd="alacritty -e"
    elif command -v xterm&>/dev/null;then term_cmd="xterm -e"
    fi

    if [[ -z "$term_cmd" ]];then
        bash "$input_script" "$title" "$prompt" "$default" "$output_file"
    else
        $term_cmd bash "$input_script" "$title" "$prompt" "$default" "$output_file"
        sleep .2
    fi

    if [[ -f "$output_file" ]];then
        cat "$output_file"
    else
        echo
    fi
}

# 5. rofi backend.
rofi_show_menu() {
    local title="$1"
    local prompt="$2"
    shift 2
    local options=("$@")

    debug "rofi_show_menu: title=$title, prompt=$prompt"
    debug "rofi_show_menu: options count=${#options[@]}"

    local rofi_config=""
    if [[ -n "$ROFI_CONFIG" ]];then
        # Use custom config if specified
        if [[ -f "$ROFI_CONFIG" ]];then
            rofi_config="-config $ROFI_CONFIG"
            debug "Using custom rofi config: $ROFI_CONFIG"
        else
            debug "WARNING: Custom rofi config not found: $ROFI_CONFIG"
        fi
    elif [[ -f $L_PATH/config/rofi-menu.rasi ]];then
        # Use default menu config
        rofi_config="-config $L_PATH/config/rofi-menu.rasi"
        debug "Using default rofi config: $L_PATH/config/rofi-menu.rasi"
    else
        rofi_config="-config ~/.config/rofi/config.rasi"
        debug "Using default rofi config: ~/.config/rofi/config.rasi"
    fi

    printf '%s\n' "${options[@]}" | rofi \
        -dmenu \
        -i \
        -p "$prompt" \
        -mesg "$title" \
        -no-custom \
        -format 'i' \
        $rofi_config 2>/dev/null || echo ""
}

rofi_show_input() {
    local title="$1"
    local prompt="$2"
    local default="$3"

    debug "rofi_show_input: title=$title, prompt=$prompt, default=$default"

    # Use shell input window for better input support
    shell_show_input "$title" "$prompt" "$default"
}

# 6. YAD backend.
yad_show_menu() {
    local title="$1"
    local prompt="$2"
    shift 2
    local options=("$@")

    debug "yad_show_menu: title='$title', prompt='$prompt'"
    debug "yad_show_menu: options count=${#options[@]}"

    if [[ $DEBUG_MODE -eq 1 ]];then
        for i in "${!options[@]}";do
            debug "  YAD Option $i: ${options[$i]}"
        done
    fi

    local yad_list=""
    for i in "${!options[@]}";do
        yad_list+="$i\n${options[$i]}\n"
    done

    debug "yad_show_menu: Calling yad with title='$title'"

    local result
    result=$(echo -e "$yad_list" | yad \
        --list \
        --title "$title" \
        --text "$prompt" \
        --column="Index:HD" \
        --column="Option" \
        --hide-column=1 \
        --no-headers \
        --width=500 \
        --height=400 \
        --center \
        --button="Cancel:1" \
        --button="Select:0" 2>/dev/null | cut -d'|' -f1 || echo "")

    echo "$result"
}

yad_show_input() {
    local title="$1"
    local prompt="$2"
    local default="$3"

    debug "yad_show_input: title=$title, prompt=$prompt, default=$default"

    yad \
        --entry \
        --title="$title" \
        --text="$prompt" \
        --entry-text="$default" \
        --width=400 \
        --center \
        --button="Cancel:1" \
        --button="OK:0" 2>/dev/null || echo ""
}

# 7. TUI backend (gum / fzf) — renders inline in the invoking terminal,
# unlike rofi/yad which pop up their own window. Picked with --backend tui
# or -t/--tui, and auto-selected when neither rofi nor yad is installed but
# we're actually attached to a tty (see detect_backend above).
tui_detect_tool() {
    if command -v gum &>/dev/null;then
        echo "gum"
    elif command -v fzf &>/dev/null;then
        echo "fzf"
    else
        echo "none"
    fi
}

# Gruvbox Dark accents — the same palette shell_show_input() uses above —
# so the TUI backend's picker/input box look at home next to that dialog.
TUI_YELLOW="#fabd2f"
TUI_ORANGE="#fe8019"
TUI_GREEN="#b8bb26"
TUI_GRAY="#928374"
TUI_FG="#ebdbb2"

tui_show_menu() {
    local title="$1"
    local prompt="$2"
    shift 2
    local options=("$@")

    debug "tui_show_menu: title=$title, prompt=$prompt"
    debug "tui_show_menu: options count=${#options[@]}"

    local tool
    tool=$(tui_detect_tool)

    case "$tool" in
        gum)
            # --label-delimiter shows the label but returns the value after
            # the delimiter, so we pair each label with its real index —
            # gum's equivalent of yad's --hide-column trick above.
            local -a labeled=()
            local i
            for i in "${!options[@]}";do
                labeled+=("${options[$i]}"$'\t'"${i}")
            done

            # gum's Bubble Tea UI renders to stderr by design (confirmed in
            # gum's own source: choose/command.go and input/command.go both
            # pass tea.WithOutput(os.Stderr)), specifically so stdout stays
            # clean for the captured result below. Redirecting stderr away
            # would silently discard the entire picker — it'd still be
            # running, just invisible, waiting on keys nobody can see to
            # press. So we only rely on the exit code here, not on 2>/dev/null.
            printf '%s\n' "${labeled[@]}" | gum choose \
                --label-delimiter=$'\t' \
                --header="${title}"$'\n'"${prompt}" \
                --height=20 \
                --cursor="❯ " \
                --header.foreground="$TUI_YELLOW" \
                --cursor.foreground="$TUI_GREEN" \
                --selected.foreground="$TUI_ORANGE" \
                || echo ""
            ;;
        fzf)
            # Same idea via a hidden tab-delimited field: --with-nth shows
            # only the label, but fzf still returns the whole original line.
            local -a indexed=()
            local i
            for i in "${!options[@]}";do
                indexed+=("${i}"$'\t'"${options[$i]}")
            done

            local line
            line=$(printf '%s\n' "${indexed[@]}" | fzf \
                --delimiter=$'\t' --with-nth=2 \
                --prompt="❯ " \
                --header="${title}"$'\n'"${prompt}" \
                --height="~90%" --layout=reverse --border=rounded \
                --color="fg:${TUI_FG},header:${TUI_GRAY},prompt:${TUI_GREEN},pointer:${TUI_ORANGE},hl:${TUI_YELLOW},hl+:${TUI_YELLOW},fg+:${TUI_FG}" \
                || echo "")

            echo "${line%%$'\t'*}"
            ;;
        *)
            echo "ERROR: tui backend requires gum or fzf to be installed" >&2
            echo ""
            ;;
    esac
}

tui_show_input() {
    local title="$1"
    local prompt="$2"
    local default="$3"

    debug "tui_show_input: title=$title, prompt=$prompt, default=$default"

    if command -v gum &>/dev/null;then
        # See the note in tui_show_menu()'s gum branch above: gum's UI
        # renders to stderr on purpose, so it must not be redirected away.
        gum input \
            --header="${title}"$'\n'"${prompt}" \
            --value="$default" \
            --prompt="❯ " \
            --width=70 \
            --header.foreground="$TUI_YELLOW" \
            --prompt.foreground="$TUI_GREEN" \
            --cursor.foreground="$TUI_GREEN" \
            || echo ""
    else
        # No gum: fall back to a plain readline prompt, since fzf has no
        # input-box widget of its own. Needs nothing but bash itself, so
        # this is also what runs if fzf is the only tool installed.
        # The decorative lines below are written to fd 2 (not fd 1), since
        # this function's stdout is captured by the caller as the result —
        # same reason debug()/notify() write to stderr elsewhere in this file.
        {
            echo ""
            echo -e "\033[1;33m${title}\033[0m"
            while IFS= read -r pline;do
                [[ -n "$pline" ]] && echo -e "  \033[2;36m${pline}\033[0m"
            done <<< "$prompt"
            echo ""
        } >&2
        local result
        read -r -e -i "$default" -p "$(echo -e '\033[1;32m❯\033[0m ')" result || result=""
        echo "$result"
    fi
}

# 8. Menu interface.
show_menu() {
    local title="$1"
    local prompt="$2"
    shift 2
    local options=("$@")

    local backend
    backend=$(detect_backend)

    debug "show_menu: backend=$backend"

    case "$backend" in
        rofi)
            rofi_show_menu "$title" "$prompt" "${options[@]}"
            ;;
        yad)
            yad_show_menu "$title" "$prompt" "${options[@]}"
            ;;
        tui)
            tui_show_menu "$title" "$prompt" "${options[@]}"
            ;;
        *)
            echo "ERROR: No supported backend found (rofi, yad, or tui)" >&2
            exit 1
            ;;
    esac
}

show_input() {
    local title="$1"
    local prompt="$2"
    local default="${3:-}"

    local backend
    backend=$(detect_backend)

    debug "show_input: backend=$backend"

    case "$backend" in
        rofi)
            rofi_show_input "$title" "$prompt" "$default"
            ;;
        yad)
            yad_show_input "$title" "$prompt" "$default"
            ;;
        tui)
            tui_show_input "$title" "$prompt" "$default"
            ;;
        *)
            echo "ERROR: No supported backend found (rofi, yad, or tui)" >&2
            exit 1
            ;;
    esac
}

# ============================================================================
# MENU STACK MANAGEMENT
# ============================================================================

push_menu() {
    local menu_id="$1"
    MENU_STACK+=("$menu_id")
    debug "push_menu: $menu_id (stack size: ${#MENU_STACK[@]})"
}

pop_menu() {
    if [[ ${#MENU_STACK[@]} -gt 0 ]];then
        unset 'MENU_STACK[-1]'
        debug "pop_menu: (stack size: ${#MENU_STACK[@]})"
    fi
}

get_current_menu() {
    if [[ ${#MENU_STACK[@]} -gt 0 ]];then
        echo "${MENU_STACK[-1]}"
    else
        echo ""
    fi
}

# ============================================================================
# MENU EXECUTION ENGINE
# ============================================================================

execute_action() {
    local action="$1"
    shift
    local args=("$@")

    debug "execute_action: $action ${args[*]}"

    case "$action" in
        cmd)
            eval "${args[@]}"
            ;;
        menu)
            show_menu_by_id "${args[0]}"
            ;;
        script)
            bash -c "${args[@]}"
            ;;
        *)
            debug "Unknown action: $action"
            ;;
    esac
}

# ============================================================================
# MENU DEFINITION PARSER
# ============================================================================

declare -A MENU_TITLES
declare -A MENU_PROMPTS
declare -A MENU_OPTIONS
declare -A MENU_ACTIONS

register_menu() {
    local menu_id="$1"
    local title="$2"
    local prompt="$3"
    shift 3

    MENU_TITLES["$menu_id"]="$title"
    MENU_PROMPTS["$menu_id"]="$prompt"

    local options=()
    local actions=()

    while [[ $# -gt 0 ]];do
        options+=("$1")
        actions+=("$2")
        shift 2
    done

    # Use a unique delimiter that won't appear in menu text
    # Using ASCII Record Separator (0x1E) instead of Unit Separator
    local delimiter=$'\x1E'
    local old_ifs="$IFS"
    IFS="$delimiter"
    MENU_OPTIONS["$menu_id"]="${options[*]}"
    MENU_ACTIONS["$menu_id"]="${actions[*]}"
    IFS="$old_ifs"

    debug "register_menu: $menu_id with ${#options[@]} options"
    if [[ $DEBUG_MODE -eq 1 ]];then
        debug "  Title: $title"
        debug "  Prompt: $prompt"
        for i in "${!options[@]}";do
            debug "  Registering option $i: '${options[$i]}' -> '${actions[$i]}'"
        done
    fi
}

show_menu_by_id() {
    local menu_id="$1"

    debug "show_menu_by_id: $menu_id"

    if [[ -z "${MENU_TITLES[$menu_id]:-}" ]];then
        debug "Menu not found: $menu_id"
        return 1
    fi

    push_menu "$menu_id"

    local title="${MENU_TITLES[$menu_id]}"
    local prompt="${MENU_PROMPTS[$menu_id]}"

    debug "Menu title: $title"
    debug "Menu prompt: $prompt"
    debug "Raw options string: ${MENU_OPTIONS[$menu_id]}"
    debug "Raw actions string: ${MENU_ACTIONS[$menu_id]}"

    # Parse options and actions using unique delimiter
    local -a options
    local -a actions
    local delimiter=$'\x1E'  # ASCII Record Separator (changed from Unit Separator)

    # Use mapfile for more reliable parsing
    local old_ifs="$IFS"
    IFS="$delimiter"
    read -ra options <<< "${MENU_OPTIONS[$menu_id]}"
    read -ra actions <<< "${MENU_ACTIONS[$menu_id]}"
    IFS="$old_ifs"

    debug "Parsed ${#options[@]} options and ${#actions[@]} actions"
    if [[ $DEBUG_MODE -eq 1 ]];then
        for i in "${!options[@]}";do
            debug "  Option $i: '${options[$i]}' -> '${actions[$i]}'"
        done
    fi

    # Verify arrays have same length
    if [[ ${#options[@]} -ne ${#actions[@]} ]];then
        debug "ERROR: Options and actions arrays have different lengths!"
        debug "  Options: ${#options[@]}, Actions: ${#actions[@]}"
        pop_menu
        return 1
    fi

    # Add back button if not root menu
    if [[ ${#MENU_STACK[@]} -gt 1 ]];then
        options=("← Back" "${options[@]}")
        actions=("back" "${actions[@]}")
        debug "Added back button (stack size: ${#MENU_STACK[@]})"
    fi

    while true;do
        local selection
        selection=$(show_menu "$title" "$prompt" "${options[@]}")

        debug "Selection: $selection"

        if [[ -z "$selection" ]];then
            # User cancelled
            pop_menu
            return 0
        fi

        local action="${actions[$selection]}"

        if [[ "$action" == "back" ]];then
            pop_menu
            return 0
        fi

        # Parse and execute action
        local action_type="${action%%:*}"
        local action_data="${action#*:}"

        case "$action_type" in
            menu)
                show_menu_by_id "$action_data"
                # After returning from submenu, continue showing this menu
                ;;
            cmd)
                execute_action "cmd" "$action_data"
                # After executing command, exit this menu
                pop_menu
                return 0
                ;;
            script)
                execute_action "script" "$action_data"
                # After executing script, exit this menu
                pop_menu
                return 0
                ;;
            *)
                debug "Unknown action type: $action_type"
                ;;
        esac
    done
}

# ============================================================================
# PRESET LOADER
# ============================================================================

load_preset() {
    local preset_file="$1"

    debug "load_preset: $preset_file"

    if [[ ! -f "$preset_file" ]];then
        echo "ERROR: Preset file not found: $preset_file" >&2
        exit 1
    fi

    source "$preset_file"
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

show_help() {
    cat << EOF
MolniOS Menu System

Usage: $0 [OPTIONS]

OPTIONS:
    -p, --preset FILE       Load menu preset from FILE
    -b, --backend BACKEND   Force backend (rofi, yad, tui, auto)
    -r, --rofi-config FILE  Custom rofi config file path
    -d, --debug             Enable debug mode
    -h, --help              Show this help message

BACKENDS:
    rofi    - Use rofi for menu display
    yad     - Use yad for menu display
    tui     - Use a terminal UI (gum, falling back to fzf) in this terminal
    auto    - Auto-detect available backend (default)

EXAMPLES:
    $0 --preset main-menu.sh
    $0 --preset main-menu.sh --backend rofi --debug
    $0 -p main-menu.sh -b yad -d
    $0 -p main-menu.sh -b tui
    $0 -p main-menu.sh -r ~/.config/rofi/custom.rasi

EOF
}

main() {
    local preset_file=""

    while [[ $# -gt 0 ]];do
        case "$1" in
            -p|--preset)
                preset_file="$2"
                shift 2
                ;;
            -b|--backend)
                BACKEND="$2"
                shift 2
                ;;
            -r|--rofi-config)
                ROFI_CONFIG="$2"
                shift 2
                ;;
            -d|--debug)
                DEBUG_MODE=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done

    if [[ -z "$preset_file" ]];then
        echo "ERROR: No preset file specified" >&2
        show_help
        exit 1
    fi

    debug "Starting MolniOS Menu System"
    debug_var "BACKEND"
    debug_var "DEBUG_MODE"
    debug_var "preset_file"

    # Check backend availability
    local detected_backend
    detected_backend=$(detect_backend)

    if [[ "$detected_backend" == "none" ]];then
        echo "ERROR: No supported backend found. Please install rofi, yad, or a terminal picker (gum/fzf)." >&2
        exit 1
    fi

    debug "Detected backend: $detected_backend"

    # Load preset
    load_preset "$preset_file"

    # Start main menu
    show_menu_by_id "main"

    # Cleanup
    rm -rf "$STATE_DIR"
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]];then
    main "$@"
fi