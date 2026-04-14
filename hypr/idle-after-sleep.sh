#!/usr/bin/env bash

set -euo pipefail

/home/jim/jimdots/hypr/idle-dpms-on.sh >/dev/null 2>&1 || true
/home/jim/jimdots/hypr/idle-undim.sh >/dev/null 2>&1 || true

# Give the lock surface a moment to remap after resume, then reclaim keyboard focus.
sleep 0.5
quickshell msg lockscreen refocus >/dev/null 2>&1 || true
