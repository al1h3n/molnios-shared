#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/molnios-menu.sh"
trap 'rm -rf "$STATE_DIR"' EXIT

yad() {
    if [[ " $* " == *' --entry '* ]];then
        [[ " $* " == *$'Scale\nDefault'* ]]
        printf '1.25\n'
        return
    fi
    local -a rows
    mapfile -t rows
    [[ ${rows[3]} == '󰚥 Power Options' ]]
    [[ ${rows[5]} == '󰏘 Themes &amp; Colors' ]]
    [[ " $* " == *' --print-column=1 '* ]]
    [[ " $* " == *$'Choose\ncategory'* ]]
    printf '2|\n'
}

BACKEND=yad
[[ $(show_menu 'Main' 'Choose\ncategory' '󰌘 Connection' '󰚥 Power Options' '󰏘 Themes & Colors') == 2 ]]
INPUT_BACKEND=yad
[[ $(show_input 'Scale' 'Scale\nDefault' 1) == 1.25 ]]
BACKEND=rofi
rofi_show_menu() { [[ $2 == $'Choose\ncategory' ]] && printf '2\n'; }
[[ $(show_menu 'Main' 'Choose\ncategory' '󰌘 Connection' '󰚥 Power Options' '󰏘 Themes & Colors') == 2 ]]
BACKEND=tui
tui_show_menu() { [[ $2 == $'Choose\ncategory' ]] && printf '2\n'; }
[[ $(show_menu 'Main' 'Choose\ncategory' '󰌘 Connection' '󰚥 Power Options' '󰏘 Themes & Colors') == 2 ]]
printf 'YAD menu: OK\n'
