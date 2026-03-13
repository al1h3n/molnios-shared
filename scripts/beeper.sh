# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - ko-fi.com/al1h3n
# beeper v1 - first release.
# Create a notification.
# Part of the MolniOS project.
# ==============================================================================

#!/bin/sh

# Optional: verbose mode.
# echo "[$(date)] Script triggered" >> /tmp/beeper.log

# 1. Definitions. If custom file is provided, it'll be the dominant sound.
DEFAULT_SOUND=$L_PATH/sfx/notifications/breeze.mp3
if [ -f "$1" ];then
    FILE=$1
else
    FILE=$DEFAULT_SOUND
fi

# 2. Try playing with mpv if available, otherwise paplay.
# Redirect ALL output (errors included) to the log file.
# if command -v mpv &> /dev/null; then
#     mpv --no-terminal --volume=50 $FILE
# else
#     paplay $FILE --volume=50
# fi
