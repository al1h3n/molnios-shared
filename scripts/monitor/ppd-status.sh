# Switch command:
# sh -c '[[ $SWAYNC_TOGGLE_STATE == true ]] && pkexec powerprofilesctl set power-saver || pkexec powerprofilesctl set performance'

[[ "$(powerprofilesctl get)" == "power-saver" ]] && echo true || echo false