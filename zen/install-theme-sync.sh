#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXT_DIR="$SCRIPT_DIR/theme-sync"
HOST_DIR="$SCRIPT_DIR/theme-sync/native-host"
XPI_PATH="$SCRIPT_DIR/theme-sync.xpi"
EXT_ID="quickshell-theme-sync@jimdots"

# Find Zen browser paths
ZEN_PROFILE_DIR="$HOME/.config/zen"
ZEN_NATIVE_MSG_DIR="$HOME/.mozilla/native-messaging-hosts"

echo "=== Quickshell Theme Sync — Zen Browser Extension Installer ==="

# 0. Package extension as .xpi
echo "[0/4] Packaging extension..."
(cd "$EXT_DIR" && zip -j "$XPI_PATH" manifest.json background.js)
echo "   Built: $XPI_PATH"

# 1. Install native messaging host manifest
echo "[1/4] Installing native messaging host..."
mkdir -p "$ZEN_NATIVE_MSG_DIR"

cat > "$ZEN_NATIVE_MSG_DIR/quickshell_theme.json" << EOF
{
  "name": "quickshell_theme",
  "description": "Quickshell theme sync native messaging host",
  "path": "$HOST_DIR/quickshell-theme-host.py",
  "type": "stdio",
  "allowed_extensions": ["$EXT_ID"]
}
EOF

echo "   Installed to: $ZEN_NATIVE_MSG_DIR/quickshell_theme.json"

# 2. Install .xpi into Zen profiles
echo "[2/4] Installing extension into Zen profiles..."

if [ ! -d "$ZEN_PROFILE_DIR" ]; then
    echo "   WARNING: Zen profile directory not found at $ZEN_PROFILE_DIR"
    echo "   You may need to install the extension manually."
else
    for profile in "$ZEN_PROFILE_DIR"/*.default* "$ZEN_PROFILE_DIR"/*.Default* "$ZEN_PROFILE_DIR"/*.zen*; do
        if [ -d "$profile" ]; then
            ext_install_dir="$profile/extensions"
            mkdir -p "$ext_install_dir"
            # Copy the .xpi with the extension ID as filename
            cp "$XPI_PATH" "$ext_install_dir/$EXT_ID.xpi"
            echo "   Installed to profile: $(basename "$profile")"
        fi
    done
fi

# 3. Set policies to force-install and disable signature requirement
echo "[3/4] Configuring browser policies..."

ZEN_DIST_DIRS=(
    "/opt/zen-browser-bin/distribution"
    "/usr/lib/zen-browser/distribution"
    "/usr/lib64/zen-browser/distribution"
    "/opt/zen-browser/distribution"
)

DIST_DIR=""
for dir in "${ZEN_DIST_DIRS[@]}"; do
    parent="$(dirname "$dir")"
    if [ -d "$parent" ]; then
        DIST_DIR="$dir"
        break
    fi
done

if [ -n "$DIST_DIR" ]; then
    echo "   Requires sudo to write browser policies..."
    sudo mkdir -p "$DIST_DIR"
    sudo tee "$DIST_DIR/policies.json" > /dev/null << EOF
{
  "policies": {
    "ExtensionSettings": {
      "$EXT_ID": {
        "installation_mode": "normal_installed",
        "install_url": "file://$XPI_PATH"
      }
    }
  }
}
EOF
    echo "   Policies written to: $DIST_DIR/policies.json"
else
    echo "   WARNING: Could not find Zen browser installation directory."
    echo "   You may need to install the extension manually via about:debugging."
fi

# 4. Disable signature requirement via autoconfig
echo "[4/4] Disabling extension signature requirement..."

if [ -n "$DIST_DIR" ]; then
    ZEN_DIR="$(dirname "$DIST_DIR")"

    # autoconfig.js tells Zen to load the autoconfig file
    sudo tee "$ZEN_DIR/defaults/pref/autoconfig.js" > /dev/null << 'EOF'
pref("general.config.filename", "autoconfig.cfg");
pref("general.config.obscure_value", 0);
EOF

    # autoconfig.cfg disables signature requirement
    sudo tee "$ZEN_DIR/autoconfig.cfg" > /dev/null << 'EOF'
// First line must be a comment
defaultPref("xpinstall.signatures.required", false);
EOF

    echo "   Signature requirement disabled via autoconfig"
else
    echo "   Skipped — set xpinstall.signatures.required = false in about:config manually"
fi

echo ""
echo "=== Done! Restart Zen browser to activate the extension. ==="
