#!/usr/bin/env bash

set -euo pipefail

/home/jim/jimdots/hypr/external-brightness.sh power-on >/dev/null 2>&1 || true
hyprctl dispatch dpms on >/dev/null 2>&1 || true
