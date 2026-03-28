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
    # Priority: vscodium/codium (NixOS) → code → cursor → coder

    coder)
        try_exec vscodium "${ELECTRON_FLAGS[@]}" "$@" ||  # Arch, Debian, Alpine (AUR/deb)
        try_exec codium   "${ELECTRON_FLAGS[@]}" "$@" ||  # NixOS binary name
        try_exec code     "${ELECTRON_FLAGS[@]}" "$@" ||  # VS Code
        try_exec cursor   "${ELECTRON_FLAGS[@]}" "$@" ||  # Cursor (VS Code fork)
        try_exec coder    "${ELECTRON_FLAGS[@]}" "$@" ||  # Generic coder fallback
        { echo "No editor found (tried vscodium, codium, code, cursor, coder)" >&2; exit 1; }
        ;;

    # ── Music ─────────────────────────────────────────────────────────────────
    # Priority: spotify → spotify-launcher (AUR wrapper that downloads Spotify)

    spotify)
        try_exec spotify          "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec spotify-launcher "${ELECTRON_FLAGS[@]}" "$@" ||
        { echo "No Spotify client found (tried spotify, spotify-launcher)" >&2; exit 1; }
        ;;

    # ── Communications ────────────────────────────────────────────────────────
    # Priority: vesktop (AUR) → webcord → discord
    # discord-canary and discord-ptb are omitted — same source as discord.

    discord)
        try_exec vesktop "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec webcord "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec discord "${ELECTRON_FLAGS[@]}" "$@" ||
        { echo "No Discord client found (tried vesktop, webcord, discord)" >&2; exit 1; }
        ;;

    # ── Notes ─────────────────────────────────────────────────────────────────
    # Priority: notion-app-electron (AUR) → notion-app → notion-enhanced → obsidian → appflowy
    # appflowy is Flutter-based — no Electron flags.

    notes)
        try_exec notion-app-electron "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec notion-app          "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec notion-enhanced     "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec obsidian            "${ELECTRON_FLAGS[@]}" "$@" ||
        try_exec appflowy                                   "$@" ||  # Flutter, no Electron flags.
        { echo "No notes app found (tried notion-app-electron, notion-app, notion-enhanced, obsidian, appflowy)" >&2; exit 1; }
        ;;

    # ── Browser ───────────────────────────────────────────────────────────────
    # Priority: firefox → brave → ungoogled-chromium → chromium → google-chrome
    # Browsers handle Wayland natively — no Electron flags needed.

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
            echo "Unknown argument '$APP'. Valid arguments: coder, spotify, discord, notes, browser" >&2
            exit 1
        fi
        ;;

esac