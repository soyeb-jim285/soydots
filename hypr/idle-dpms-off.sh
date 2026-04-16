#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

hyprctl dispatch dpms off >/dev/null 2>&1 || true
"$SCRIPT_DIR/external-brightness.sh" power-off >/dev/null 2>&1 || true
