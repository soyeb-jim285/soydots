#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 1 ]; then
  exit 1
fi

brightnessctl "$@" >/dev/null

last_arg="${!#}"

if [[ "$last_arg" =~ ^([0-9]+)%([+-])$ ]]; then
  step_pct="${BASH_REMATCH[1]}"
  op="${BASH_REMATCH[2]}"
  if [ "$op" = "+" ]; then
    /home/jim/jimdots/hypr/external-brightness.sh inc "$step_pct" || true
  else
    /home/jim/jimdots/hypr/external-brightness.sh dec "$step_pct" || true
  fi
elif [[ "$last_arg" =~ ^([0-9]+)%$ ]]; then
  /home/jim/jimdots/hypr/external-brightness.sh set "${BASH_REMATCH[1]}" || true
else
  pct="$({ brightnessctl -m | awk -F, 'NR==1 {gsub(/%/, "", $4); print $4}'; } 2>/dev/null || true)"
  [ -n "$pct" ] || exit 0
  /home/jim/jimdots/hypr/external-brightness.sh set "$pct" || true
fi
