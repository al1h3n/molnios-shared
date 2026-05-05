# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - ko-fi.com/al1h3n
# borderline v1.2 - Niri support.
# Used to get 2 main colors of theme for Hyprland/Niri dynamically.
# Part of the MolniOS project.
# ==============================================================================

if [ -f /etc/profiles/per-user/"$(whoami)"/etc/profile.d/hm-session-vars.sh ]; then
    . /etc/profiles/per-user/"$(whoami)"/etc/profile.d/hm-session-vars.sh
fi
[ -f ~/.nix-profile/etc/profile.d/nix.sh ] && . ~/.nix-profile/etc/profile.d/nix.sh
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# Arguments handling.
while getopts "r:c" opt;do
  case $opt in
  	r)
      reload
      ;;
    c)
      change $@
      ;;
    \?)
      echo "Invalid option: -$OPTARG">&2
      exit 1
      ;;
  esac
done

# 0. Dependencies.
for cmd in grep cut xargs file magick hyprctl kitty ffmpeg;do
    if ! command -v $cmd &> /dev/null;then
        notify-send -u critical Borderline "Missing dependency: $cmd"
        exit 1
    fi
done

# 1. Detect running compositors.
HYPRLAND_RUNNING=false
NIRI_RUNNING=false

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && command -v hyprctl &>/dev/null; then
    hyprctl version &>/dev/null && HYPRLAND_RUNNING=true
fi

# Niri socket lives at $XDG_RUNTIME_DIR/niri/socket.
# niri msg will exit non-zero if the socket is absent.
if command -v niri &>/dev/null && niri msg version &>/dev/null 2>&1; then
    NIRI_RUNNING=true
fi

if ! $HYPRLAND_RUNNING && ! $NIRI_RUNNING; then
    notify-send -u critical Borderline "No supported compositor found (Hyprland or Niri)."
    exit 1
fi

# 2. Get the current wallpaper path.
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

# 3. Extract colors.
# If it's a video (mpvpaper), extract the first frame.
# If it's an image, use it directly.
IS_VIDEO=$(file --mime-type -b "$WALLPAPER" | grep video)

if [ -n "$IS_VIDEO" ];then
    # Extract frame from video
    # -vframes 1: get 1 frame
    # -f image2pipe: pipe output to magick
    TMPFRAME=$(mktemp /tmp/borderline_XXXXXX.png)
    ffmpeg -i "$WALLPAPER" -y -vframes 1 -v quiet "$TMPFRAME"
    MAGICK_SOURCE="$TMPFRAME"
else
    # Standard image
    MAGICK_SOURCE="$WALLPAPER"
fi

# 4. Get dominant colors using ImageMagick.
# -resize -> Speed up processing.
# -colors 2 -> Quantize to 2 dominant colors.
hex_colors=$(magick "$MAGICK_SOURCE" -resize 160x90! +dither -colors 2 -unique-colors txt:- 2>/dev/null | \
    grep -oE '#[0-9A-Fa-f]{6}' | head -n 2)

# Read into variables.
color1=$(echo "$hex_colors" | sed -n '1p')
color2=$(echo "$hex_colors" | sed -n '2p')

# Fallback if image is monochrome (only 1 color found).
if [ -z "$color2" ]; then
    color2=$color1
fi

# 5. Apply borders per compositor.

# 5.1. Hyprland.
if $HYPRLAND_RUNNING; then
    hyprctl keyword general:col.active_border "rgba(${color1:1}FF) rgba(${color2:1}FF) 45deg"
fi

# 5.2. Niri.
# Strategy: sed-replace the active-color / inactive-color lines inside the
# focus-ring block in the niri config, then reload the config.
# Expects lines of the form (with any leading whitespace):
#   active-color   "#RRGGBB"
#   inactive-color "#RRGGBB"
# Lines must exist in the config already; borderline will not insert them.
# Niri doesn't support dynamic border animations.
if $NIRI_RUNNING; then
    NIRI_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/niri/config.kdl"

    if [ ! -f "$NIRI_CONFIG" ]; then
        notify-send -u critical Borderline "Niri config not found: $NIRI_CONFIG"
    else
        niri_c1="${color1}FF"
        niri_c2="${color2}FF"
        sed -i \
            -E "s|^(\s*)(active-color\|active-gradient)\s+.*|\1active-gradient from=\"${niri_c1}\" to=\"${niri_c2}\" angle=45|" \
            "$NIRI_CONFIG"
            
        # Keep inactive-color behavior intact
        sed -i \
            -E "s|^(\s*inactive-color\s+)\"#[0-9A-Fa-f]{6,8}\"|\1\"${niri_c2}\"|" \
            "$NIRI_CONFIG"
        niri msg action reload-config
    fi
fi


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
sockets=("$XDG_RUNTIME_DIR"/kitty/borderline-*)


# If no sockets found, we are done (already updated)
if [ ${#sockets[@]} -eq 0 ]; then
    _compositors=""
    $HYPRLAND_RUNNING && _compositors="Hyprland"
    $NIRI_RUNNING && _compositors="${_compositors:+$_compositors + }Niri"
    notify-send -u low "Borderline" "Theme applied via ${_compositors} (no Kitty open)\n$color1 / $color2"
    exit 0
fi

# Apply to all found Kitty instances
for socket in "${sockets[@]}"; do
    if [ -S "$socket" ]; then
        # Point set-colors to the temp file
        kitty @ --to "unix:@$socket" set-colors -a "$KITTY_TEMP" &>/dev/null
    fi
done


_compositors=""
$HYPRLAND_RUNNING && _compositors="Hyprland"
$NIRI_RUNNING && _compositors="${_compositors:+$_compositors + }Niri"
notify-send -u low "Borderline" "Theme applied via ${_compositors}\n$color1 / $color2"