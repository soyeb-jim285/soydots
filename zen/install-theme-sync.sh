#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHROME_DIR="$SCRIPT_DIR/chrome"

# Find Zen browser paths
ZEN_PROFILE_DIR="$HOME/.config/zen"

echo "=== Catppuccin Theme for Zen Browser — Installer ==="

# 1. Install CSS theme into Zen profiles
echo "[1/2] Installing CSS theme into Zen profiles..."

if [ ! -d "$ZEN_PROFILE_DIR" ]; then
    echo "   WARNING: Zen profile directory not found at $ZEN_PROFILE_DIR"
    exit 1
fi

installed=0
for profile in "$ZEN_PROFILE_DIR"/*.default* "$ZEN_PROFILE_DIR"/*.Default* "$ZEN_PROFILE_DIR"/*.zen*; do
    if [ -d "$profile" ]; then
        target="$profile/chrome"
        mkdir -p "$target"
        cp "$CHROME_DIR/userChrome.css" "$target/userChrome.css"
        cp "$CHROME_DIR/userContent.css" "$target/userContent.css"
        echo "   Installed to profile: $(basename "$profile")"
        installed=1

        # Enable legacy stylesheets in user.js
        user_js="$profile/user.js"
        pref_line='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
        if [ -f "$user_js" ] && grep -q "legacyUserProfileCustomizations.stylesheets" "$user_js"; then
            sed -i 's/.*legacyUserProfileCustomizations.stylesheets.*/'"$pref_line"'/' "$user_js"
        else
            echo "$pref_line" >> "$user_js"
        fi

        # Set website appearance to automatic (follows system color scheme)
        appearance_line='user_pref("layout.css.prefers-color-scheme.content-override", 2);'
        if [ -f "$user_js" ] && grep -q "prefers-color-scheme.content-override" "$user_js"; then
            sed -i 's/.*prefers-color-scheme.content-override.*/'"$appearance_line"'/' "$user_js"
        else
            echo "$appearance_line" >> "$user_js"
        fi

        echo "   Enabled legacy stylesheets + automatic website appearance"
    fi
done

if [ "$installed" -eq 0 ]; then
    echo "   WARNING: No profiles found"
    exit 1
fi

# 2. Clean up old extension artifacts (if any)
echo "[2/2] Cleaning up old extension artifacts..."

# Remove old .xpi files
for profile in "$ZEN_PROFILE_DIR"/*.default* "$ZEN_PROFILE_DIR"/*.Default* "$ZEN_PROFILE_DIR"/*.zen*; do
    if [ -d "$profile/extensions" ]; then
        rm -f "$profile/extensions/quickshell-theme-sync@jimdots"
        rm -f "$profile/extensions/quickshell-theme-sync@jimdots.xpi"
    fi
done

# Remove old native messaging host
rm -f "$HOME/.mozilla/native-messaging-hosts/quickshell_theme.json"

echo "   Cleaned up"

echo ""
echo "=== Done! Restart Zen browser to activate the theme. ==="
echo "    Theme switches automatically when you toggle dark/light mode (Super+Shift+T)"
