-- Global paths and command definitions.
-- Dynamically check for NixOS (evaluated once at launch).
local os_release = io.open("/etc/os-release", "r")
local is_nixos = os_release and os_release:read("*a"):match("ID=nixos")
if os_release then os_release:close() end

-- Terminal.
_G.shell = "sh "
_G.terminal_wez = "wezterm --config-file " .. conf .. "wezterm/wezterm.lua "
_G.terminal = "kitty -c " .. conf .. "kitty/kitty.conf "
_G.multiterminal = terminal .. "zellij -c " .. conf .. "zellij/config.kdl"

-- Flags.
local noicons = "-no-show-icons -theme-str 'listview{columns: 1;}'"
local icons = "-show-icons"

-- Utilities

-- Rofi.
_G.menuid = "rofi"
local menuconfig = is_nixos and "" or ("-config " .. conf .. "rofi")
_G.menu = menuid .. " " .. menuconfig .. " -show"
_G.appmenu = menu .. " drun " .. icons
_G.emojimenu = menu .. " emoji " .. noicons
_G.commandmenu = menu .. " run " .. noicons
_G.switchmenu = menu .. " window " .. icons

_G.youtube = "yt-x -s " .. icons
_G.switcher = "snappy-switcher" -- Works only on hyprland.
_G.switcherdaemon = switcher .. " --daemon -c " .. conf .. "snappy.ini"

_G.gpu = shell .. scripts .. "gpu.sh"
_G.temp = shell .. scripts .. "temp.sh"
_G.reload = shell .. scripts .. "reloadus.sh"
_G.gamemode = shell .. scripts .. "gamemode.sh"

_G.eyedropper = "ie-r"
_G.actionmenu = "wlogout -nl " .. conf .. "wlogout/layout -C " .. conf .. "wlogout/wlogout.css"

_G.clipman = shell .. scripts .. "clipboard-images.sh"
_G.cliptext = "wl-paste --type text --watch cliphist store"
_G.clipmage = "wl-paste --type image --watch cliphist store"
_G.clipsave = "wl-clip-persist --clipboard regular"

_G.screenshot = [[sh -c 'grim -g "$(slurp -b 000000CC -s FFFFFF00 -c 00FF00 -w 1)" - | tee $(xdg-user-dir PICTURES)/Screenshots/screenshot_$(date +%Y-%m-%d_%H:%M:%S).png | wl-copy']]
_G.screenshot_clip_hyprshot = [[sh -c 'hyprshot -m region --raw | satty --filename -']]
_G.record = shell .. scripts .. "record.sh"
_G.ocr = shell .. scripts .. "ocr-select.sh"
_G.ocr_simple = [[sh -c 'grim -g "$(slurp -b 000000CC -s FFFFFF00 -c 00FF00 -w 1)" - | tesseract stdin stdout | wl-copy']]

_G.permissions = "polkit-gnome-authentication-agent-1"
_G.hyprpermissions = "hyprpolkitagent"
_G.network = "nm-applet"
_G.bluetooth = "blueman-applet"
_G.bar = "waybar -c " .. conf .. "waybar/config-hypr.jsonc -s " .. conf .. "waybar/style.css"
_G.qbar = "qs"
_G.notify = "swaync -c " .. conf .. "swaync/swaync.json -s " .. conf .. "swaync/swaync-style.css"
_G.lock = "hyprlock -q -c " .. conf .. "hypr/hyprlock.conf"

_G.wallpaperengine = "waypaper"
_G.wallpaper = wallpaperengine .. " --restore"
_G.idlewallpaper = "mpvpaper-stop"
_G.borders = shell .. scripts .. "borderline.sh"

_G.explorer = "thunar"
_G.explorercli = terminal .. "yazi"
_G.editor = terminal .. "nvim"
_G.player = "mpv --keep-open --player-operation-mode=pseudo-gui --force-window --volume-max=200"
_G.blueman = "blueman-manager"
_G.netman = "nm-connection-editor"
_G.vmanager = "virt-manager"

_G.browser = shell .. scripts .. "electron.sh browser"
_G.discord = shell .. scripts .. "electron.sh discord"
_G.notes = shell .. scripts .. "electron.sh notes"
_G.coder = shell .. scripts .. "electron.sh coder"
_G.musicplayer = shell .. scripts .. "electron.sh spotify"
_G.telegram = shell .. scripts .. "telegram.sh"