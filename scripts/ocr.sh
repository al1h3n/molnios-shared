# ocr-region.sh — Capture a screen region and OCR it to a viewer window / clipboard
#
# Dependencies: grim, slurp, tesseract5, wl-clipboard, libnotify (optional)
# Viewer deps (one of): zenity | yad | your terminal emulator
#
# NixOS — recommended configuration.nix / home-manager setup:
#   (tesseract5.override { enableLanguages = [ "eng" "deu" "fra" ]; })
#   grim slurp wl-clipboard libnotify
#   zenity   # or: yad
#
# Usage:
#   ocr-region.sh                     — open result in viewer window (default)
#   ocr-region.sh --viewer clipboard  — copy silently to clipboard only
#   ocr-region.sh --viewer zenity     — force zenity window
#   ocr-region.sh --viewer yad        — force yad window
#   ocr-region.sh --viewer term       — open in $TERM + $EDITOR
#   ocr-region.sh --save              — also save .txt + .png to screenshots dir
#   ocr-region.sh --lang deu          — override OCR language (default: eng)
#   ocr-region.sh --tessdata /path    — manual TESSDATA_PREFIX override
#
# Hyprland bind examples:
#   bind = SUPER, T,       exec, ~/scripts/ocr-region.sh
#   bind = SUPER SHIFT, T, exec, ~/scripts/ocr-region.sh --save

# ── defaults ──────────────────────────────────────────────────────────────────
LANG="eng"
SAVE=false
VIEWER="auto"   # auto | zenity | yad | term | clipboard
TESSDATA_OVERRIDE=""
SCREENSHOTS_DIR="$(xdg-user-dir PICTURES)/Screenshots"
# Terminal + editor used when VIEWER=term (override to taste)
TERM_CMD="${TERM:-foot}"
EDITOR_CMD="${EDITOR:-nano}"

# ── parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --save)       SAVE=true ;;
        --lang)       shift; LANG="$1" ;;
        --viewer)     shift; VIEWER="$1" ;;
        --tessdata)   shift; TESSDATA_OVERRIDE="$1" ;;
        *)            echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
    shift
done

# ── dependency check ──────────────────────────────────────────────────────────
for cmd in grim slurp tesseract wl-copy; do
    if ! command -v "$cmd" &>/dev/null; then
        msg="ocr-region: missing dependency '$cmd'"
        command -v notify-send &>/dev/null && notify-send -u critical "OCR" "$msg"
        echo "$msg" >&2
        exit 1
    fi
done

# ── locate tessdata (NixOS / TESSDATA_PREFIX aware) ───────────────────────────
if [[ -n "$TESSDATA_OVERRIDE" ]]; then
    export TESSDATA_PREFIX="$TESSDATA_OVERRIDE"
elif [[ -z "$TESSDATA_PREFIX" ]]; then
    TESS_BIN="$(command -v tesseract)"
    TESS_STORE="${TESS_BIN%/bin/tesseract}"
    if [[ -d "$TESS_STORE/share/tessdata" ]]; then
        export TESSDATA_PREFIX="$TESS_STORE/share/tessdata"
    fi
fi

if [[ -n "$TESSDATA_PREFIX" ]] && [[ ! -f "$TESSDATA_PREFIX/${LANG}.traineddata" ]]; then
    msg="ocr-region: language '$LANG' not found in $TESSDATA_PREFIX"$'\n'"Rebuild tesseract with enableLanguages = [ \"$LANG\" ]"
    command -v notify-send &>/dev/null && notify-send -u critical "OCR" "$msg"
    echo "$msg" >&2
    exit 1
fi

# ── capture region ────────────────────────────────────────────────────────────
TIMESTAMP="$(date +%Y-%m-%d_%H:%M:%S)"
TMP_IMG="$(mktemp /tmp/ocr_XXXXXX.png)"

grim -g "$(slurp -b 000000CC -s FFFFFF00 -c 00FF00 -w 1)" "$TMP_IMG"

if [[ $? -ne 0 ]] || [[ ! -s "$TMP_IMG" ]]; then
    rm -f "$TMP_IMG"
    exit 0
fi

# ── run OCR ───────────────────────────────────────────────────────────────────
TMP_BASE="$(mktemp /tmp/ocr_text_XXXXXX)"
tesseract "$TMP_IMG" "$TMP_BASE" -l "$LANG" --psm 6 quiet 2>/dev/null
TMP_TXT="${TMP_BASE}.txt"

if [[ ! -s "$TMP_TXT" ]]; then
    command -v notify-send &>/dev/null && \
        notify-send -u normal "OCR" "No text detected in selection."
    rm -f "$TMP_IMG" "$TMP_BASE" "$TMP_TXT"
    exit 0
fi

# ── always copy to clipboard too ──────────────────────────────────────────────
wl-copy < "$TMP_TXT"

# ── open viewer ───────────────────────────────────────────────────────────────
open_viewer() {
    local file="$1"

    case "$VIEWER" in
        clipboard)
            # already done above — nothing extra to open
            ;;

        zenity)
            zenity --text-info \
                --title="OCR Result" \
                --filename="$file" \
                --width=600 --height=400 \
                --font="monospace 11" &
            ;;

        yad)
            yad --text-info \
                --title="OCR Result" \
                --filename="$file" \
                --width=600 --height=400 \
                --button="Close":0 &
            ;;

        term)
            # Open file in terminal editor; keep alive until user closes it
            "$TERM_CMD" -e "$EDITOR_CMD" "$file" &
            ;;

        auto|*)
            # Prefer zenity → yad → term → clipboard-only fallback
            if command -v zenity &>/dev/null; then
                VIEWER=zenity; open_viewer "$file"
            elif command -v yad &>/dev/null; then
                VIEWER=yad;    open_viewer "$file"
            elif command -v "$TERM_CMD" &>/dev/null; then
                VIEWER=term;   open_viewer "$file"
            else
                # nothing to open — clipboard is already set, just notify
                command -v notify-send &>/dev/null && \
                    notify-send -u normal "OCR" "Text copied to clipboard (no viewer found)."
            fi
            ;;
    esac
}

# If --save, persist files first so the viewer can keep them open after cleanup
if $SAVE; then
    mkdir -p "$SCREENSHOTS_DIR"
    DEST_IMG="$SCREENSHOTS_DIR/ocr_${TIMESTAMP}.png"
    DEST_TXT="$SCREENSHOTS_DIR/ocr_${TIMESTAMP}.txt"
    cp "$TMP_IMG" "$DEST_IMG"
    cp "$TMP_TXT" "$DEST_TXT"
    command -v notify-send &>/dev/null && \
        notify-send -u low -i edit-copy "OCR" "Saved:\n• $DEST_TXT"
    open_viewer "$DEST_TXT"   # open the permanent copy
else
    # Copy tmp file to a stable path so it survives cleanup while viewer is open
    VIEWER_TMP="$(mktemp /tmp/ocr_view_XXXXXX.txt)"
    cp "$TMP_TXT" "$VIEWER_TMP"
    open_viewer "$VIEWER_TMP"
    # Clean up viewer tmp after a generous delay (viewer is backgrounded)
    ( sleep 300 && rm -f "$VIEWER_TMP" ) &
fi

# ── cleanup originals ─────────────────────────────────────────────────────────
rm -f "$TMP_IMG" "$TMP_BASE" "$TMP_TXT"
