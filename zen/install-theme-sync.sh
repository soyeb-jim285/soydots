#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXT_DIR="$SCRIPT_DIR/theme-sync"
HOST_DIR="$SCRIPT_DIR/theme-sync/native-host"
EXT_ID="quickshell-theme-sync@jimdots"

# Find Zen browser paths
# Zen uses ~/.zen for profiles (similar to ~/.mozilla/firefox)
ZEN_PROFILE_DIR="$HOME/.zen"
ZEN_NATIVE_MSG_DIR="$HOME/.mozilla/native-messaging-hosts"

echo "=== Quickshell Theme Sync — Zen Browser Extension Installer ==="

# 1. Install native messaging host manifest
echo "[1/3] Installing native messaging host..."
mkdir -p "$ZEN_NATIVE_MSG_DIR"

# Update path in manifest to point to actual location
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

# 2. Install extension into Zen profiles
echo "[2/3] Installing extension into Zen profiles..."

if [ ! -d "$ZEN_PROFILE_DIR" ]; then
    echo "   WARNING: Zen profile directory not found at $ZEN_PROFILE_DIR"
    echo "   You may need to install the extension manually."
else
    # Find all profile directories
    for profile in "$ZEN_PROFILE_DIR"/*.default* "$ZEN_PROFILE_DIR"/*.zen*; do
        if [ -d "$profile" ]; then
            ext_install_dir="$profile/extensions"
            mkdir -p "$ext_install_dir"
            # Create a pointer file — Zen/Firefox will load the extension from this path
            echo "$EXT_DIR" > "$ext_install_dir/$EXT_ID"
            echo "   Installed to profile: $(basename "$profile")"
        fi
    done
fi

# 3. Set preferences to allow unsigned extensions
echo "[3/3] Configuring extension permissions..."

# Find Zen's distribution directory for policies
ZEN_DIST_DIRS=(
    "/usr/lib/zen-browser/distribution"
    "/usr/lib64/zen-browser/distribution"
    "/opt/zen-browser/distribution"
    "$HOME/.local/share/zen/distribution"
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
    sudo mkdir -p "$DIST_DIR"
    sudo tee "$DIST_DIR/policies.json" > /dev/null << EOF
{
  "policies": {
    "ExtensionSettings": {
      "$EXT_ID": {
        "installation_mode": "allowed"
      }
    }
  }
}
EOF
    echo "   Policies written to: $DIST_DIR/policies.json"
else
    echo "   WARNING: Could not find Zen browser installation directory."
    echo "   You may need to set xpinstall.signatures.required = false in about:config"
fi

echo ""
echo "=== Done! Restart Zen browser to activate the extension. ==="
