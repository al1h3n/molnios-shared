# Switch command:
# sh -c '[[ $SWAYNC_TOGGLE_STATE == true ]] && pkexec tlp bat || pkexec tlp ac'
tlp-stat -s | grep -q "BAT" && echo true || echo false