#!/bin/bash

# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - ko-fi.com/al1h3n
# electon.sh - Unified Electron launcher for Hyprland.
# Part of the MolniOS project.
# ==============================================================================

ELECTRON_FLAGS=(--enable-features=UseOzonePlatform --ozone-platform=wayland)

launch_app() {
    local app="$1"
    shift

    if command -v "$app" >/dev/null 2>&1; then
        exec "$app" "${ELECTRON_FLAGS[@]}" "$@"
    fi
}

case "$1" in

coder|vscodium|code|cursor|zed)
    case "$1" in
        vscodium)       exec vscodium "${ELECTRON_FLAGS[@]}" "$@" ;;
        code)           exec code "${ELECTRON_FLAGS[@]}" "$@" ;;      # VS Code
        cursor)         exec cursor "${ELECTRON_FLAGS[@]}" "$@" ;;    # Cursor (VS Code fork)
        zed)            exec zed "$@" ;;                             # Zed (Rust native, no Electron flags)
        coder)          exec coder "${ELECTRON_FLAGS[@]}" "$@" ;;    # your generic "coder"
    esac
    ;;

discord|vesktop|webcord|discord-canary|discord-ptb|spotify|spotify-launcher|notion-app|notion-app-electron)
    if command -v "$1" >/dev/null 2>&1; then
        exec "$1" "${ELECTRON_FLAGS[@]}" "$@"
    fi
    ;;

notes)
    local notes_apps=(notion-app notion-app-electron obsidian)
    for n in "${notes_apps[@]}"; do
        if command -v "$n" >/dev/null 2>&1; then
            exec "$n" "${ELECTRON_FLAGS[@]}" "$@"
        fi
    done
    echo "No notes app found" >&2
    exit 1
    ;;

browser)
    local browsers=(firefox brave ungoogled-chromium chromium google-chrome)
    for b in "${browsers[@]}"; do
        if command -v "$b" >/dev/null 2>&1; then
            exec "$b" "$@"
        fi
    done
    echo "No browser found" >&2
    exit 1
    ;;

*)
    if command -v "$1" >/dev/null 2>&1; then
        exec "$1" "$@"
    else
        echo "App '$1' not found" >&2
        exit 1
    fi
    ;;
esac