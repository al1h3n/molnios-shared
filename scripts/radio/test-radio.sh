#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export RADIO_TEST_DIR="$tmp"

gum(){
    case "$1" in
        input) printf '%s\n' 'test song' ;;
        choose)
            if [ ! -e "$RADIO_TEST_DIR/chosen" ];then
                touch "$RADIO_TEST_DIR/chosen"
                printf '%s\n' Search
            else
                printf '%s\n' Quit
            fi ;;
        *) return 0 ;;
    esac
}
yt-x(){
    local extension
    while [ $# -gt 0 ];do
        if [ "$1" = -x ];then extension="$2"; shift; fi
        shift
    done
    [ -n "${extension:-}" ] || return 1
    . "$extension"
    __player_mpv 'https://youtu.be/dQw4w9WgXcQ' listen
}
cliamp(){
    printf '%s\n' "$*" >> "$RADIO_TEST_DIR/played"
}
export -f gum yt-x cliamp

bash scripts/radio.sh >"$tmp/output" 2>&1
test "$(<"$tmp/played")" = '--vol -13 https://youtu.be/dQw4w9WgXcQ'
! command grep -q 'nohup:' "$tmp/output"

bash scripts/radio.sh --vol -20 dQw4w9WgXcQ >"$tmp/output" 2>&1
mapfile -t played < "$tmp/played"
test "${played[1]}" = '--vol -20 https://youtu.be/dQw4w9WgXcQ'
if bash scripts/radio.sh --vol -40 >"$tmp/output" 2>&1;then
    printf '%s\n' 'invalid volume was accepted' >&2
    exit 1
fi
printf '%s\n' 'radio selection and direct URL open cliamp at the requested volume'
