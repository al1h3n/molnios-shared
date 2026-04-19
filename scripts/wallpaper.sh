$MENU=~/.local/share/molnios/scripts/menu/menu.sh
$CONF=~/.local/share/molnios/scripts/menu/style.conf

reload(){
    if pgrep -x mpvpaper > /dev/null;then
    pkill -x mpvpaper
elif pgrep -x swww > /dev/null;then
    pkill -x swww
elif pgrep -x awww > /dev/null;then
    pkill -x awww
else
    waypaper --restore
fi
}

# TODO: make it gather theme colors from borderline.
change(){
    sh $MENU
    -c "$CONF" \
    -t "Select Wallpaper" \
    -d "$HOME/Pictures/wallpapers" \
    -f "jpg,jpeg,png,webp" \
    --strip-ext \
    -e "feh --no-fehbg --bg-fill"
}

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