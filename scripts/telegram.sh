#!/bin/bash

# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - ko-fi.com/al1h3n
# telegram.sh — Unified launcher for Telegram clients
# Priority: 64Gram → Kotatogram → Ayugram → telegram‑desktop (official)
# Part of the MolniOS project.
# ==============================================================================

launch_telegram() {
    local client="$1"
    shift
    if command -v "$client" >/dev/null 2>&1; then
        exec "$client" "$@"
    fi
}

if [[ -z "$1" ]]; then
    echo "Usage: $0 <client>" >&2
    echo "Available: 64gram, kotatogram, ayugram, telegram" >&2
    exit 1
fi

CLIENT="$1"
shift

case "$CLIENT" in
    64gram)
        # 64Gram is an unofficial Telegram Desktop variant (x64 enhanced builds) :contentReference[oaicite:1]{index=1}
        launch_telegram 64gram "$@"
        ;;

    kotatogram)
        # Kotatogram Desktop (fork of Telegram Desktop) :contentReference[oaicite:2]{index=2}
        launch_telegram kotatogram "$@"
        ;;

    ayugram)
        # AyuGram Desktop (Telegram fork with customization & privacy) :contentReference[oaicite:3]{index=3}
        launch_telegram ayugram "$@"
        ;;

    telegram)
        # Official Telegram Desktop
        launch_telegram telegram-desktop "$@"
        ;;

    *)
        echo "Unknown Telegram client: '$CLIENT'" >&2
        exit 1
        ;;
esac

echo "No such client installed: $CLIENT" >&2
exit 1