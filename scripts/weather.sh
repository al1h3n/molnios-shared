# Fetches weather from wttr.in and outputs Waybar JSON
# Requires jq, curl packages.
# Flags:
#   -l <location>   set location (city/region/country), like "new york"
#   -i              show weather icon
#   -c              show temperature in °C (default)
#   -f              show temperature in °F
#   -k              show temperature in °K
#   -p <n>          spaces between every icon and its text (default: 2, SF Pro needs 3)
# Plain-text output (hyprlock):
#   <ICON>  29°C
#   Feels like: <ICON>  +27°C
#
# JSON output (Waybar, -j):
#   {"text":"…","tooltip":"…","class":"weather"}
#
# Waybar config example:
#   "exec": "sh weather.sh -j -i -l frankfurt -p 3"
#
# Hyprlock config example:
#   text = cmd[update:300] echo "$(sh weather.sh -i -l frankfurt -p 3)"

if [[ -n "${WEATHER_LOCATION:-}" ]];then
  LOCATION="$WEATHER_LOCATION"
elif [[ -f "$HOME/.weather" ]];then
  LOCATION=$(tr -d '[:space:]' < "$HOME/.weather")
else
  LOCATION=""
fi
SHOW_ICON=false
JSON_MODE=false
UNIT="C"
ICON_PAD=1

while getopts "l:ijcfkp:" opt; do
  case $opt in
    l) LOCATION="$OPTARG" ;;
    i) SHOW_ICON=true ;;
    j) JSON_MODE=true ;;
    c) UNIT="C" ;;
    f) UNIT="F" ;;
    k) UNIT="K" ;;
    p) ICON_PAD="$OPTARG" ;;
    *)
      echo "Usage: $0 [-l location] [-i] [-c|-f|-k] [-p spaces]" >&2
      exit 1
      ;;
  esac
done

SEP="$(printf '%*s' "$ICON_PAD" '')"
DATA=$(curl -sf "wttr.in/${LOCATION}?format=j1" 2>/dev/null)

if [[ -z "$DATA" ]]; then
  if [[ "$JSON_MODE" == true ]]; then
    echo '{"text":"󰖚'$SEP'N/A","tooltip":"Weather unavailable (offline)","class":"offline"}'
  else
    echo "󰖚${SEP}N/A"
    echo "Weather is unavailable (offline)"
  fi
  exit 0
fi

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

SUNRISE=$(echo "$DATA" | jq -r '.weather[0].astronomy[0].sunrise')
SUNSET=$(echo "$DATA"  | jq -r '.weather[0].astronomy[0].sunset')

TMRW_DESC=$(echo "$DATA"  | jq -r '.weather[1].hourly[4].weatherDesc[0].value')
TMRW_MAX_C=$(echo "$DATA" | jq -r '.weather[1].maxtempC')
TMRW_MIN_C=$(echo "$DATA" | jq -r '.weather[1].mintempC')
TMRW_SUNRISE=$(echo "$DATA" | jq -r '.weather[1].astronomy[0].sunrise')
TMRW_SUNSET=$(echo "$DATA"  | jq -r '.weather[1].astronomy[0].sunset')

capitalize() { echo "$1" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print}'; }
CITY_RAW=$(echo "$DATA"    | jq -r '.nearest_area[0].areaName[0].value')
COUNTRY_RAW=$(echo "$DATA" | jq -r '.nearest_area[0].country[0].value')
CITY=$(capitalize "$CITY_RAW")
COUNTRY=$(capitalize "$COUNTRY_RAW")
LOC_LABEL="${CITY}, ${COUNTRY}"

to_kelvin() { echo "$1" | awk '{printf "%.2f", $1 + 273.15}'; }

weather_icon() {
  local code=$1
  case $code in
    113)                                 echo "󰖨";;
    116)                                 echo "";;
    119|122)                             echo "󰅟";;
    143|248|260)                         echo "󰖑";;
    176|263|266|293|296)                 echo "";;
    179|227|230)                         echo "";;
    182|185|281|284|311|314|317|350|377| \
      299|302|305|308)                   echo "";;
    200|386|389|392|395)                 echo "󰖓";;
    323|326|329|332|335|338|368|371|374) echo "";;
    *)                                   echo "󱣶";;
  esac
}

TEMP_K="$(to_kelvin "$TEMP_C")°K"
FEEL_K="$(to_kelvin "$FEEL_C")°K"

case $UNIT in
  F) TEMP="${TEMP_F}°F"; FEEL="${FEEL_F}°F" ;;
  K) TEMP="${TEMP_K}";   FEEL="${FEEL_K}"   ;;
  *) TEMP="${TEMP_C}°C"; FEEL="${FEEL_C}°C" ;;
esac

ICON=$(weather_icon "$CODE")

if [[ "$SHOW_ICON" == true ]]; then
  TEXT="${ICON}${SEP}${TEMP}"
else
  TEXT="${TEMP}"
fi

if [[ "$JSON_MODE" == false ]]; then
  printf "Feels like: %s" "$TEXT"
  exit 0
fi

# Icons with separator.
TI_TEMP="${SEP}Temperature:"
TI_FEEL="${SEP}Feels like:"
TI_HUMID="󰖌${SEP}Humidity:"
TI_WIND="${SEP}Wind:"
TI_VIS="󰈈${SEP}Visibility:"
TI_PRESS="󰄠${SEP}Pressure:"
TI_UV="󱩷${SEP}UV Index:"
TI_RISE="󰖜${SEP}Sunrise:"
TI_SET="󰖛${SEP}Sunset:"
TI_TMRW="${SEP}Tomorrow:"
TI_HL="${SEP}High/Low:"

TI_RISE_1="󰖜${SEP}Sunrise tomorrow:"
TI_SET_1="󰖛${SEP}Sunset tomorrow:"

TOOLTIP="$(cat <<EOF
${DESC} - ${LOC_LABEL:-$(hostname)}
${TI_TEMP} ${TEMP_C}°C | ${TEMP_F}°F | ${TEMP_K}
${TI_FEEL} ${FEEL}
${TI_HUMID} ${HUMID}%
${TI_WIND} ${WIND} km/h
${TI_VIS} ${VISIB} km
${TI_PRESS} ${PRESS} hPa
${TI_UV} ${UV}
${TI_RISE} ${SUNRISE}
${TI_SET} ${SUNSET}
${TI_TMRW} ${TMRW_DESC}
${TI_HL} ${TMRW_MAX_C}°C | ${TMRW_MIN_C}°C
${TI_RISE_1} ${TMRW_SUNRISE}
${TI_SET_1} ${TMRW_SUNSET}
EOF
)"
TOOLTIP_JSON=$(jq -Rn --arg t "$TOOLTIP" '$t | sub("\n$"; "")')

echo "{\"text\":\"${TEXT}\",\"tooltip\":${TOOLTIP_JSON},\"class\":\"weather\"}"