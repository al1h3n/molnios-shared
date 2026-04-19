$MENU="menu.sh"

sh $MENU
-c "$CONF" \
-t "🖼 Wallpaper" \
-d "$HOME/Pictures/wallpapers" \
-f "jpg,jpeg,png,webp" \
--strip-ext \
-e "feh --no-fehbg --bg-fill"