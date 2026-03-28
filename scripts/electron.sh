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
APP="$1"
shift

# Try to exec a binary with given args. Returns 1 if not found, never returns on success.
try_exec() {
    local bin="$1"; shift
    if command -v "$bin" >/dev/null 2>&1; then
        exec "$bin" "$@"
    fi
    return 1
}

case "$APP" in

    # ── Editor / IDE ──────────────────────────────────────────────────────────
    # Priority: vscodium → code → cursor → zed → coder

    coder)
        try_exec vscodium "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec code     "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec cursor   "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec zed                             "$@" ||  # Native Rust, no Electron flags.
        try_exec coder    "${ELECTRON_FLAGS[@]}" "$@" ||
        { echo "No editor found (tried vscodium, code, cursor, zed, coder)" >&2; exit 1; }
        ;;

    # ── Music ─────────────────────────────────────────────────────────────────
    # Priority: spotify → spotify-launcher

    spotify)
        try_exec spotify          "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec spotify-launcher "${ELECTRON_FLAGS[@]}" "$@" ||
        { echo "No Spotify client found (tried spotify, spotify-launcher)" >&2; exit 1; }
        ;;

    # ── Communications ────────────────────────────────────────────────────────
    # Priority: vesktop → webcord → discord → discord-canary → discord-ptb

    discord)
        try_exec vesktop        "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec webcord        "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec discord        "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec discord-canary "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec discord-ptb    "${ELECTRON_FLAGS[@]}" "$@" ||
        { echo "No Discord client found (tried vesktop, webcord, discord, discord-canary, discord-ptb)" >&2; exit 1; }
        ;;

    # ── Browser ───────────────────────────────────────────────────────────────
    # Priority: firefox → brave → ungoogled-chromium → chromium → google-chrome
    # Browsers handle Wayland natively; no Electron flags needed.

    browser)
        try_exec firefox            "$@" ||
        try_exec brave              "$@" ||
        try_exec ungoogled-chromium "$@" ||
        try_exec chromium           "$@" ||
        try_exec google-chrome      "$@" ||
        { echo "No browser found (tried firefox, brave, ungoogled-chromium, chromium, google-chrome)" >&2; exit 1; }
        ;;

    # ── Generic fallback ──────────────────────────────────────────────────────

    *)
        if command -v "$APP" >/dev/null 2>&1; then
            exec "$APP" "${ELECTRON_FLAGS[@]}" "$@"
        else
            echo "Unknown argument '$APP'. Valid arguments: coder, spotify, discord, browser" >&2
            exit 1
        fi
        ;;

esac