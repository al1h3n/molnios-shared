# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - ko-fi.com/al1h3n
# playr v1 - first release.
# Find easily what music you're listening to.
# Part of the MolniOS project.
# ==============================================================================

#!/bin/bash

if playerctl status >>/dev/null 2>&1;then

    # Text.
    STATUS=$(playerctl status)
    TEXT=$(playerctl metadata --format '{{default(title,"Emptiness")}} | {{default(artist,"Unknown")}} | {{duration(position)}}/{{duration(mpris:length)}}' | sed 's/&/&amp;/g')
    # {{x}}, x = default/title/artist/album/playerName/status/volume,
    # Use default in cases where you need a placeholder.

    if [[ $STATUS=="Playing" ]];then
        echo "  $TEXT"
    elif [[ $STATUS=="Paused" ]];then
        echo "  $TEXT"
    fi
else
    echo ""
fi
