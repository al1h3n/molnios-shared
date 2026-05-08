# Scale 1 is used to fix pixelated look in applications and games.

ACTIVE_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = 1 ] ; then
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword animation borderangle,0; \
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
	    keyword decoration:fullscreen_opacity 1;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0;\
        keyword monitor $ACTIVE_MONITOR,highres@highrr,auto,1"
    hyprctl notify 1 3000 "rgb(40a02b)" " Gamemode [ON]"
    exit
else
    hyprctl notify 1 3000 "rgb(d20f39)" " Gamemode [OFF]"
    hyprctl reload
    sh ~/.local/share/molnios/scripts/borderline.sh
    exit 0
fi
