# ==========================================================
# GPU usage script
# Part of the MolniOS project.
# ==========================================================

# Use argument if provided, otherwise default to root "/"
# Use value such as /dev/sda1
TARGET="${1:-/}"
USAGE=$(df -P "$TARGET" | awk 'NR==2 {print $5}' | tr -d '%')
echo $USAGE