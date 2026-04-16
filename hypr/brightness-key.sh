#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

"$SCRIPT_DIR/brightness-sync.sh" "$@"
quickshell msg osd brightness >/dev/null 2>&1 || true
