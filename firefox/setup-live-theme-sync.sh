#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUTOCONFIG_SRC="$SCRIPT_DIR/autoconfig.cfg"
AUTOCONFIG_REAL="$(realpath "$AUTOCONFIG_SRC")"
AUTOCONFIG_URI="file://$AUTOCONFIG_REAL"

is_firefox_dir() {
    local candidate="$1"
    [ -f "$candidate/omni.ja" ] || [ -f "$candidate/browser/omni.ja" ]
}

detect_firefox_dir() {
    local launcher target candidate

    for candidate in \
        "/usr/lib/firefox" \
        "/usr/lib64/firefox" \
        "/opt/firefox" \
        "/opt/firefox-esr"
    do
        if is_firefox_dir "$candidate"; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    launcher="$(command -v firefox 2>/dev/null || true)"
    if [ -n "$launcher" ] && [ -e "$launcher" ]; then
        target="$(readlink -f "$launcher")"
        candidate="$(dirname "$target")"
        if is_firefox_dir "$candidate"; then
            printf '%s\n' "$candidate"
            return 0
        fi

        if [ -f "$launcher" ]; then
            target="$(sed -n 's|^[[:space:]]*exec[[:space:]]\([^[:space:]]*\)[[:space:]].*|\1|p' "$launcher")"
            if [ -n "$target" ]; then
                candidate="$(dirname "$target")"
                if is_firefox_dir "$candidate"; then
                    printf '%s\n' "$candidate"
                    return 0
                fi
            fi
        fi
    fi

    return 1
}

FIREFOX_DIR="$(detect_firefox_dir || true)"
if [ -z "$FIREFOX_DIR" ]; then
    printf 'Could not locate the Firefox installation directory.\n' >&2
    printf 'Expected something like /usr/lib/firefox containing omni.ja.\n' >&2
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

printf 'Installing Firefox live theme sync into %s\n' "$FIREFOX_DIR"
sudo install -d "$FIREFOX_DIR/defaults/pref"
sudo install -m 0644 "$TMP_AUTOCONFIG_JS" "$FIREFOX_DIR/defaults/pref/autoconfig.js"
sudo install -m 0644 "$TMP_AUTOCONFIG_CFG" "$FIREFOX_DIR/autoconfig.cfg"

mkdir -p "$HOME/.config"

printf '\nSetup complete.\n'
printf 'Restart Firefox once to load the browser hook.\n'
printf 'After that, theme changes should hot-reload from %s/.config/zen-live-theme.json\n' "$HOME"
printf 'If you add a dedicated Firefox payload later, %s/.config/firefox-live-theme.json is preferred.\n' "$HOME"
printf 'If you move this repo, rerun this script so the bootstrap path stays valid.\n'
