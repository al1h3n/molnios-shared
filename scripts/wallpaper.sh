# Check if mpvpaper is running
if pgrep -x mpvpaper > /dev/null;then
    pkill -x mpvpaper
else
    # If not running, restore last used wallpaper via waypaper (turn on)
    waypaper --restore
fi
