#!/bin/bash
# Wallpaper manager for awww (swww successor)
# Usage:
#   wallpaper.sh set <path>         - Set a specific wallpaper
#   wallpaper.sh random [light|dark] - Set a random wallpaper from light/dark dir
#   wallpaper.sh toggle             - Toggle between light/dark variant
#   wallpaper.sh restore            - Restore last wallpaper

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
LIGHT_DIR="$WALLPAPER_DIR/light"
DARK_DIR="$WALLPAPER_DIR/dark"
STATE_FILE="$HOME/.cache/wallpaper-state"
TRANSITION="--transition-type fade --transition-duration 0.35 --transition-bezier .54,0,.34,.99"

mkdir -p "$(dirname "$STATE_FILE")"

set_wallpaper() {
    local img="$1"
    if [ ! -f "$img" ]; then
        echo "File not found: $img"
        exit 1
    fi
    awww img "$img" $TRANSITION
    echo "$img" > "$STATE_FILE"
    echo "Set wallpaper: $img"
}

random_wallpaper() {
    local dir="${1:-$WALLPAPER_DIR}"
    case "$1" in
        light) dir="$LIGHT_DIR" ;;
        dark)  dir="$DARK_DIR" ;;
    esac

    local img
    img=$(find "$dir" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' -o -name '*.gif' \) 2>/dev/null | shuf -n 1)

    if [ -z "$img" ]; then
        echo "No wallpapers found in $dir"
        exit 1
    fi
    set_wallpaper "$img"
}

toggle_variant() {
    local current
    current=$(cat "$STATE_FILE" 2>/dev/null)
    if [ -z "$current" ]; then
        echo "No current wallpaper state. Use 'set' or 'random' first."
        exit 1
    fi

    local basename
    basename=$(basename "$current")

    if [[ "$current" == *"/light/"* ]]; then
        # Switch to dark variant (same filename)
        if [ -f "$DARK_DIR/$basename" ]; then
            set_wallpaper "$DARK_DIR/$basename"
        else
            echo "No dark variant found for $basename, picking random dark"
            random_wallpaper dark
        fi
    else
        # Switch to light variant (same filename)
        if [ -f "$LIGHT_DIR/$basename" ]; then
            set_wallpaper "$LIGHT_DIR/$basename"
        else
            echo "No light variant found for $basename, picking random light"
            random_wallpaper light
        fi
    fi
}

case "${1:-}" in
    set)
        set_wallpaper "$2"
        ;;
    random)
        random_wallpaper "${2:-}"
        ;;
    toggle)
        toggle_variant
        ;;
    restore)
        awww restore
        ;;
    *)
        echo "Usage: $(basename "$0") {set <path>|random [light|dark]|toggle|restore}"
        exit 1
        ;;
esac
