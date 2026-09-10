#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"
state_file="$state_dir/idle-monitor-brightness.tsv"
external_state_file="$state_dir/idle-external-brightness"

mkdir -p "$state_dir"

brightnessctl -s set 10% >/dev/null 2>&1 || true
external_brightness="$("$SCRIPT_DIR/external-brightness.sh" get 2>/dev/null || true)"
if [ -n "$external_brightness" ]; then
  saved_external_brightness=""
  [ ! -f "$external_state_file" ] || saved_external_brightness="$(<"$external_state_file")"
  # A retained value of 10 means the previous wake failed before DDC was ready.
  if [ -z "$saved_external_brightness" ] || { [ "$saved_external_brightness" = 10 ] && [ "$external_brightness" != 10 ]; }; then
    printf '%s\n' "$external_brightness" > "$external_state_file"
  fi
fi
"$SCRIPT_DIR/external-brightness.sh" set 10 >/dev/null 2>&1 || true

hyprctl -j monitors | jq -r '
  .[]
  | select(.disabled | not)
  | select(.name | test("^(eDP|LVDS|DSI)-") | not)
  | [
      .name,
      (.width | tostring),
      (.height | tostring),
      (.refreshRate | tostring),
      (.x | tostring),
      (.y | tostring),
      (.scale | tostring),
      (.transform | tostring),
      (.sdrBrightness | tostring)
    ]
  | @tsv
' > "$state_file"

while IFS=$'\t' read -r name width height refresh x y scale transform brightness; do
  [ -n "$name" ] || continue
  hyprctl eval "hl.monitor({ output = \"$name\", mode = \"${width}x${height}@${refresh}\", position = \"${x}x${y}\", scale = ${scale}, transform = ${transform}, sdrbrightness = 1 })" >/dev/null
done < "$state_file"
