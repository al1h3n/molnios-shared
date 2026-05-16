#!/usr/bin/env bash

exists(){
	command -v $1&>/dev/null
}

: '
ipinfo.io has rate limit.
Check if VPN exists and reset IP adress (change for your needs).
'
# if exists warp-cli;then
#     warp-cli disconnect&>/dev/null
#     warp-cli connect&>/dev/null
#     sleep 4
# fi

SCRIPT=$L_PATH/scripts/whereami.sh
SPACING=${1:-2}
PAD=$(printf '%*s' "$SPACING" '')

TEXT=$(sh $SCRIPT -C)
TOOLTIP=$(sh $SCRIPT -S "$SPACING")
TOOLTIP_ESCAPED=$(printf '%s' "$TOOLTIP" | sed ':a;N;$!ba;s/\n/\\n/g')

printf '{"text":"󰖂%s%s","tooltip":"%s"}\n' "$PAD" "${TEXT:-N/A}" "$TOOLTIP_ESCAPED"