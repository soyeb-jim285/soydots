#!/usr/bin/env bash

set -euo pipefail

hyprctl dispatch dpms off >/dev/null 2>&1 || true
/home/jim/jimdots/hypr/external-brightness.sh power-off >/dev/null 2>&1 || true
