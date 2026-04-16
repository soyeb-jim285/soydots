#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"
state_file="$state_dir/idle-monitor-brightness.tsv"
external_state_file="$state_dir/idle-external-brightness"

mkdir -p "$state_dir"

brightnessctl -s set 10 >/dev/null 2>&1 || true
external_brightness="$("$SCRIPT_DIR/external-brightness.sh" get 2>/dev/null || true)"
[ -n "$external_brightness" ] && printf '%s\n' "$external_brightness" > "$external_state_file"
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
  hyprctl keyword monitor "$name,${width}x${height}@${refresh},${x}x${y},${scale},transform,${transform},sdrbrightness,1" >/dev/null
done < "$state_file"
