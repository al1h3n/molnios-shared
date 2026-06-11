#!/bin/sh

set -a

l_path=$L_PATH
conf=$L_PATH/config
scripts=$L_PATH/scripts

shell=sh
terminal="kitty -c $conf/kitty/kitty.conf"
terminal_wez="wezterm --config-file $conf/wezterm/wezterm.lua"
multiterminal="$terminal zellij -c $conf/zellij/config.kdl"

# Rofi.
rofi_noicons="-no-show-icons -theme-str 'listview{columns: 1;}'"
rofi_icons="-show-icons"
menuid=rofi

if grep -q "ID=nixos" /etc/os-release 2>/dev/null; then
    menuconfig=""
else
    menuconfig="-config $conf/rofi"
fi

menu="$menuid $menuconfig -show"
appmenu="$menu drun $rofi_icons"
emojimenu="$menu emoji $rofi_noicons"
commandmenu="$menu run $rofi_noicons"
switchmenu="$menu window $rofi_icons"
youtube="yt-x -s -l rofi --rofi-theme-main $menuconfig"

# Utilities & System Scripts
switcher="snappy-switcher"
switcherdaemon="$switcher --daemon -c $conf/snappy.ini"

gpu="$shell $scripts/gpu.sh"
temp="$shell $scripts/temp.sh"
reload="$shell $scripts/reloadus.sh"
gamemode="$shell $scripts/gamemode.sh"
eyedropper="ie-r"
actionmenu="wlogout -nl $conf/wlogout/layout -C $conf/wlogout/wlogout.css"

# Clipboard
clipman="$shell $scripts/clipboard-images.sh"
cliptext="wl-paste --type text --watch cliphist store"
clipmage="wl-paste --type image --watch cliphist store"
clipsave="wl-clip-persist --clipboard regular"

# Screenshots, Recording, & OCR
screenshot='grim -g "$(slurp -b 000000CC -s FFFFFF00 -c 00FF00 -w 1)" - | tee $(xdg-user-dir PICTURES)/Screenshots/screenshot_$(date +%Y-%m-%d_%H:%M:%S).png | wl-copy'
screenshot_clip_hyprshot="sh -c 'hyprshot -m region --raw | satty --filename -'"
record="$shell $scripts/record.sh"
ocr="$shell $scripts/ocr-select.sh"
ocr_simple='grim -g "$(slurp -b 000000CC -s FFFFFF00 -c 00FF00 -w 1)" - | tesseract stdin stdout | wl-copy'

# Daemons & Background Services
permissions="polkit-gnome-authentication-agent-1"
hyprpermissions="hyprpolkitagent"
network="nm-applet"
bluetooth="blueman-applet"
bar="waybar -c $conf/waybar/config-niri.jsonc -s $conf/waybar/style.css" # Pointed to your niri config
qbar="qs"
notify="swaync -c $conf/swaync/swaync.json -s $conf/swaync/swaync-style.css"
lock="hyprlock -q -c $conf/hypr/hyprlock.conf"

# Appearance
wallpaperengine="waypaper"
wallpaper="$wallpaperengine --restore"
idlewallpaper="mpvpaper-stop"
borders="$shell $scripts/colors/borderline.sh"

# General Applications
explorer="thunar"
explorercli="$terminal yazi"
editor="$terminal nvim"
player="mpv --keep-open --player-operation-mode=pseudo-gui --force-window --volume-max=200"
blueman="blueman-manager"
netman="nm-connection-editor"
vmanager="virt-manager"

# Electron / Web App Wrappers
browser="$shell $scripts/electron.sh browser"
discord="$shell $scripts/electron.sh discord"
notes="$shell $scripts/electron.sh notes"
coder="$shell $scripts/electron.sh coder"
musicplayer="$shell $scripts/electron.sh spotify"
telegram="$shell $scripts/telegram.sh"

set +a

# Execute whatever argument is passed to this script.
eval "$@"