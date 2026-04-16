#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

"$SCRIPT_DIR/external-brightness.sh" power-on >/dev/null 2>&1 || true
hyprctl dispatch dpms on >/dev/null 2>&1 || true
