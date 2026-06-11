# Use argument if provided, otherwise fallback to root "/"
# Value such as /dev/sda1 can be used as an argument.
TARGET="${1:-/}"
USAGE=$(df -P "$TARGET" | awk 'NR==2 {print $5}' | tr -d '%')
echo $USAGE