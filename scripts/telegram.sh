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

# Order of preference (highest → lowest)
PRIORITY_CLIENTS=(
    "64gram"
    "kotatogram kotatogram-desktop"
    "ayugram ayugram-desktop"
    "telegram-desktop Telegram telegram"   # NixOS ships as 'Telegram'
)

for group in "${PRIORITY_CLIENTS[@]}"; do
    for bin in $group; do
        if command -v "$bin" >/dev/null 2>&1; then
            exec "$bin" "$@"
        fi
    done
done

echo "⚠️  No supported Telegram client installed." >&2
printf "Checked: "
for group in "${PRIORITY_CLIENTS[@]}"; do echo -n "$group / "; done
echo >&2
exit 1