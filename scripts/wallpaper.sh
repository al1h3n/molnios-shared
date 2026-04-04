if pgrep -x mpvpaper > /dev/null;then
    pkill -x mpvpaper
elif pgrep -x swww > /dev/null;then
    pkill -x swww
elif pgrep -x awww > /dev/null;then
    pkill -x awww
else
    waypaper --restore
fi
