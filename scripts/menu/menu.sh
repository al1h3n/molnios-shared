# MM    MM              dd           bb                         lll  1  hh      333333
# MMM  MMM   aa aa      dd   eee     bb      yy   yy      aa aa lll 111 hh         3333 nn nnn
# MM MM MM  aa aaa  dddddd ee   e    bbbbbb  yy   yy     aa aaa lll  11 hhhhhh    3333  nnn  nn
# MM    MM aa  aaa dd   dd eeeee     bb   bb  yyyyyy    aa  aaa lll  11 hh   hh     333 nn   nn
# MM    MM  aaa aa  dddddd  eeeee    bbbbbb       yy     aaa aa lll 111 hh   hh 333333  nn   nn
#                                             yyyyy
# Support - al1h3n(tg,ds) | Donate me - ko-fi.com/al1h3n
# Menu generator - Part of the molniux project.
# ==============================================================================

# Usage: menu.sh [OPTIONS]
#
# Examples:
#   # Static list
#   menu.sh -t "Power Menu" -i "Shutdown,Reboot,Suspend,Logout" -e "handle_power.sh"
#
#   # Wallpaper switcher (files from dir)
#   menu.sh -t "Wallpapers" -d ~/Pictures/wallpapers -f "jpg,png,webp" -e "feh --bg-fill"
#
#   # Theme switcher (scripts from dir)
#   menu.sh -t "Themes" -s ~/.config/themes/ -x
#
#   # With a config file
#   menu.sh -c ~/.config/menu/style.conf -t "Apps" -i "Firefox,Terminal,Files"
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
BACKEND=""           # auto-detect if empty
TITLE="Menu"
WIDTH=300
HEIGHT=200           # pixel height (yad) or line count (rofi uses -l)
ROFI_LINES=10        # number of visible lines for rofi
CONFIG_FILE=""
ITEMS=""             # comma-separated static items
ITEM_DIR=""          # directory: list files as items
SCRIPT_DIR=""        # directory: list executables as items
EXEC_CMD=""          # command to run with selected item as argument
EXEC_ITEM=false      # execute the selected item directly
FILE_FILTER=""       # e.g. "png,jpg,webp" (used with -d)
SHOW_HIDDEN=false
STRIP_EXT=false      # strip file extension from display name
PROMPT=""            # rofi prompt label (falls back to TITLE)
SEPARATOR=","

# ---------------------------------------------------------------------------
# Config file defaults (overridden by config, then by CLI flags)
# ---------------------------------------------------------------------------
CF_BACKEND=""
CF_WIDTH=""
CF_HEIGHT=""
CF_ROFI_LINES=""
CF_ROFI_THEME=""
CF_ROFI_THEME_STR=""
CF_YAD_STYLE=""
CF_FONT=""
CF_BG=""
CF_FG=""
CF_ACCENT=""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
die()  { echo "Error: $*" >&2; exit 1; }
info() { echo "Info: $*" >&2; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Backend:
  -b, --backend  <rofi|yad>      Force a backend (default: auto-detect)

Appearance:
  -c, --config   <file>          Config file (key=value, see below)
  -w, --width    <px>            Window width  (default: $WIDTH)
  -H, --height   <px|lines>      Window height in px (yad) or lines (rofi)
                                  (default: $HEIGHT / $ROFI_LINES)

Menu content (pick one or combine):
  -t, --title    <string>        Menu title / rofi prompt (default: "$TITLE")
  -i, --items    <a,b,c>         Static comma-separated item list
  -d, --dir      <path>          List files in directory as items
  -s, --scripts  <path>          List executables in directory as items
  -f, --filter   <ext,ext>       File extension filter for --dir (e.g. png,jpg)
      --strip-ext                Strip extension from filenames in the menu
      --hidden                   Include hidden files when using --dir / --scripts
      --separator <char>         Separator for --items (default: ,)

Action:
  -e, --exec     <cmd>           Run this command with selected item as argument
  -x, --exec-item                Execute the selected item directly (scripts)
      --print                    Just print selection to stdout (default if no -e/-x)

Other:
  -h, --help                     Show this help

Config file format (~/.config/menu/style.conf):
  BACKEND=rofi
  WIDTH=400
  HEIGHT=15            # lines for rofi, pixels for yad
  ROFI_THEME=/path/to/theme.rasi
  ROFI_THEME_STR=window{width:400px;}
  YAD_STYLE=.background{background:#1e1e2e;}
  FONT=Monospace 11
  BG=#1e1e2e
  FG=#cdd6f4
  ACCENT=#89b4fa
EOF
  exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -b|--backend)    BACKEND="$2";    shift 2 ;;
      -c|--config)     CONFIG_FILE="$2"; shift 2 ;;
      -w|--width)      WIDTH="$2";      shift 2 ;;
      -H|--height)     HEIGHT="$2"; ROFI_LINES="$2"; shift 2 ;;
      -t|--title)      TITLE="$2";      shift 2 ;;
      -i|--items)      ITEMS="$2";      shift 2 ;;
      -d|--dir)        ITEM_DIR="$2";   shift 2 ;;
      -s|--scripts)    SCRIPT_DIR="$2"; shift 2 ;;
      -f|--filter)     FILE_FILTER="$2"; shift 2 ;;
      -e|--exec)       EXEC_CMD="$2";   shift 2 ;;
      -x|--exec-item)  EXEC_ITEM=true;  shift ;;
      --strip-ext)     STRIP_EXT=true;  shift ;;
      --hidden)        SHOW_HIDDEN=true; shift ;;
      --separator)     SEPARATOR="$2";  shift 2 ;;
      --print)         EXEC_CMD=""; EXEC_ITEM=false; shift ;;
      -h|--help)       usage ;;
      *) die "Unknown option: $1. Use --help for usage." ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Load config file
