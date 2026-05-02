#!/usr/bin/env bash
# Fetches weather from wttr.in and outputs Waybar JSON
#
# Flags:
#   -l <location>   set location (city/region/country), like "new york"
#   -i              show weather icon
#   -c              show temperature in °C (default)
#   -f              show temperature in °F
#   -k              show temperature in °K

LOCATION="${WEATHER_LOCATION:-}"
SHOW_ICON=false
UNIT="C"

while getopts "l:icfk" opt; do
  case $opt in
    l) LOCATION="$OPTARG" ;;
    i) SHOW_ICON=true ;;
    c) UNIT="C" ;;
    f) UNIT="F" ;;
    k) UNIT="K" ;;
    *)
      echo "Usage: $0 [-l location] [-i] [-c|-f|-k]" >&2
      exit 1
      ;;
  esac
done

DATA=$(curl -sf "wttr.in/${LOCATION}?format=j1" 2>/dev/null)

if [[ -z "$DATA" ]]; then
  echo '{"text":"󰖚 N/A","tooltip":"Weather unavailable (offline)","class":"offline"}'
  exit 0
fi

# --- Current conditions ---
TEMP_C=$(echo "$DATA" | jq -r '.current_condition[0].temp_C')
TEMP_F=$(echo "$DATA" | jq -r '.current_condition[0].temp_F')
FEEL_C=$(echo "$DATA" | jq -r '.current_condition[0].FeelsLikeC')
FEEL_F=$(echo "$DATA" | jq -r '.current_condition[0].FeelsLikeF')
DESC=$(echo "$DATA"   | jq -r '.current_condition[0].weatherDesc[0].value')
WIND=$(echo "$DATA"   | jq -r '.current_condition[0].windspeedKmph')
HUMID=$(echo "$DATA"  | jq -r '.current_condition[0].humidity')
VISIB=$(echo "$DATA"  | jq -r '.current_condition[0].visibility')
PRESS=$(echo "$DATA"  | jq -r '.current_condition[0].pressure')
UV=$(echo "$DATA"     | jq -r '.current_condition[0].uvIndex')
CODE=$(echo "$DATA"   | jq -r '.current_condition[0].weatherCode')

# --- Astronomy (today) ---
SUNRISE=$(echo "$DATA" | jq -r '.weather[0].astronomy[0].sunrise')
SUNSET=$(echo "$DATA"  | jq -r '.weather[0].astronomy[0].sunset')

# --- Tomorrow forecast (optional tooltip bonus) ---
TMRW_MAX_C=$(echo "$DATA" | jq -r '.weather[1].maxtempC')
TMRW_MIN_C=$(echo "$DATA" | jq -r '.weather[1].mintempC')
TMRW_DESC=$(echo "$DATA"  | jq -r '.weather[1].hourly[4].weatherDesc[0].value')

# --- Unit helpers ---
to_kelvin() { echo "$1" | awk '{printf "%.2f", $1 + 273.15}'; }

weather_icon() {
  local code=$1
  case $code in
    113)                                           echo "󰖨 "  ;;
    116)                                           echo " "  ;;
    119|122)                                       echo "󰅟 "  ;;
    143|248|260)                                   echo "󰖑 " ;;
    176|263|266|293|296)                           echo " " ;;
    179|227|230)                                   echo " "  ;;
    182|185|281|284|311|314|317|350|377| \
      299|302|305|308)                             echo " " ;;
    200|386|389|392|395)                           echo "󰖓 " ;;
    323|326|329|332|335|338|368|371|374)           echo " " ;;
    *)                                             echo "󱣶 " ;;
  esac
}

# --- Resolve display temperature ---
TEMP_K="$(to_kelvin "$TEMP_C")°K"
FEEL_K="$(to_kelvin "$FEEL_C")°K"

case $UNIT in
  F) TEMP="${TEMP_F}°F"; FEEL="${FEEL_F}°F" ;;
  K) TEMP="${TEMP_K}";   FEEL="${FEEL_K}"   ;;
  *) TEMP="${TEMP_C}°C"; FEEL="${FEEL_C}°C" ;;
esac

# --- Build text ---
if [[ "$SHOW_ICON" == true ]]; then
  ICON=$(weather_icon "$CODE")
  TEXT="${ICON} ${TEMP}"
else
  TEXT="${TEMP}"
fi

# --- Build tooltip (all params) ---
LOC_LABEL="${LOCATION:-$(hostname)}"

TOOLTIP="$(cat <<EOF
${DESC}  ·  ${LOC_LABEL}

 Temperature: ${TEMP_C}°C  |  ${TEMP_F}°F  |  ${TEMP_K}
 Feels like : ${FEEL}
󰖌 Humidity   : ${HUMID}%
 Wind       : ${WIND} km/h
󰈈 Visibility : ${VISIB} km
󰄠 Pressure   : ${PRESS} hPa
󱩷 UV Index   : ${UV}

󰖜 Sunrise: ${SUNRISE}
󰖛 Sunset: ${SUNSET}

 Tomorrow: ${TMRW_DESC}
High / Low : ${TMRW_MAX_C}°C / ${TMRW_MIN_C}°C
EOF
)"

# Escape for JSON: replace \ with \\, " with \", newlines with \n
TOOLTIP_JSON=$(echo "$TOOLTIP" | jq -Rsa .)

echo "{\"text\":\"${TEXT}\",\"tooltip\":${TOOLTIP_JSON},\"class\":\"weather\"}"