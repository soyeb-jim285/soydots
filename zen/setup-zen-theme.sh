#!/bin/bash
set -euo pipefail

ZEN_DIR="/opt/zen-browser-bin"
ZEN_PROFILE_DIR="$HOME/.config/zen"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Zen Browser Theme Setup ==="

# 1. Autoconfig for unsigned extensions
echo "[1/4] Setting up autoconfig..."
sudo mkdir -p "$ZEN_DIR/defaults/pref"

sudo tee "$ZEN_DIR/defaults/pref/autoconfig.js" > /dev/null << 'EOF'
pref("general.config.filename", "autoconfig.cfg");
pref("general.config.obscure_value", 0);
EOF

sudo tee "$ZEN_DIR/autoconfig.cfg" > /dev/null << 'EOF'
// First line must be a comment
defaultPref("xpinstall.signatures.required", false);
EOF

echo "   Done"

# 2. Build extension
echo "[2/4] Building extension..."
cd "$SCRIPT_DIR/theme-sync"
zip -j "$SCRIPT_DIR/theme-sync.xpi" manifest.json background.js
echo "   Built theme-sync.xpi"

# 3. Install into profiles
echo "[3/4] Installing into Zen profiles..."
for profile in "$ZEN_PROFILE_DIR"/*.default* "$ZEN_PROFILE_DIR"/*.Default*; do
    if [ -d "$profile" ]; then
        mkdir -p "$profile/extensions"
        cp "$SCRIPT_DIR/theme-sync.xpi" "$profile/extensions/quickshell-theme-sync@jimdots.xpi"

        # Set up user.js prefs
        user_js="$profile/user.js"
        touch "$user_js"

        # Website appearance = automatic (follows system)
        grep -q "prefers-color-scheme.content-override" "$user_js" 2>/dev/null && \
            sed -i 's/.*prefers-color-scheme.content-override.*/user_pref("layout.css.prefers-color-scheme.content-override", 2);/' "$user_js" || \
            echo 'user_pref("layout.css.prefers-color-scheme.content-override", 2);' >> "$user_js"

        echo "   Installed to: $(basename "$profile")"
    fi
done

# 4. Set up native messaging host
echo "[4/4] Setting up native messaging host..."
mkdir -p "$HOME/.mozilla/native-messaging-hosts"
cat > "$HOME/.mozilla/native-messaging-hosts/quickshell_theme.json" << EOF
{
  "name": "quickshell_theme",
  "description": "Quickshell theme sync",
  "path": "$SCRIPT_DIR/theme-sync/native-host/quickshell-theme-host.py",
  "type": "stdio",
  "allowed_extensions": ["quickshell-theme-sync@jimdots"]
}
EOF
chmod +x "$SCRIPT_DIR/theme-sync/native-host/quickshell-theme-host.py"
echo "   Done"

echo ""
echo "=== All done! Restart Zen browser. ==="
echo "    Check about:addons to verify the extension loaded."
