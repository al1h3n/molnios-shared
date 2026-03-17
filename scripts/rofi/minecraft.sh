# ==========================================================
# Minecraftsfx al1h3n edition - v1
# Rofi soundtheme. Location: ~/.local/bin
# ==========================================================

DIR=~/.local/share/molnios/sfx/minecraft
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

if [ "$1" = "error" ];then
    pw-play --volume 1.2 $DIR/toast.ogx &
elif [ "$1" = "tap" ];then
    pw-play --volume .5 $DIR/click.ogx &
elif [ "$1" = "enter" ];then
    pw-play --volume 2 $DIR/in.ogx &
elif [ "$1" = "tab" ];then
    pw-play $DIR/release.ogx &
elif [ "$1" = "exit" ];then
    pw-play --volume 2 $DIR/out.ogx &
else
    notify-send -u critical "Rofi error:" "Incorrect sound call."
fi