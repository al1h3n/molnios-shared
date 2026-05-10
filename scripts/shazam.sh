debug_notify(){
    [[ "$DEBUG" == "1" ]] || return 0
    notify-send -h int:transient:1 "󰎆 Shazam Debug" "$1"
    echo $1
}
notify(){
    notify-send -h int:transient:1 " Shazam" "$1"
}

exists(){
	command -v $1&>/dev/null
}

if exists notify-send;then
    notify "Listening for 5 seconds.."
else
    notify-send -u critical " Dependency error" "notify-send isn't installed"
fi

DEBUG=0
while getopts "d" opt; do
    case $opt in
        d) DEBUG=1 ;;
        *) ;;
    esac
done
tmpf=$(mktemp /tmp/shazam_XXXXXX.wav)
mon="$(pactl get-default-sink).monitor"
debug_notify "Recording from: $mon"

parec --device=$mon --file-format=wav $tmpf & PREC=$!
sleep 5
kill $PREC 2>/dev/null
wait $PREC 2>/dev/null

result=$(songrec audio-file-to-recognized-song $tmpf 2>/dev/null | \
python3 -c "
import sys,json
d=json.load(sys.stdin)
t=d.get('track',{})
title=t.get('title','')
sub=t.get('subtitle','')
print(title + ' — ' + sub if title else '')
" 2>/dev/null)

rm -f $tmpf
notify ${result:-"Song wasn't recognized"}
echo ${result:-"Song wasn't recognized"}