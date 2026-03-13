# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - ko-fi.com/al1h3n
# Battery widget v1 - first release.
# Part of the molniux project.
# ==============================================================================

# Adjust BAT0 to BAT1 if needed (check /sys/class/power_supply/)

# 0. Environments.
BAT=BAT0
BAT_PATH=/sys/class/power_supply/$BAT
CAPACITY=$(cat $BAT_PATH/capacity)
STATUS=$(cat $BAT_PATH/status)

# 1. AC / Charging icons.
if [ ! -d $BAT_PATH ];then
    ICON="󰦉  "
    echo "$ICON | AC"
    exit 0
fi

if [[ $STATUS == Charging ]];then
    ICON="  "
    echo $ICON Charging
    exit 0
fi


# 2. Percentage icons.
if [[ $CAPACITY -ge 90 ]]; then
    ICON="  "
elif [[ $CAPACITY -ge 60 ]]; then
    ICON="  "
elif [[ $CAPACITY -ge 40 ]]; then
    ICON="  "
elif [[ $CAPACITY -ge 10 ]]; then
    ICON="  "
else
    ICON="  "
fi
echo $ICON $CAPACITY%
