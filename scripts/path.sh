# ==========================================================
# path.sh - Universal path resolver for Molniux/MolnixOS
# Usage: path.sh <key>
# ==========================================================

# Will be deprecated in future.

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
    hyprland)   echo "$BASE/config/hyprland/hyprland.lua" ;;
    hyprlock)   echo "$BASE/config/hypr/hyprlock.conf" ;;
    rofi)       echo "$BASE/config/rofi.rasi" ;;
    kitty)      echo "$BASE/config/kitty/kitty.conf" ;;
    dunst)      echo "$BASE/config/dunst.ini" ;;
    waybar)     echo "$BASE/config/waybar" ;;
    zsh)        echo "$BASE/config/zsh/.zshrc" ;;
    zsh_theme)  echo "$BASE/config/zsh/.p10k.zsh" ;;
    fish)       echo "$BASE/config/fish/config.fish" ;;
    *)
                echo "Unknown key: $1" >&2
                echo "Available: base, media, scripts, config, cursors, icons, wallpapers, hyprland, hyprlock, rofi, kitty, dunst, waybar, zsh, zsh_theme, fish" >&2
                exit 1 ;;
esac