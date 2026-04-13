#!/usr/bin/env bash
# Screenshot wrapper — runs hyprshot, sends actionable notification

set -euo pipefail

MODE="${1:-region}"
OUTPUT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$OUTPUT_DIR"

# Get timestamp before screenshot for file detection
BEFORE=$(date +%s%N)

# Run hyprshot silently (we'll send our own notification)
hyprshot -m "$MODE" --freeze -s -o "$OUTPUT_DIR" || exit 0

# Find the newest file created after our timestamp
SCREENSHOT=""
for f in "$OUTPUT_DIR"/*; do
    if [[ -f "$f" ]] && [[ $(stat -c %Y "$f") -ge $((BEFORE / 1000000000)) ]]; then
        SCREENSHOT="$f"
    fi
done

[[ -z "$SCREENSHOT" ]] && exit 0

FILENAME=$(basename "$SCREENSHOT")

# Send actionable notification
ACTION=$(notify-send "Screenshot saved" "$FILENAME" \
    -a "Hyprshot" \
    -i "$SCREENSHOT" \
    -A "open=Open" \
    -A "delete=Delete" \
    --wait 2>/dev/null || true)

case "$ACTION" in
    open)
        xdg-open "$SCREENSHOT" &
        ;;
    delete)
        rm -f "$SCREENSHOT"
        notify-send "Screenshot deleted" "$FILENAME" -a "Hyprshot" -t 2000
        ;;
esac
