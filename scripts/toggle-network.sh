ETH=$(nmcli -t -f TYPE,STATE device | grep "^ethernet:connected" | head -1)
WIFI=$(nmcli -t -f TYPE,STATE device | grep "^wifi:connected" | head -1)
if [ -n "$ETH" ]; then
    ETH_DEV=$(nmcli -t -f TYPE,DEVICE device | grep "^ethernet" | cut -d: -f2 | head -1)
    nmcli device disconnect "$ETH_DEV"
elif [ -n "$WIFI" ]; then
    nmcli radio wifi off
fi