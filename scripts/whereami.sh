#!/usr/bin/env bash
# myip.sh — Public IP & location data provider
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

  With no options, all fields are printed with labels and icons.
  Specific flags print bare values — ideal for scripts and waybar.
  Use --export to emit KEY=value pairs suitable for eval in shell functions.

Options:
  -i, --ip             Public IP address
  -c, --city           City
  -r, --region         Region / State
  -C, --country        Country (full name, e.g. "United States")
  -g, --coords         Latitude,Longitude on one line
  -s, --isp            ISP / Organisation
  -e, --export         Emit shell KEY=value pairs
  -S, --spacing <n>    Spaces between icon/label and value (default: 2)
  -h, --help           Show this help message
EOF
}

fetch_data() {
  if ! DATA=$(curl -sf --max-time 10 "https://ipinfo.io/json"); then
    echo "Error: Could not reach ipinfo.io." >&2
    exit 1
  fi
}

get_field() {
  echo "$DATA" | grep -o "\"$1\": *\"[^\"]*\"" | sed 's/.*": *"\(.*\)"/\1/'
}

resolve_country() {
  local code="${1^^}"
  local name=""
  name=$(curl -sf --max-time 5 \
    "https://restcountries.com/v3.1/alpha/${code}?fields=name" 2>/dev/null \
    | grep -o '"common":"[^"]*"' \
    | head -1 \
    | sed 's/"common":"//;s/"$//') || name=""
  printf '%s' "${name:-$code}"
}

labeled() {
  local icon="$1" label="$2" value="$3"
  local pad
  pad=$(printf '%*s' "$SPACING" '')
  printf '%s  %s%s%s%s\n' "$icon" "$pad" "$label" ": " "$value"
}

# ─── Argument parsing ─────────────────────────────────────────────────────────
SHOW_IP=false
SHOW_CITY=false
SHOW_REGION=false
SHOW_COUNTRY=false
SHOW_COORDS=false
SHOW_ISP=false
SHOW_ALL=true
EXPORT_MODE=false
SPACING=2

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--ip)      SHOW_IP=true;      SHOW_ALL=false ;;
    -c|--city)    SHOW_CITY=true;    SHOW_ALL=false ;;
    -r|--region)  SHOW_REGION=true;  SHOW_ALL=false ;;
    -C|--country) SHOW_COUNTRY=true; SHOW_ALL=false ;;
    -g|--coords)  SHOW_COORDS=true;  SHOW_ALL=false ;;
    -s|--isp)     SHOW_ISP=true;     SHOW_ALL=false ;;
    -e|--export)  EXPORT_MODE=true;  SHOW_ALL=false ;;
    -S|--spacing)
      [[ -z "${2-}" || ! "$2" =~ ^[0-9]+$ ]] && {
        echo "Error: --spacing requires a non-negative integer." >&2; exit 1
      }
      SPACING="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

# ─── Fetch & parse ────────────────────────────────────────────────────────────
fetch_data

IP=$(get_field "ip")
CITY=$(get_field "city")
REGION=$(get_field "region")
COUNTRY_CODE=$(get_field "country")
LOC=$(get_field "loc")
ORG=$(get_field "org")
LAT="${LOC%%,*}"
LON="${LOC##*,}"

COUNTRY="$COUNTRY_CODE"
if $SHOW_ALL || $SHOW_COUNTRY || $EXPORT_MODE; then
  COUNTRY=$(resolve_country "$COUNTRY_CODE")
fi

# ─── Output ───────────────────────────────────────────────────────────────────
if $EXPORT_MODE; then
  printf 'WHEREAMI_IP=%q\n'      "$IP"
  printf 'WHEREAMI_CITY=%q\n'    "$CITY"
  printf 'WHEREAMI_REGION=%q\n'  "$REGION"
  printf 'WHEREAMI_COUNTRY=%q\n' "$COUNTRY"
  printf 'WHEREAMI_LAT=%q\n'     "$LAT"
  printf 'WHEREAMI_LON=%q\n'     "$LON"
  printf 'WHEREAMI_ISP=%q\n'     "$ORG"
  exit 0
fi

if $SHOW_ALL; then
  labeled "󰩟" "IP" "$IP"
  labeled "󰏠" "City" "$CITY"
  labeled "󰦉" "Region" "$REGION"
  labeled "󰐇" "Country" "$COUNTRY"
  labeled "󰓾" "Latitude" "$LAT"
  labeled "󰓾" "Longitude" "$LON"
  labeled "󰛳" "ISP" "$ORG"
else
  $SHOW_IP      && echo "$IP"
  $SHOW_CITY    && echo "$CITY"
  $SHOW_REGION  && echo "$REGION"
  $SHOW_COUNTRY && echo "$COUNTRY"
  $SHOW_COORDS  && echo "$LAT,$LON"
  $SHOW_ISP     && echo "$ORG"
fi

exit 0