#!/usr/bin/env bash
# Screenshot wrapper — runs hyprshot, sends actionable notification

set -uo pipefail

MODE="${1:-region}"
OUTPUT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$OUTPUT_DIR"

# Use a known filename so we can check if hyprshot saved it
FILENAME="$(date +%Y-%m-%d-%H%M%S)_hyprshot.png"
SCREENSHOT="$OUTPUT_DIR/$FILENAME"

if [[ "$MODE" == "region" ]]; then
    # Capture full screen BEFORE slurp draws its selection overlay, then
    # crop to the chosen region. Prevents slurp's border from ending up in
    # the image (compositor may commit a stale frame with the overlay).
    TMPFULL=$(mktemp --suffix=.ppm)
    trap 'rm -f "$TMPFULL"' EXIT
    # Capture full screen in the background so slurp's crosshair appears
    # immediately — grim + PNG encode on a multi-monitor logical image
    # (~2680x1920 here) adds 200-500ms of delay if done serially.
    # PPM is uncompressed (~15MB) but encodes near-instantly, and ffmpeg
    # reads it directly for the crop step. -s 1 gives logical resolution
    # so slurp coords map 1:1 onto image pixels.
    grim -s 1 -t ppm "$TMPFULL" &
    GRIM_PID=$!
    GEOMETRY=$(slurp -d 2>/dev/null)
    SLURP_RC=$?
    if (( SLURP_RC != 0 )) || [[ -z "$GEOMETRY" ]]; then
        wait "$GRIM_PID" 2>/dev/null || true
        exit 0
    fi
    wait "$GRIM_PID" || exit 0
    # Geometry: "X,Y WxH". slurp returns global compositor coords (can be
    # negative with multi-monitor setups); grim's combined output starts
    # at the bounding-box origin, so offset coords by min_x/min_y.
    XY="${GEOMETRY%% *}"
    WH="${GEOMETRY##* }"
    X="${XY%,*}"; Y="${XY#*,}"
    W="${WH%x*}"; H="${WH#*x}"
    MIN_X=$(hyprctl monitors -j | jq '[.[].x] | min')
    MIN_Y=$(hyprctl monitors -j | jq '[.[].y] | min')
    CX=$(( X - MIN_X ))
    CY=$(( Y - MIN_Y ))
    ffmpeg -loglevel error -y -i "$TMPFULL" -vf "crop=${W}:${H}:${CX}:${CY}" "$SCREENSHOT" || exit 0
    wl-copy --type image/png < "$SCREENSHOT" 2>/dev/null || true
else
    # Run hyprshot silently (we'll send our own notification)
    hyprshot -m "$MODE" --freeze -s -o "$OUTPUT_DIR" -f "$FILENAME" || true

    # Wait for hyprshot to finish writing the file (it forks internally)
    for _ in $(seq 1 20); do
        [[ -f "$SCREENSHOT" ]] && break
        sleep 0.1
    done
fi
[[ ! -f "$SCREENSHOT" ]] && exit 0

# Wait for the file to be fully written (grim may still be flushing)
# Check that file size stabilizes
PREV_SIZE=0
for _ in $(seq 1 20); do
    sleep 0.2
    CUR_SIZE=$(stat -c %s "$SCREENSHOT" 2>/dev/null || echo 0)
    [[ "$CUR_SIZE" -gt 0 && "$CUR_SIZE" == "$PREV_SIZE" ]] && break
    PREV_SIZE="$CUR_SIZE"
done

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
