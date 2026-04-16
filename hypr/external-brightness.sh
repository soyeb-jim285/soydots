#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"
state_file="$state_dir/external-brightness"
target_file="$state_dir/external-brightness-target"
bus_file="$state_dir/external-brightness-bus"
lock_file="$state_dir/external-brightness.lock"

mkdir -p "$state_dir"

detect_bus() {
  ddcutil detect --brief 2>/dev/null | awk '
    /^Display / { in_display = 1; connector = ""; bus = "" }
    in_display && /I2C bus:/ { sub(/^.*\/dev\/i2c-/, "", $0); bus = $0; gsub(/^[[:space:]]+|[[:space:]]+$/, "", bus) }
    in_display && /DRM connector:/ {
      connector = $0
      gsub(/^.*DRM connector:[[:space:]]*/, "", connector)
      gsub(/^.*-/, "", connector)
      if (connector !~ /^(eDP|LVDS|DSI)-/ && bus != "") {
        print bus
        exit
      }
    }
  '
}

find_bus() {
  if [ -f "$bus_file" ]; then
    bus="$(<"$bus_file")"
    if [ -n "$bus" ] && [ -e "/dev/i2c-$bus" ]; then
      printf '%s\n' "$bus"
      return 0
    fi
  fi

  bus="$(detect_bus)"
  [ -n "$bus" ] || return 1
  printf '%s\n' "$bus" > "$bus_file"
  printf '%s\n' "$bus"
}

get_current() {
  local bus="$1"
  ddcutil --bus "$bus" getvcp 10 2>/dev/null | sed -n 's/.*current value = *\([0-9][0-9]*\).*/\1/p'
}

set_value() {
  local bus="$1"
  local value="$2"
  ddcutil --bus "$bus" --noverify setvcp 10 "$value" >/dev/null
}

set_power_mode() {
  local bus="$1"
  local value="$2"
  ddcutil --bus "$bus" --noverify setvcp D6 "$value" >/dev/null
}

clamp_value() {
  local value="$1"
  if [ "$value" -lt 0 ]; then value=0; fi
  if [ "$value" -gt 100 ]; then value=100; fi
  printf '%s\n' "$value"
}

bus="$(find_bus)"
[ -n "$bus" ] || exit 0

get_cached_or_current() {
  if [ -f "$target_file" ]; then
    value="$(<"$target_file")"
  elif [ -f "$state_file" ]; then
    value="$(<"$state_file")"
  else
    value="$(get_current "$bus")"
  fi
  [ -n "${value:-}" ] || exit 0
  printf '%s\n' "$value"
}

schedule_apply() {
  nohup "$SCRIPT_DIR/external-brightness.sh" apply >/dev/null 2>&1 &
}

case "${1:-}" in
  get)
    get_current "$bus"
    ;;
  apply)
    exec 9>"$lock_file"
    flock -n 9 || exit 0
    while [ -f "$target_file" ]; do
      target="$(<"$target_file")"
      [ -n "$target" ] || break
      target="$(clamp_value "$target")"
      if [ -f "$state_file" ]; then
        current="$(<"$state_file")"
      else
        current="$(get_current "$bus")"
      fi
      [ -n "$current" ] || current="$target"
      if [ "$current" != "$target" ]; then
        set_value "$bus" "$target"
        printf '%s\n' "$target" > "$state_file"
      fi
      latest="$(<"$target_file")"
      if [ "$latest" = "$target" ]; then
        rm -f "$target_file"
        break
      fi
    done
    ;;
  set)
    value="$(clamp_value "$2")"
    printf '%s\n' "$value" > "$target_file"
    schedule_apply
    ;;
  inc)
    current="$(get_cached_or_current)"
    [ -n "$current" ] || exit 0
    next="$(clamp_value $(( current + $2 )))"
    printf '%s\n' "$next" > "$target_file"
    schedule_apply
    ;;
  dec)
    current="$(get_cached_or_current)"
    [ -n "$current" ] || exit 0
    next="$(clamp_value $(( current - $2 )))"
    printf '%s\n' "$next" > "$target_file"
    schedule_apply
    ;;
  save)
    current="$(get_current "$bus")"
    [ -n "$current" ] || exit 0
    printf '%s\n' "$current" > "$state_file"
    ;;
  restore)
    [ -f "$state_file" ] || exit 0
    value="$(<"$state_file")"
    [ -n "$value" ] || exit 0
    exec 9>"$lock_file"
    flock 9
    set_value "$bus" "$value"
    ;;
  power-off)
    exec 9>"$lock_file"
    flock 9
    set_power_mode "$bus" 5
    ;;
  power-on)
    exec 9>"$lock_file"
    flock 9
    set_power_mode "$bus" 1
    ;;
  *)
    exit 1
    ;;
esac
