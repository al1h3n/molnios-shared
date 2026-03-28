#!/bin/bash

# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - ko-fi.com/al1h3n
# electon v1 - first release.
# Unified Electron launcher for Hyprland.
# Part of the MolniOS project.
# ==============================================================================

ELECTRON_FLAGS=(--enable-features=UseOzonePlatform --ozone-platform=wayland)

# Function: launch a client with optional electron flags
launch_app() {
    local app="$1"
    shift

    case "$app" in
        # Electron-based apps
        discord|vesktop|webcord|discord-canary|discord-ptb|spotify|spotify-launcher|notion-app|notion-app-electron|coder)
            if command -v "$app" >/dev/null 2>&1; then
                exec "$app" "${ELECTRON_FLAGS[@]}" "$@"
            fi
            ;;
        # Flatpak handling
        spotify-flatpak)
            exec flatpak run com.spotify.Client "$@"
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
        *)
            if command -v "$app" >/dev/null 2>&1; then
                exec "$app" "$@"
            else
                echo "App '$app' not found" >&2
                exit 1
            fi
            ;;
    esac
}

# Main: parse first argument as the app to launch
if [[ -z "$1" ]]; then
    echo "Usage: $0 <app> [args...]"
    echo "Available: discord, spotify, browser, notes, coder, etc."
    exit 1
fi

APP="$1"
shift

# Spotify special handling
if [[ "$APP" == "spotify" ]]; then
    if command -v spotify >/dev/null 2>&1; then
        launch_app spotify "$@"
    elif command -v spotify-launcher >/dev/null 2>&1; then
        launch_app spotify-launcher "$@"
    elif command -v flatpak >/dev/null 2>&1; then
        launch_app spotify-flatpak "$@"
    else
        launch_app spotify-launcher "$@"
    fi
else
    launch_app "$APP" "$@"
fi