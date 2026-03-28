declare -A LANGS=(
    ["English"]="eng"
    ["Russian"]="rus"
    # ["Chinese (Simplified)"]="chi_sim"
    # ["Chinese (Traditional)"]="chi_tra"
    # ["Spanish"]="spa"
)

CHOICE=$(printf '%s\n' "${!LANGS[@]}" | sort | rofi -dmenu -p "OCR language:")
[[ -z "$CHOICE" ]] && exit 0

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
bash "$SCRIPT_DIR/ocr-region.sh" --lang "${LANGS[$CHOICE]}"