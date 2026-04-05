#!/bin/bash
set -euo pipefail

ZEN_DIR="/opt/zen-browser-bin"
ZEN_PROFILE_DIR="$HOME/.config/zen"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Zen Browser Theme Setup ==="

# 1. Autoconfig for unsigned extensions
echo "[1/5] Setting up autoconfig..."
sudo mkdir -p "$ZEN_DIR/defaults/pref"

sudo tee "$ZEN_DIR/defaults/pref/autoconfig.js" > /dev/null << 'EOF'
pref("general.config.filename", "autoconfig.cfg");
pref("general.config.obscure_value", 0);
EOF

sudo tee "$ZEN_DIR/autoconfig.cfg" > /dev/null << 'EOF'
// First line must be a comment
defaultPref("xpinstall.signatures.required", false);
defaultPref("extensions.experiments.enabled", true);
EOF

echo "   Done"

# 2. Build extension
echo "[2/5] Building extension..."
cd "$SCRIPT_DIR/theme-sync"
zip -j "$SCRIPT_DIR/theme-sync.xpi" manifest.json background.js api.js schema.json
echo "   Built theme-sync.xpi"

# 3. Install extension into profiles
echo "[3/5] Installing extension into Zen profiles..."
for profile in "$ZEN_PROFILE_DIR"/*.default* "$ZEN_PROFILE_DIR"/*.Default*; do
    if [ -d "$profile" ]; then
        mkdir -p "$profile/extensions"
        cp "$SCRIPT_DIR/theme-sync.xpi" "$profile/extensions/quickshell-theme-sync@jimdots.xpi"
        echo "   Extension installed to: $(basename "$profile")"
    fi
done

# 4. Install CSS theme files into profiles
echo "[4/5] Installing CSS theme files..."
for profile in "$ZEN_PROFILE_DIR"/*.default* "$ZEN_PROFILE_DIR"/*.Default*; do
    if [ -d "$profile" ]; then
        target="$profile/chrome"
        mkdir -p "$target"

        # Copy all variants
        cp "$SCRIPT_DIR/chrome/userChrome-mocha.css" "$target/"
        cp "$SCRIPT_DIR/chrome/userChrome-latte.css" "$target/"
        cp "$SCRIPT_DIR/chrome/userContent-mocha.css" "$target/"
        cp "$SCRIPT_DIR/chrome/userContent-latte.css" "$target/"

        # Default to mocha (dark)
        cp "$SCRIPT_DIR/chrome/userChrome-mocha.css" "$target/userChrome.css"
        cp "$SCRIPT_DIR/chrome/userContent-mocha.css" "$target/userContent.css"

        # Set up user.js prefs
        user_js="$profile/user.js"
        touch "$user_js"

        # Enable legacy stylesheets (for userChrome/userContent CSS)
        pref="toolkit.legacyUserProfileCustomizations.stylesheets"
        grep -q "$pref" "$user_js" 2>/dev/null && \
            sed -i "s/.*$pref.*/user_pref(\"$pref\", true);/" "$user_js" || \
            echo "user_pref(\"$pref\", true);" >> "$user_js"

        # Website appearance = automatic (follows system)
        pref="layout.css.prefers-color-scheme.content-override"
        grep -q "$pref" "$user_js" 2>/dev/null && \
            sed -i "s/.*$pref.*/user_pref(\"$pref\", 2);/" "$user_js" || \
            echo "user_pref(\"$pref\", 2);" >> "$user_js"

        echo "   CSS + prefs installed to: $(basename "$profile")"
    fi
done

# 5. Set up native messaging host
echo "[5/5] Setting up native messaging host..."
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
echo ""
echo "What switches in real-time (via extension):"
echo "  - Toolbar, sidebar, tabs, popup colors"
echo "  - Website appearance (dark/light)"
echo ""
echo "What needs Zen restart (via CSS):"
echo "  - Settings page styling"
echo "  - Internal page (about:) styling"
echo "  - Zen-specific UI elements"
