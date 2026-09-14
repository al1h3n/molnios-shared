#!/usr/bin/env bash
# radio - YouTube audio player for the terminal.
#
# Was a ~100-line function duplicated in .zshrc and config.fish, each with its
# own extract-id/deps/ipc helpers. One copy here, both shells call it.
#
# Split of responsibilities:
#   yt-x  discovery - search, subscriptions, feed, liked, history, playlists.
#         It already knows how to talk to YouTube, so nothing here scrapes IDs.
#   mpv   playback. yt-x is told to spawn mpv on *our* IPC socket
#         (--mpv-args --input-ipc-server), so after yt-x exits the same control
#         loop still drives the player: switch tracks, volume, seek, quit.
#
# No video by design: yt-x itself does video, this is the audio front end.
set -uo pipefail

SOCK="${XDG_RUNTIME_DIR:-/tmp}/mpv-radio.sock"
LOG=/tmp/radio-mpv.log
VOLUME="${RADIO_VOLUME:-50}"

# yt-dlp has no "librewolf" backend, but librewolf's profile is Firefox's format,
# so the firefox backend pointed at the profile directory works. Exported here
# rather than left to the session so radio works without a rebuild; a value
# already in the environment wins.
if [ -z "${YT_X_BROWSER:-}" ] && [ -f "$HOME/.librewolf/personal/cookies.sqlite" ];then
    export YT_X_BROWSER="firefox:$HOME/.librewolf/personal"
fi

err(){ gum style --foreground 1 "radio: $*" >&2; }
info(){ gum style --foreground 244 "$*" >&2; }

deps_ok(){
    local dep missing=0
    for dep in "$@";do
        command -v "$dep" >/dev/null 2>&1 || { echo "radio: needs $dep" >&2; missing=1; }
    done
    return $missing
}

# An 11-char YouTube id, from a bare id or any of the URL shapes.
extract_id(){
    local input="$1" id
    id=$(printf '%s' "$input" \
        | grep -oE '(youtu\.be/|youtube\.com/(watch\?v=|live/|shorts/)|[?&]v=)[A-Za-z0-9_-]{11}' \
        | grep -oE '[A-Za-z0-9_-]{11}$' | head -n1)
    [ -z "$id" ] && printf '%s' "$input" | grep -qE '^[A-Za-z0-9_-]{11}$' && id="$input"
    printf '%s' "$id"
}

ipc(){ [ -S "$SOCK" ] && printf '%s\n' "$1" | nc -U -w1 "$SOCK" >/dev/null 2>&1; }

# gum probes the terminal (DECRQM, kitty keyboard protocol) and exits without
# draining the replies. They land in the tty buffer and the next TUI reads them
# as keystrokes - which is the "?2026;2$y?2027;0$y?1u" that appeared in yt-x's
# search box. Eat whatever is pending before handing the terminal over.
drain_tty(){
    [ -t 0 ] || return 0
    # read's job here is to consume, not to store.
    while read -rs -t 0.15 -N 4096 _ 2>/dev/null;do :;done
}
alive(){ ipc '{"command":["get_property","pid"]}'; }

stop(){
    alive && ipc '{"command":["quit"]}'
    rm -f "$SOCK"
}

# Takes a full media URL, not an id, so soundcloud and a resolved spotify track
# go through the same path as youtube.
start_url(){
    stop
    mpv --msg-level=all=error --no-video --volume="$VOLUME" \
        --input-ipc-server="$SOCK" "$1" >"$LOG" 2>&1 &
    disown
    sleep 1
}

start_id(){ start_url "https://youtu.be/$1"; }

# Spotify streams are DRM'd, so nothing can play the track itself. The public
# track page still carries the metadata, so take title + artist from the og:
# tags and hand the query to yt-dlp's ytsearch.
#   og:title       "Are You With Me"
#   og:description "Lost Frequencies · Less Is More · Song · 2016"
spotify_to_query(){
    local html title artist
    html=$(curl -sL --max-time 20 -A "Mozilla/5.0" "$1") || return 1
    title=$(printf '%s' "$html" \
        | grep -oE '<meta property="og:title" content="[^"]*"' \
        | head -n1 | sed 's/.*content="//; s/"$//')
    artist=$(printf '%s' "$html" \
        | grep -oE '<meta property="og:description" content="[^"]*"' \
        | head -n1 | sed 's/.*content="//; s/"$//' | cut -d"·" -f1)
    [ -n "$title" ] || return 1
    printf '%s %s' "$title" "$artist"
}

