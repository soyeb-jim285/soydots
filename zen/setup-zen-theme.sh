#!/bin/bash
set -euo pipefail

ZEN_DIR="/opt/zen-browser-bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Zen Browser Theme Setup ==="

# 1. Install autoconfig (privileged JS that watches zen-theme.json)
echo "[1/2] Installing autoconfig..."
sudo mkdir -p "$ZEN_DIR/defaults/pref"

sudo tee "$ZEN_DIR/defaults/pref/autoconfig.js" > /dev/null << 'EOF'
pref("general.config.filename", "autoconfig.cfg");
pref("general.config.obscure_value", 0);
EOF

sudo cp "$SCRIPT_DIR/autoconfig.cfg" "$ZEN_DIR/autoconfig.cfg"
echo "   Installed autoconfig.cfg"

# 2. Clean up old extension artifacts
echo "[2/2] Cleaning up old extension artifacts..."
ZEN_PROFILE_DIR="$HOME/.config/zen"
for profile in "$ZEN_PROFILE_DIR"/*.default* "$ZEN_PROFILE_DIR"/*.Default*; do
    if [ -d "$profile" ]; then
        rm -f "$profile/extensions/quickshell-theme-sync@jimdots.xpi"
        rm -f "$profile/extensions/quickshell-theme-sync@jimdots"
    fi
done
rm -f "$HOME/.mozilla/native-messaging-hosts/quickshell_theme.json"
echo "   Done"

echo ""
echo "=== All done! Restart Zen browser. ==="
echo ""
echo "How it works:"
echo "  - autoconfig.cfg polls ~/.config/zen-theme.json every second"
echo "  - When quickshell toggles (Super+Shift+T), it writes new colors"
echo "  - autoconfig applies CSS instantly via nsIStyleSheetService"
echo "  - Website appearance switches via layout.css.prefers-color-scheme pref"
echo "  - No extension needed!"
