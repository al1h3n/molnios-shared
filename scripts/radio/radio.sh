#!/usr/bin/env bash
# radio - yt-x discovery with cliamp playback.
#
# Shared launcher for shell aliases.
#
# yt-x discovers videos; its player hook opens the selection in cliamp.
set -uo pipefail

VOLUME="${RADIO_VOLUME:--13}"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

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

# gum probes the terminal (DECRQM, kitty keyboard protocol) and exits without
# draining the replies. They land in the tty buffer and the next TUI reads them
# as keystrokes - which is the "?2026;2$y?2027;0$y?1u" that appeared in yt-x's
# search box. Eat whatever is pending before handing the terminal over.
drain_tty(){
    [ -t 0 ] || return 0
    # read's job here is to consume, not to store.
    while read -rs -t 0.15 -N 4096 _ 2>/dev/null;do :;done
}
play_url(){ cliamp --vol "$VOLUME" "$1"; }

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

# Anything that is not a bare youtube id: returns a URL cliamp can open, or empty.
resolve_url(){
    local input="$1" id query url
    case "$input" in
        *open.spotify.com/track/*)
            query=$(spotify_to_query "$input") || return 1
            [ -n "$query" ] || return 1
            info "Spotify: $query"
            # Resolve here so a search miss is reported before opening cliamp.
            url=$(yt-dlp --simulate --print "%(webpage_url)s" "ytsearch1:$query" 2>/dev/null | head -n1)
            [ -n "$url" ] && printf '%s' "$url"
            ;;
        *soundcloud.com/*)
            # cliamp handles SoundCloud URLs directly.
            printf '%s' "$input"
            ;;
        *)
            id=$(extract_id "$input")
            [ -n "$id" ] && printf 'https://youtu.be/%s' "$id"
            ;;
    esac
}

# yt-x owns the picking. Its extension replaces the mpv player hook with
# cliamp; keeping the player attached lets cliamp own the terminal and audio.
#
# "$@", never a word-split string: yt-x validates that every value-taking flag has
# a non-empty next argument, so `--search lofi hip hop` made it read "lofi" as the
# term and then choke on "hip" as an unknown flag - which is why searching dumped
# the usage text instead of results. An empty term hit the same check.
pick(){
    [ $# -gt 0 ] || return 1
    drain_tty
    RADIO_VOLUME="$VOLUME" yt-x -x "$SCRIPT_DIR/radio-cliamp.sh" "$@" --player mpv --listen -me --no-disown-player
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

main(){
    deps_ok cliamp gum curl yt-dlp || return 1
    command -v yt-x >/dev/null 2>&1 || info "yt-x not found - only direct IDs and links will work"

    if [ "${1:-}" = --vol ];then
        [ $# -ge 2 ] || { err "--vol needs a dB value"; return 1; }
        VOLUME="$2"
        shift 2
    fi

    # radio <id|url> [dB] also accepts a volume as its second argument.
    [ $# -lt 2 ] || VOLUME="$2"
    if ! [[ "$VOLUME" =~ ^-?[0-9]+$ ]] || [ "$VOLUME" -lt -30 ] || [ "$VOLUME" -gt 6 ];then
        err "volume must be -30 to +6 dB, got '$VOLUME'"
        return 1
    fi

    if [ $# -gt 0 ];then
        local url
        url=$(resolve_url "$1")
        [ -z "$url" ] && { err "could not resolve '$1'"; return 1; }
        play_url "$url"
    fi

    while true;do
        local choice
        choice=$(gum choose --header "radio" \
            "Search" \
            "Subscriptions" \
            "Personalised feed" \
            "Liked videos" \
            "Watch later" \
            "Watch history" \
            "Recently watched" \
            "Saved playlists" \
            "Paste link" \
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
                play_url "$url"
                ;;
            Quit)         break ;;
        esac
    done
}

main "$@"
