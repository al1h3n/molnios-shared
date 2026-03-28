#!/bin/bash

# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - ko-fi.com/al1h3n
# borderline v1.1 - added kitty accent colors (not fully).
# Used to get 2 main colors of theme for Hyprland dynamically.
# Part of the MolniOS project.
# ==============================================================================

if [ -f /etc/profiles/per-user/"$(whoami)"/etc/profile.d/hm-session-vars.sh ]; then
    . /etc/profiles/per-user/"$(whoami)"/etc/profile.d/hm-session-vars.sh
fi
[ -f ~/.nix-profile/etc/profile.d/nix.sh ] && . ~/.nix-profile/etc/profile.d/nix.sh
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# 0. Dependencies.
for cmd in grep cut xargs file magick hyprctl kitty ffmpeg;do
    if ! command -v $cmd &> /dev/null;then
        notify-send -u critical Borderline "Missing dependency: $cmd"
        exit 1
    fi
done

# 1. Get the current wallpaper path.
# Waypaper updates its config file before running the post-command.
CONFIG_FILE=~/.config/waypaper/config.ini
WALLPAPER=$(grep "^wallpaper = " "$CONFIG_FILE" | cut -d= -f2- | xargs)

if [ ! -f "$CONFIG_FILE" ];then
    notify-send -u critical Borderline "Waypaper config not found."
    exit 1
fi

# Fallback if argument is passed directly.
if [ -n "$1" ];then
    WALLPAPER=$1
fi

if [ -z "$WALLPAPER" ];then
    notify-send -u critical Borderline "No wallpaper path found."
    exit 1
fi

if [ ! -f "$WALLPAPER" ];then
    notify-send -u critical Borderline "Wallpaper file does not exist: $WALLPAPER"
    exit 1
fi

# 2. Extract colors.
# If it's a video (mpvpaper), extract the first frame.
# If it's an image, use it directly.
IS_VIDEO=$(file --mime-type -b "$WALLPAPER" | grep video)

if [ -n "$IS_VIDEO" ];then
    # Extract frame from video
    # -vframes 1: get 1 frame
    # -f image2pipe: pipe output to magick
    CMD="ffmpeg -i \"$WALLPAPER\" -y -vframes 1 -f image2pipe -v quiet - | magick -"
else
    # Standard image
    CMD="magick \"$WALLPAPER\""
fi

# 3. Get dominant colors using ImageMagick.
# -resize -> Speed up processing.
# -colors 2 -> Quantize to 2 dominant colors.
# format "%c" -> Output histogram count.
hex_colors=$(eval "$CMD -resize 160x90! +dither -colors 2 -define histogram:unique-colors=true -format '%c\n' histogram:info:" | \
sed -n 's/.*\(#[0-9A-Fa-f]\{6\}\).*/\1/p' | head -n 2)

# Read into variables.
color1=$(echo "$hex_colors" | sed -n '1p')
color2=$(echo "$hex_colors" | sed -n '2p')

# Fallback if image is monochrome (only 1 color found).
if [ -z "$color2" ]; then
    color2=$color1
fi

# 4. Update Hyprland borders.
# We convert HEX RGB to HEX RGBA.
hyprctl keyword general:col.active_border "rgba(${color1:1}ff) rgba(${color2:1}ff) 45deg"

# 5. Update Kitty terminal elements. (seems not to work properly).
KITTY_TEMP="/tmp/kitty_borderline_theme.conf"
cat <<EOF > "$KITTY_TEMP"
cursor=$color1
cursor_text_color=$color2
active_border_color=$color1
inactive_border_color=$color2
bell_border_color=$color1
active_tab_foreground=$color2
active_tab_background=$color1
inactive_tab_foreground=$color1
inactive_tab_background=$color2
url_color=$color1
selection_foreground=$color2
selection_background=$color1
EOF

# Enable nullglob to safely handle missing sockets
shopt -s nullglob
sockets=(borderline-*)

# If no sockets found, we are done (Hyprland is already updated)
if [ ${#sockets[@]} -eq 0 ]; then
    notify-send -u low "Borderline" "Theme applied (Hyprland only - No Kitty open)"
    exit 0
fi

# Apply to all found Kitty instances
for socket in "${sockets[@]}"; do
    if [ -S "$socket" ]; then
        # Point set-colors to the temp file
        kitty @ --to "unix:@$socket" set-colors -a "$KITTY_TEMP" &>/dev/null
    fi
done

notify-send -u low "Borderline" "Theme applied ($color1 / $color2)"
