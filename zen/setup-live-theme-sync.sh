#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUTOCONFIG_SRC="$SCRIPT_DIR/autoconfig.cfg"
AUTOCONFIG_REAL="$(realpath "$AUTOCONFIG_SRC")"
AUTOCONFIG_URI="file://$AUTOCONFIG_REAL"

detect_zen_dir() {
    local launcher target candidate

    for candidate in \
        "/opt/zen-browser-bin" \
        "/usr/lib/zen-browser" \
        "/usr/lib64/zen-browser"
    do
        if [ -f "$candidate/omni.ja" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    launcher="$(command -v zen-browser 2>/dev/null || true)"
    if [ -n "$launcher" ] && [ -f "$launcher" ]; then
        target="$(sed -n 's|^[[:space:]]*exec[[:space:]]\([^[:space:]]*\)[[:space:]].*|\1|p' "$launcher")"
        if [ -n "$target" ]; then
            candidate="$(dirname "$target")"
            if [ -f "$candidate/omni.ja" ]; then
                printf '%s\n' "$candidate"
                return 0
            fi
        fi
    fi

    return 1
}

ZEN_DIR="$(detect_zen_dir || true)"
if [ -z "$ZEN_DIR" ]; then
    printf 'Could not locate the Zen installation directory.\n' >&2
    printf 'Expected something like /opt/zen-browser-bin containing omni.ja.\n' >&2
    exit 1
fi

if [ ! -f "$AUTOCONFIG_SRC" ]; then
    printf 'Missing autoconfig source: %s\n' "$AUTOCONFIG_SRC" >&2
    exit 1
fi

TMP_AUTOCONFIG_JS="$(mktemp)"
TMP_AUTOCONFIG_CFG="$(mktemp)"
trap 'rm -f "$TMP_AUTOCONFIG_JS" "$TMP_AUTOCONFIG_CFG"' EXIT

cat > "$TMP_AUTOCONFIG_JS" <<'EOF'
pref("general.config.filename", "autoconfig.cfg");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_enabled", false);
EOF

cat > "$TMP_AUTOCONFIG_CFG" <<EOF
// Bootstrap to the repo copy so future edits do not need reinstalling.
Services.scriptloader.loadSubScript("$AUTOCONFIG_URI", this, "UTF-8");
EOF

printf 'Installing Zen live theme sync into %s\n' "$ZEN_DIR"
sudo install -d "$ZEN_DIR/defaults/pref"
sudo install -m 0644 "$TMP_AUTOCONFIG_JS" "$ZEN_DIR/defaults/pref/autoconfig.js"
sudo install -m 0644 "$TMP_AUTOCONFIG_CFG" "$ZEN_DIR/autoconfig.cfg"

mkdir -p "$HOME/.config"

printf '\nSetup complete.\n'
printf 'Restart Zen once to load the browser hook.\n'
printf 'After that, theme changes should hot-reload from %s/.config/zen-live-theme.json\n' "$HOME"
printf 'If you move this repo, rerun this script so the bootstrap path stays valid.\n'
