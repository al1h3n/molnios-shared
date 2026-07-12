#!/usr/bin/env bash
# MolniOS Main Menu Launcher
# Quick launcher script for the main menu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_SCRIPT="$SCRIPT_DIR/molnios-menu.sh"
PRESET_FILE="$SCRIPT_DIR/custom/main-menu-preset.sh"

# Default backend (auto-detect)
BACKEND="auto"
DEBUG=0
# ROFI_CONFIG=/home/al1h3n/repo/molnios-shared/config/rofi-menu.rasi

# Parse arguments
while [[ $# -gt 0 ]]; do
case "$1" in
-r|--rofi)
BACKEND="rofi"
shift
;;
-y|--yad)
BACKEND="yad"
shift
;;
-t|--tui)
BACKEND="tui"
shift
;;
-c|--rofi-config)
ROFI_CONFIG="$2"
shift 2
;;
-d|--debug)
DEBUG=1
shift
;;
-h|--help)
cat << EOF
MolniOS Main Menu Launcher
Usage: $0 [OPTIONS]
OPTIONS:
    -r, --rofi              Force rofi backend
    -y, --yad               Force yad backend
    -t, --tui               Force terminal UI backend (gum, falling back to fzf)
    -c, --rofi-config FILE  Custom rofi config file path
    -d, --debug             Enable debug mode
    -h, --help              Show this help
EXAMPLES:
$0                      # Auto-detect backend
$0 --rofi               # Use rofi
$0 --yad -d             # Use yad with debug
$0 --tui                # Use terminal UI (gum/fzf), in this terminal
$0 -c ~/.config/rofi/custom.rasi  # Use custom rofi config
EOF
exit 0
;;
*)
echo "Unknown option: $1"
exit 1
;;
esac
done

# Build command
CMD="$MENU_SCRIPT --preset $PRESET_FILE --backend $BACKEND"
if [[ $DEBUG -eq 1 ]]; then
CMD="$CMD --debug"
fi
if [[ -n "$ROFI_CONFIG" ]]; then
CMD="$CMD --rofi-config \"$ROFI_CONFIG\""
fi

# Execute
exec bash -c "$CMD"