# ---------------------------------------------------------------------------
load_config() {
  [[ -z "$CONFIG_FILE" ]] && return
  [[ ! -f "$CONFIG_FILE" ]] && die "Config file not found: $CONFIG_FILE"

  while IFS='=' read -r key value; do
    # skip comments and blank lines
    [[ "$key" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$key" ]] && continue
    key="${key%%[[:space:]]*}"   # trim trailing spaces
    value="${value#"${value%%[![:space:]]*}"}"  # trim leading spaces
    case "$key" in
      BACKEND)         CF_BACKEND="$value" ;;
      WIDTH)           CF_WIDTH="$value" ;;
      HEIGHT)          CF_HEIGHT="$value" ;;
      ROFI_LINES)      CF_ROFI_LINES="$value" ;;
      ROFI_THEME)      CF_ROFI_THEME="$value" ;;
      ROFI_THEME_STR)  CF_ROFI_THEME_STR="$value" ;;
      YAD_STYLE)       CF_YAD_STYLE="$value" ;;
      FONT)            CF_FONT="$value" ;;
      BG)              CF_BG="$value" ;;
      FG)              CF_FG="$value" ;;
      ACCENT)          CF_ACCENT="$value" ;;
    esac
  done < "$CONFIG_FILE"

  # Apply config values (CLI flags will override these later if re-parsed,
  # but since we load config first, CLI already won via parse order)
  [[ -n "$CF_BACKEND" && -z "$BACKEND" ]]         && BACKEND="$CF_BACKEND"
  [[ -n "$CF_WIDTH"   && "$WIDTH" == "300" ]]      && WIDTH="$CF_WIDTH"
  [[ -n "$CF_HEIGHT"  && "$HEIGHT" == "200" ]]     && HEIGHT="$CF_HEIGHT"
  [[ -n "$CF_ROFI_LINES" && "$ROFI_LINES" == "10" ]] && ROFI_LINES="$CF_ROFI_LINES"
}

# ---------------------------------------------------------------------------
# Detect backend
# ---------------------------------------------------------------------------
detect_backend() {
  if [[ -n "$BACKEND" ]]; then
    command -v "$BACKEND" &>/dev/null || die "Backend '$BACKEND' not found in PATH"
    return
  fi
  if command -v rofi &>/dev/null; then
    BACKEND="rofi"
  elif command -v yad &>/dev/null; then
    BACKEND="yad"
  else
    die "No supported backend found. Install rofi or yad."
  fi
  info "Auto-detected backend: $BACKEND"
}

# ---------------------------------------------------------------------------
# Build item list
# ---------------------------------------------------------------------------
build_items() {
  local list=""

  # 1. Static items
  if [[ -n "$ITEMS" ]]; then
    list+=$(echo "$ITEMS" | tr "$SEPARATOR" '\n')
    list+=$'\n'
  fi

  # 2. Files from directory
  if [[ -n "$ITEM_DIR" ]]; then
    [[ -d "$ITEM_DIR" ]] || die "Directory not found: $ITEM_DIR"

    local find_args=("$ITEM_DIR" -maxdepth 1 -type f)
    $SHOW_HIDDEN || find_args+=( ! -name '.*' )

    local files
    files=$(find "${find_args[@]}" | sort)

    # apply extension filter
    if [[ -n "$FILE_FILTER" ]]; then
      local ext_pattern
      ext_pattern=$(echo "$FILE_FILTER" | tr ',' '|')
      files=$(echo "$files" | grep -E "\.(${ext_pattern})$" || true)
    fi

    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      local name; name=$(basename "$f")
      $STRIP_EXT && name="${name%.*}"
      list+="$name"$'\n'
    done <<< "$files"
  fi

  # 3. Executables from directory (scripts)
  if [[ -n "$SCRIPT_DIR" ]]; then
    [[ -d "$SCRIPT_DIR" ]] || die "Script directory not found: $SCRIPT_DIR"

    local find_args=("$SCRIPT_DIR" -maxdepth 1 -type f -executable)
    $SHOW_HIDDEN || find_args+=( ! -name '.*' )

    local scripts
    scripts=$(find "${find_args[@]}" | sort)

    while IFS= read -r s; do
      [[ -z "$s" ]] && continue
      local name; name=$(basename "$s")
      $STRIP_EXT && name="${name%.*}"
      list+="$name"$'\n'
    done <<< "$scripts"
  fi

  # Remove trailing newline, deduplicate
  echo "$list" | sed '/^$/d' | awk '!seen[$0]++'
}

