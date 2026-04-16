#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

"$SCRIPT_DIR/idle-dpms-on.sh" >/dev/null 2>&1 || true
"$SCRIPT_DIR/idle-undim.sh" >/dev/null 2>&1 || true

# Give the lock surface a moment to remap after resume, then reclaim keyboard focus.
sleep 0.5
quickshell msg lockscreen refocus >/dev/null 2>&1 || true
