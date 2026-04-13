#!/usr/bin/env bash
# Screenshot wrapper — runs hyprshot, sends actionable notification

set -uo pipefail

MODE="${1:-region}"
OUTPUT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$OUTPUT_DIR"

# Use a known filename so we can check if hyprshot saved it
FILENAME="$(date +%Y-%m-%d-%H%M%S)_hyprshot.png"
SCREENSHOT="$OUTPUT_DIR/$FILENAME"

# Run hyprshot silently (we'll send our own notification)
hyprshot -m "$MODE" --freeze -s -o "$OUTPUT_DIR" -f "$FILENAME" || true

# Wait for hyprshot to finish writing the file (it forks internally)
for _ in $(seq 1 20); do
    [[ -f "$SCREENSHOT" ]] && break
    sleep 0.1
done
[[ ! -f "$SCREENSHOT" ]] && exit 0

# Wait for the file to be fully written (grim may still be flushing)
sleep 0.5

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
