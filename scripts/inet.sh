# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - ko-fi.com/al1h3n
# Internet widget v1 - first release.
# Part of the MolniOS project.
# ==============================================================================

WIFI_STATUS=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2)
ETH_STATUS=$(nmcli -t -f TYPE,STATE dev | grep "^ethernet:connected")

if [[ -n $ETH_STATUS ]];then
    echo "   Connected"
    exit 0
fi

if [[ -n "$WIFI_STATUS" ]];then
    echo "    $WIFI_STATUS"
    exit 0
fi

echo "󱘖   Disconnected"
