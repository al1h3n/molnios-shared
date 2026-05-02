#!/usr/bin/env bash
# whereami.sh — Public IP & location data provider
# Usage: ./whereami.sh [OPTIONS]

set -euo pipefail

# ─── Helpers ──────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

  With no options, all fields are printed in a human-readable table.
  Use --export to emit KEY=value pairs suitable for eval in shell functions.

Options:
  -i, --ip          Public IP address
  -c, --city        City
  -r, --region      Region / State
  -C, --country     Country
  -g, --coords      Latitude & Longitude
  -s, --isp         ISP / Organisation
  -e, --export      Emit shell KEY=value pairs (for eval in shell functions)
  -h, --help        Show this help message

Examples:
  $(basename "$0")               # Print all fields
  $(basename "$0") --export      # KEY=value pairs for eval
  $(basename "$0") -i            # IP only
  $(basename "$0") -i -g         # IP + coordinates
EOF
}

fetch_data() {
  if ! DATA=$(curl -sf --max-time 10 "https://ipinfo.io/json"); then
    echo "Error: Could not reach ipinfo.io. Check your internet connection." >&2
    exit 1
  fi
}

get_field() {
  echo "$DATA" | grep -o "\"$1\": *\"[^\"]*\"" | sed 's/.*": *"\(.*\)"/\1/'
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--ip)      SHOW_IP=true;      SHOW_ALL=false ;;
    -c|--city)    SHOW_CITY=true;    SHOW_ALL=false ;;
    -r|--region)  SHOW_REGION=true;  SHOW_ALL=false ;;
    -C|--country) SHOW_COUNTRY=true; SHOW_ALL=false ;;
    -g|--coords)  SHOW_COORDS=true;  SHOW_ALL=false ;;
    -s|--isp)     SHOW_ISP=true;     SHOW_ALL=false ;;
    -e|--export)  EXPORT_MODE=true;  SHOW_ALL=false ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

# ─── Fetch & parse ────────────────────────────────────────────────────────────

fetch_data

IP=$(get_field "ip")
CITY=$(get_field "city")
REGION=$(get_field "region")
COUNTRY=$(get_field "country")
LOC=$(get_field "loc")
ORG=$(get_field "org")
LAT="${LOC%%,*}"
LON="${LOC##*,}"

# ─── Output ───────────────────────────────────────────────────────────────────

print_field() {
  printf "  %-14s %s\n" "$1:" "$2"
}

if $EXPORT_MODE; then
  # Emit KEY=value pairs — safe for eval in shell functions
  printf 'WHEREAMI_IP=%q\n'      "$IP"
  printf 'WHEREAMI_CITY=%q\n'    "$CITY"
  printf 'WHEREAMI_REGION=%q\n'  "$REGION"
  printf 'WHEREAMI_COUNTRY=%q\n' "$COUNTRY"
  printf 'WHEREAMI_LAT=%q\n'     "$LAT"
  printf 'WHEREAMI_LON=%q\n'     "$LON"
  printf 'WHEREAMI_ISP=%q\n'     "$ORG"
  exit 0
fi

if $SHOW_ALL || $SHOW_IP;      then print_field "IP"        "$IP";      fi
if $SHOW_ALL || $SHOW_CITY;    then print_field "City"      "$CITY";    fi
if $SHOW_ALL || $SHOW_REGION;  then print_field "Region"    "$REGION";  fi
if $SHOW_ALL || $SHOW_COUNTRY; then print_field "Country"   "$COUNTRY"; fi
if $SHOW_ALL || $SHOW_COORDS;  then print_field "Latitude"  "$LAT"
                                    print_field "Longitude" "$LON";     fi
if $SHOW_ALL || $SHOW_ISP;     then print_field "ISP"       "$ORG";     fi