#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHROME_DIR="$SCRIPT_DIR/chrome"
ZEN_PROFILE_DIR="$HOME/.config/zen"

echo "=== Catppuccin Theme for Zen Browser — Installer ==="

if [ ! -d "$ZEN_PROFILE_DIR" ]; then
    echo "   ERROR: Zen profile directory not found at $ZEN_PROFILE_DIR"
    exit 1
fi

installed=0
for profile in "$ZEN_PROFILE_DIR"/*.default* "$ZEN_PROFILE_DIR"/*.Default* "$ZEN_PROFILE_DIR"/*.zen*; do
    if [ -d "$profile" ]; then
        target="$profile/chrome"
        mkdir -p "$target"

        # Copy all theme variants
        cp "$CHROME_DIR"/userChrome-mocha.css "$target/"
        cp "$CHROME_DIR"/userChrome-latte.css "$target/"
        cp "$CHROME_DIR"/userContent-mocha.css "$target/"
        cp "$CHROME_DIR"/userContent-latte.css "$target/"

        # Default to mocha (dark)
        cp "$CHROME_DIR"/userChrome-mocha.css "$target/userChrome.css"
        cp "$CHROME_DIR"/userContent-mocha.css "$target/userContent.css"

        # Enable legacy stylesheets
        user_js="$profile/user.js"
        pref_line='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
        if [ -f "$user_js" ] && grep -q "legacyUserProfileCustomizations.stylesheets" "$user_js"; then
            sed -i 's/.*legacyUserProfileCustomizations.stylesheets.*/'"$pref_line"'/' "$user_js"
        else
            echo "$pref_line" >> "$user_js"
        fi

        # Set website appearance to automatic
        appearance_line='user_pref("layout.css.prefers-color-scheme.content-override", 2);'
        if [ -f "$user_js" ] && grep -q "prefers-color-scheme.content-override" "$user_js"; then
            sed -i 's/.*prefers-color-scheme.content-override.*/'"$appearance_line"'/' "$user_js"
        else
            echo "$appearance_line" >> "$user_js"
        fi

        echo "   Installed to profile: $(basename "$profile")"
        installed=1
    fi
done

if [ "$installed" -eq 0 ]; then
    echo "   ERROR: No profiles found"
    exit 1
fi

# Clean up old extension artifacts
rm -f "$HOME/.mozilla/native-messaging-hosts/quickshell_theme.json"
for profile in "$ZEN_PROFILE_DIR"/*.default* "$ZEN_PROFILE_DIR"/*.Default* "$ZEN_PROFILE_DIR"/*.zen*; do
    [ -d "$profile/extensions" ] && rm -f "$profile/extensions/quickshell-theme-sync@jimdots" "$profile/extensions/quickshell-theme-sync@jimdots.xpi"
done

echo ""
echo "=== Done! Restart Zen browser to activate. ==="
echo "    Quickshell swaps the CSS on Super+Shift+T toggle."
echo "    Zen needs a restart after each toggle to pick up the new CSS."
