#!/usr/bin/env bash
# Toggle HDMI-A-1 between landscape (transform 0) and portrait (transform 3).
# Reads current transform from hyprctl, flips to the other.

mon="HDMI-A-1"
cur=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$mon\") | .transform")

# Per-orientation position: portrait is tall and sits higher; landscape is wide.
if [ "$cur" = "0" ]; then
    new=3
    pos="1600x-920"
    label="Portrait"
else
    new=0
    pos="1600x0"
    label="Landscape"
fi

line="monitor=$mon,preferred,$pos,1,transform,$new"

# Apply live now.
hyprctl keyword monitor "$mon,preferred,$pos,1,transform,$new"

# Persist to local.conf (sourced last, survives reload/theme toggle).
# Replace any existing marked line; append if absent.
local_conf="$HOME/.config/hypr/local.conf"
marker="# HDMI rotate state (auto)"
touch "$local_conf"
if grep -qF "$marker" "$local_conf"; then
    # Marker line followed by the monitor line; rewrite the monitor line under it.
    awk -v m="$marker" -v l="$line" '
        prev==1 { print l; prev=0; next }
        $0==m   { print; prev=1; next }
        { print }
    ' "$local_conf" > "$local_conf.tmp" && mv "$local_conf.tmp" "$local_conf"
else
    printf '\n%s\n%s\n' "$marker" "$line" >> "$local_conf"
fi

notify-send -t 2000 "🖥️ HDMI rotated" "$label (transform $new)"
