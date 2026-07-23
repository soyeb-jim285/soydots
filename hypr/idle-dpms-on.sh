#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

"$SCRIPT_DIR/external-brightness.sh" power-on >/dev/null 2>&1 || true
hyprctl dispatch dpms on >/dev/null 2>&1 || true

# DDC can accept the power-on command before the monitor is ready for
# brightness commands. Keep retrying the saved pre-dim value during startup.
external_state_file="${XDG_CACHE_HOME:-$HOME/.cache}/hypr/idle-external-brightness"
for delay in 1 2 3; do
  [ ! -f "$external_state_file" ] && break
  sleep "$delay"
  "$SCRIPT_DIR/idle-undim.sh" >/dev/null 2>&1 || true
done
