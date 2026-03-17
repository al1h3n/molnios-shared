# ==========================================================
# GTA San Andreas SFX al1h3n edition - v1
# Rofi soundtheme.
# ==========================================================

DIR=~/.local/share/molnios/sfx/gta

if [ "$1" = "error" ];then
    pw-play --volume 2 $DIR/rdr2.mp3 &
elif [ "$1" = "tap" ];then
    pw-play --volume 1.5 $DIR/move.mp3 &
elif [ "$1" = "enter" ];then
    pw-play --volume .5 $DIR/select.wav &
elif [ "$1" = "tab" ];then
    pw-play --volume .5 $DIR/select.wav &
elif [ "$1" = "exit" ];then
    pw-play --volume .15 $DIR/wasted.wav &
else
    notify-send -u critical "Rofi error:" "Incorrect sound call."
fi