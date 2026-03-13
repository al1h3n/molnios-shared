# ==========================================================
# PC temperature script v1
# Changed: first release.
# Part of the MolniOS project.
# ==========================================================

# Finds the hottest thermal zone and converts to degrees.
for zone in /sys/class/thermal/thermal_zone*;do
cat "$zone/temp" 2>/dev/null
done | sort -nr | head -n1 | awk '{printf("%.0f°C", $1/1000)}'