# ---------------------------------------------------------------------------
# Resolve full path for a selected item
# (needed when displaying stripped names or when exec-item is used)
# ---------------------------------------------------------------------------
resolve_path() {
  local selected="$1"

  # Check ITEM_DIR
  if [[ -n "$ITEM_DIR" ]]; then
    local find_args=("$ITEM_DIR" -maxdepth 1 -type f)
    while IFS= read -r f; do
      local name; name=$(basename "$f")
      $STRIP_EXT && name="${name%.*}"
      [[ "$name" == "$selected" ]] && { echo "$f"; return; }
    done < <(find "${find_args[@]}" | sort)
  fi

  # Check SCRIPT_DIR
  if [[ -n "$SCRIPT_DIR" ]]; then
    local find_args=("$SCRIPT_DIR" -maxdepth 1 -type f -executable)
    while IFS= read -r s; do
      local name; name=$(basename "$s")
      $STRIP_EXT && name="${name%.*}"
      [[ "$name" == "$selected" ]] && { echo "$s"; return; }
    done < <(find "${find_args[@]}" | sort)
  fi

  # Return as-is (static item or already a path)
  echo "$selected"
}

# ---------------------------------------------------------------------------
# Build rofi theme string from config
# ---------------------------------------------------------------------------
rofi_theme_str() {
  local parts=""
  [[ -n "$CF_ROFI_THEME_STR" ]] && parts+="$CF_ROFI_THEME_STR "

  local inline=""
  [[ -n "$CF_BG" ]]     && inline+="background-color:${CF_BG};"
  [[ -n "$CF_FG" ]]     && inline+="text-color:${CF_FG};"
  [[ -n "$CF_FONT" ]]   && parts+="* {font:\"${CF_FONT}\";} "
  [[ -n "$inline" ]]    && parts+="window{${inline}} "
  [[ -n "$CF_ACCENT" ]] && parts+="element selected{background-color:${CF_ACCENT};} "
  parts+="window{width:${WIDTH}px;} "

  echo "$parts"
}

# ---------------------------------------------------------------------------
# Show menu with rofi
# ---------------------------------------------------------------------------
show_rofi() {
  local items="$1"
  local prompt="${PROMPT:-$TITLE}"
  local theme_str; theme_str=$(rofi_theme_str)

  local rofi_args=(
    -dmenu
    -p "$prompt"
    -l "$ROFI_LINES"
    -theme-str "$theme_str"
  )

  [[ -n "$CF_ROFI_THEME" ]] && rofi_args+=(-theme "$CF_ROFI_THEME")

  echo "$items" | rofi "${rofi_args[@]}"
}

# ---------------------------------------------------------------------------
# Show menu with yad
# ---------------------------------------------------------------------------
show_yad() {
  local items="$1"

  local yad_args=(
    --list
    --title="$TITLE"
    --column="$TITLE"
    --width="$WIDTH"
    --height="$HEIGHT"
    --no-headers
    --print-column=1
    --separator=$'\n'
  )

  [[ -n "$CF_FONT" ]]      && yad_args+=(--font="$CF_FONT")
  [[ -n "$CF_YAD_STYLE" ]] && yad_args+=(--css=<(echo "$CF_YAD_STYLE"))

  echo "$items" | while IFS= read -r item; do
    echo "$item"
  done | xargs yad "${yad_args[@]}" | head -n1
}

# ---------------------------------------------------------------------------
# Execute action on selection
# ---------------------------------------------------------------------------
run_action() {
  local selected="$1"
  [[ -z "$selected" ]] && exit 0   # user cancelled

  local target
  target=$(resolve_path "$selected")

  if $EXEC_ITEM; then
    [[ -x "$target" ]] || die "Selected item is not executable: $target"
    exec "$target"
  elif [[ -n "$EXEC_CMD" ]]; then
    eval "$EXEC_CMD \"$target\""
  else
    echo "$selected"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  parse_args "$@"
  load_config
  detect_backend

  local items
  items=$(build_items)

  [[ -z "$items" ]] && die "No items to display. Use -i, -d, or -s."

  local selected=""
  case "$BACKEND" in
    rofi) selected=$(show_rofi "$items") ;;
    yad)  selected=$(show_yad  "$items") ;;
    *)    die "Unsupported backend: $BACKEND" ;;
  esac

  run_action "$selected"
}

main "$@"