# Anything that is not a bare youtube id: returns a URL mpv can open, or empty.
resolve_url(){
    local input="$1" id query url
    case "$input" in
        *open.spotify.com/track/*)
            query=$(spotify_to_query "$input") || return 1
            [ -n "$query" ] || return 1
            info "Spotify: $query"
            # Resolve here rather than letting mpv do it, so a miss is reported
            # instead of mpv silently exiting.
            url=$(yt-dlp --simulate --print "%(webpage_url)s" "ytsearch1:$query" 2>/dev/null | head -n1)
            [ -n "$url" ] && printf '%s' "$url"
            ;;
        *soundcloud.com/*)
            # yt-dlp handles soundcloud natively, so mpv takes the URL as-is.
            printf '%s' "$input"
            ;;
        *)
            id=$(extract_id "$input")
            [ -n "$id" ] && printf 'https://youtu.be/%s' "$id"
            ;;
    esac
}

# yt-x owns the picking; mpv is pointed at our socket so the loop keeps control
# once yt-x exits. --listen is yt-x's audio-only action, -me exits after it.
#
# "$@", never a word-split string: yt-x validates that every value-taking flag has
# a non-empty next argument, so `--search lofi hip hop` made it read "lofi" as the
# term and then choke on "hip" as an unknown flag - which is why searching dumped
# the usage text instead of results. An empty term hit the same check.
pick(){
    [ $# -gt 0 ] || return 1
    stop
    drain_tty
    printf 'yt-x %s\n' "$*" >> "$LOG"
    yt-x "$@" --listen -me --disown-player \
        --mpv-args "--input-ipc-server=$SOCK --no-video --volume=$VOLUME" || true
    sleep 1
}

# Everything personalised goes through yt-dlp --cookies-from-browser, which yt-x
# drives off CONFIG_BROWSER / YT_X_BROWSER. Unset, those menu entries come back
# empty with no explanation, so say so instead.
needs_cookies(){
    [ -n "${YT_X_BROWSER:-}" ] && return 0
    grep -qE '^CONFIG_BROWSER="[^"]+"' "${XDG_CONFIG_HOME:-$HOME/.config}/yt-x/config" 2>/dev/null \
        && return 0
    err "no browser cookies configured - YouTube will not return your data"
    info "set YT_X_BROWSER, e.g. firefox:\$HOME/.librewolf/personal"
    return 1
}

now_playing(){
    alive || { printf 'stopped'; return; }
    printf '%s\n' '{"command":["get_property","media-title"]}' \
        | nc -U -w1 "$SOCK" 2>/dev/null \
        | sed -n 's/.*"data":"\([^"]*\)".*/\1/p' | head -n1
}

# mpv is detached and has no tty, so its keybinds are unreachable. Everything
# here goes over the IPC socket instead.
controls(){
    alive || { err "player is not running"; return 1; }
    while true;do
        local c
        c=$(gum choose --header "controls - $(now_playing)" \
            "Pause / resume" "Volume +10" "Volume -10" \
            "Seek +10s" "Seek -10s" "Mute" "Back") || return 0
        case "$c" in
            "Pause / resume") ipc '{"command":["cycle","pause"]}' ;;
            "Volume +10")     ipc '{"command":["add","volume",10]}' ;;
            "Volume -10")     ipc '{"command":["add","volume",-10]}' ;;
            "Seek +10s")      ipc '{"command":["seek",10]}' ;;
            "Seek -10s")      ipc '{"command":["seek",-10]}' ;;
            Mute)             ipc '{"command":["cycle","mute"]}' ;;
            Back)             return 0 ;;
        esac
        alive || { err "player exited"; return 1; }
    done
}

main(){
    deps_ok mpv gum nc curl yt-dlp || return 1
    command -v yt-x >/dev/null 2>&1 || info "yt-x not found - only direct IDs will work"

    # radio <id|url> [volume] keeps the old positional interface.
    if [ $# -gt 0 ];then
        local url
        url=$(resolve_url "$1")
        [ -z "$url" ] && { err "could not resolve '$1'"; return 1; }
        case "${2:-}" in
            "") ;;
            *[!0-9]*) err "volume must be 0-100, got '$2'"; return 1 ;;
            *) [ "$2" -le 100 ] && VOLUME="$2" || { err "volume must be 0-100"; return 1; } ;;
        esac
        start_url "$url"
    fi

    while true;do
        local choice
        choice=$(gum choose --header "radio - $(now_playing)" \
            "Search" \
            "Subscriptions" \
            "Personalised feed" \
            "Liked videos" \
            "Watch later" \
            "Watch history" \
            "Recently watched" \
            "Saved playlists" \
            "Paste link" \
            "Controls" \
            "Stop player" \
            "Quit") || break

        case "$choice" in
            Search)
                local term
                term=$(gum input --placeholder "search YouTube") || continue
                [ -n "$term" ] || { err "empty search term"; continue; }
                pick --search "$term"
                ;;
            Subscriptions)      needs_cookies && pick --subscriptions-feed ;;
            "Personalised feed") needs_cookies && pick --feed ;;
            "Liked videos")     needs_cookies && pick --liked ;;
            "Watch later")      needs_cookies && pick --watch-later ;;
            "Watch history")    needs_cookies && pick --watch-history ;;
            "Recently watched") pick --recent ;;
            "Saved playlists")  needs_cookies && pick --playlists ;;
            "Paste link")
                local input url
                input=$(gum input --placeholder "YouTube / SoundCloud / Spotify link or YouTube ID") || continue
                [ -z "$input" ] && continue
                url=$(resolve_url "$input")
                [ -z "$url" ] && { err "could not resolve '$input'"; continue; }
                if alive;then
                    info "Loading: $url"
                    ipc "{\"command\":[\"loadfile\",\"$url\",\"replace\"]}" || start_url "$url"
                else
                    start_url "$url"
                fi
                ;;
            Controls)     controls ;;
            "Stop player") stop; info "Player stopped" ;;
            Quit)         stop; break ;;
        esac
    done
}

main "$@"
