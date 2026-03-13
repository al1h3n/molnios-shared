# ==========================================================
# path.sh - Universal path resolver for Molniux/MolnixOS
# Usage: path.sh <key>
# ==========================================================

# Detect OS
BASE=$SHARED_PATH
MEDIA=$SHARED_MEDIA_PATH

case "$1" in
    base)       echo "$BASE" ;;
    media)      echo "$MEDIA" ;;
    scripts)    echo "$BASE/scripts" ;;
    config)     echo "$BASE/config" ;;
    cursors)    echo "$BASE/cursors" ;;
    icons)      echo "$BASE/icons" ;;
    wallpapers) echo "$MEDIA/wallpapers" ;;
    hyprland)   echo "$BASE/config/hyprconfig" ;;
    hyprlock)   echo "$BASE/config/hyprlock" ;;
    rofi)       echo "$BASE/config/rofi" ;;
    kitty)      echo "$BASE/config/kitty" ;;
    dunst)      echo "$BASE/config/dunst" ;;
    waybar)     echo "$BASE/config/waybar" ;;
    zsh)        echo "$BASE/.zshrc" ;;
    zsh_theme)  echo "$BASE/.p10k.zsh" ;;
    *)
                echo "Unknown key: $1" >&2
                echo "Available: base, media, scripts, config, cursors, icons, wallpapers, hyprland, hyprlock, rofi, kitty, dunst, waybar, zsh, zsh_theme" >&2
                exit 1 ;;
esac