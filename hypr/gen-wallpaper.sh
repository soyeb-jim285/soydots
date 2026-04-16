#!/bin/bash
# Wallpaper switcher — picks light or dark wallpaper based on current theme.
#
# Usage: gen-wallpaper.sh [--no-apply]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
WALLPAPER_DIR="$(dirname "$SCRIPT_DIR")/wallpapers"

# Accept mode as argument, fall back to reading settings file
mode="${1:-}"
if [[ -z "$mode" ]]; then
    SETTINGS="$HOME/.config/quickshellsettings.toml"
    dark_mode=$(grep "^darkMode" "$SETTINGS" | head -1 | sed 's/.*= *//')
    mode=$([[ "$dark_mode" == "true" ]] && echo "dark" || echo "light")
fi

if [[ "$mode" == "dark" ]]; then
    wallpaper="$WALLPAPER_DIR/end4-dark.png"
else
    wallpaper="$WALLPAPER_DIR/end4-light.png"
fi

if [[ ! -f "$wallpaper" ]]; then
    echo "Wallpaper not found: $wallpaper"
    exit 1
fi

if [[ "${1:-}" != "--no-apply" ]]; then
    awww img "$wallpaper" --transition-type fade --transition-duration 0.35 --transition-bezier .54,0,.34,.99
fi
