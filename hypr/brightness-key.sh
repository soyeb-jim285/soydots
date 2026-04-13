#!/usr/bin/env bash

set -euo pipefail

/home/jim/jimdots/hypr/brightness-sync.sh "$@"
quickshell msg osd brightness >/dev/null 2>&1 || true
