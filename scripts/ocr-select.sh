#!/usr/bin/env bash
declare -A LANGS=(
    ["English"]="eng"
    ["Russian"]="rus"
    # ["Chinese (Simplified)"]="chi_sim"
    # ["Chinese (Traditional)"]="chi_tra"
    # ["Spanish"]="spa"
)

CHOICE=$(printf '%s\n' "${!LANGS[@]}" | sort | rofi -dmenu -p "OCR language:")
[[ -z "$CHOICE" ]] && exit 0

sh ~/.local/share/molnios/scripts/ocr-region.sh --lang "${LANGS[$CHOICE]}"