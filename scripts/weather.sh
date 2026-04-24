#!/usr/bin/env bash
# Fetches weather from wttr.in and outputs Waybar JSON
# Flags:
#   -l <location>  set location (city/region/country), like  "new york"
#   -i             show weather icon
#   -c             show temperature in °C (default)
#   -f             show temperature in °F
#   -k             show temperature in °K
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
    *) echo "Usage: $0 [-l location] [-i] [-c|-f|-k]" >&2; exit 1 ;;
  esac
done

DATA=$(curl -sf "https://wttr.in/${LOCATION}?format=j1" 2>/dev/null)

if [[ -z "$DATA" ]]; then
    TITLE=$(hyprctl activewindow -j 2>/dev/null | jq -r '.title // "No Window"')
    echo "{\"text\":\"󰖚  N/A\",\"tooltip\":\"${TITLE}\",\"class\":\"offline\"}"
    exit 0
fi

TEMP_C=$(echo "$DATA" | jq -r '.current_condition[0].temp_C')
TEMP_F=$(echo "$DATA" | jq -r '.current_condition[0].temp_F')
FEEL_C=$(echo "$DATA" | jq -r '.current_condition[0].FeelsLikeC')
FEEL_F=$(echo "$DATA" | jq -r '.current_condition[0].FeelsLikeF')
DESC=$(echo "$DATA"   | jq -r '.current_condition[0].weatherDesc[0].value')
WIND=$(echo "$DATA"   | jq -r '.current_condition[0].windspeedKmph')
HUMID=$(echo "$DATA"  | jq -r '.current_condition[0].humidity')
CODE=$(echo "$DATA"   | jq -r '.current_condition[0].weatherCode')

# C -> K: add 273.15, round to 2 decimal places
to_kelvin() { echo "$1" | awk '{printf "%.2f", $1 + 273.15}'; }

weather_icon() {
    local code=$1
    case $code in
        113)                         echo "☀️"  ;;
        116)                         echo "⛅"  ;;
        119|122)                     echo "☁️"  ;;
        143|248|260)                 echo "🌫️"  ;; # Mist/fog.
        176|263|266|293|296)         echo "🌦️"  ;;
        179|227|230)                 echo "❄️"  ;;
        182|185|281|284|311|314|\
        317|350|377|299|302|305|308) echo "🌧️"  ;;
        200|386|389|392|395)         echo "⛈️"  ;;
        323|326|329|332|335|338|\
        368|371|374)                 echo "🌨️"  ;;
        *)                           echo "🌡️"  ;;
    esac
}

case $UNIT in
    F) TEMP="${TEMP_F}°F"; FEEL="${FEEL_F}°F" ;;
    K) TEMP="$(to_kelvin "$TEMP_C")°K"; FEEL="$(to_kelvin "$FEEL_C")°K" ;;
    *) TEMP="${TEMP_C}°C"; FEEL="${FEEL_C}°C" ;;
esac

if [[ "$SHOW_ICON" == true ]]; then
    ICON=$(weather_icon "$CODE")
    TEXT="${ICON} ${TEMP}"
else
    TEXT="${TEMP}"
fi

TEMP_K="$(to_kelvin "$TEMP_C")°K"
LOC_LABEL="${LOCATION:-$(hostname)}"
TOOLTIP="${DESC}\nCurrent weather in ${LOC_LABEL}: ${TEMP_C}°C, ${TEMP_K}, ${TEMP_F}°F\nFeels like: ${FEEL}\nHumidity: ${HUMID}%\nWind: ${WIND} km/h"

echo "{\"text\":\"${TEXT}\",\"tooltip\":\"${TOOLTIP}\",\"class\":\"weather\"}"