#!/bin/sh
# Cycle focus through all open windows in niri.
# Usage: niri-cycle.sh next | prev
DIRECTION="${1:-next}"

WINDOWS=$(niri msg --json windows 2>/dev/null) || exit 1
COUNT=$(echo "$WINDOWS" | jq 'length')
[ "$COUNT" -le 1 ] && exit 0

IDS=$(echo "$WINDOWS" | jq -r '.[].id')
FOCUSED=$(echo "$WINDOWS" | jq -r '.[] | select(.is_focused == true) | .id')

# Load IDs into positional args for simple index math
set -- $IDS
TOTAL=$#
POS=0
I=0
for ID in "$@"; do
    I=$((I + 1))
    [ "$ID" = "$FOCUSED" ] && POS=$I && break
done

if [ "$DIRECTION" = "next" ]; then
    TARGET_POS=$(( (POS % TOTAL) + 1 ))
else
    TARGET_POS=$(( (POS - 2 + TOTAL) % TOTAL + 1 ))
fi

TARGET_ID=$(echo "$IDS" | sed -n "${TARGET_POS}p")
[ -n "$TARGET_ID" ] && niri msg action focus-window --id "$TARGET_ID"