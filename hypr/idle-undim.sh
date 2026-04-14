#!/usr/bin/env bash

set -euo pipefail

state_file="${XDG_CACHE_HOME:-$HOME/.cache}/hypr/idle-monitor-brightness.tsv"
external_state_file="${XDG_CACHE_HOME:-$HOME/.cache}/hypr/idle-external-brightness"

brightnessctl -r >/dev/null 2>&1 || true
if [ -f "$external_state_file" ]; then
  external_brightness="$(<"$external_state_file")"
  [ -n "$external_brightness" ] && /home/jim/jimdots/hypr/external-brightness.sh set "$external_brightness" >/dev/null 2>&1 || true
fi

if [ ! -f "$state_file" ]; then
  exit 0
fi

while IFS=$'\t' read -r name width height refresh x y scale transform brightness; do
  [ -n "$name" ] || continue
  hyprctl keyword monitor "$name,${width}x${height}@${refresh},${x}x${y},${scale},transform,${transform},sdrbrightness,1" >/dev/null
done < "$state_file"
