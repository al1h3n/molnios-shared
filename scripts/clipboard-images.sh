#!/usr/bin/env bash
# Rofi clipboard picker with image preview support

tmp_dir=$(mktemp -d)
trap "rm -rf $tmp_dir" EXIT

cliphist list | while IFS=$'\t' read -r id rest;do
    if [[ "$rest" == "[[ binary data"* ]];then
        img="$tmp_dir/$id.png"
        cliphist decode <<< "$id	$rest" > "$img" 2>/dev/null
        echo -e "$id\t$rest\0icon\x1f$img"
    else
        echo -e "$id\t$rest"
    fi
done | rofi -dmenu -display-columns 2 -show-icons | cliphist decode | wl-copy && wtype -M ctrl -k v -m ctrl
