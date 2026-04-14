#!/usr/bin/env bash
# Shared helpers for jimdots setup scripts.
# Source this from each phase script: . "$(dirname "$0")/lib.sh"

set -euo pipefail

: "${JIMDOTS_REPO:="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}"
: "${JIMDOTS_LOG:="$HOME/.cache/jimdots-setup.log"}"
: "${JIMDOTS_DRY_RUN:=0}"
: "${JIMDOTS_ASSUME_YES:=0}"

mkdir -p "$(dirname "$JIMDOTS_LOG")"

if [[ -t 1 ]]; then
    C_RESET=$'\e[0m'; C_DIM=$'\e[2m'; C_RED=$'\e[31m'; C_YEL=$'\e[33m'; C_GRN=$'\e[32m'; C_BLU=$'\e[34m'; C_MAU=$'\e[38;2;203;166;247m'
else
    C_RESET=""; C_DIM=""; C_RED=""; C_YEL=""; C_GRN=""; C_BLU=""; C_MAU=""
fi

_has_nf() {
    # True if the current terminal plausibly renders Nerd Font glyphs.
    # Linux TTY never does; GUI terminals usually do if the user set them up.
    [[ "$TERM" != "linux" && "$TERM" != "dumb" ]] \
        && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" \
           || "$TERM" == xterm-kitty \
           || "$TERM" == xterm-ghostty \
           || "$TERM" == foot \
           || "$TERM" == alacritty ]]
}

if _has_nf; then
    IC_OK=$'\uf00c'; IC_WARN=$'\uf071'; IC_ERR=$'\uf00d'; IC_INFO=$'\uf054'
else
    IC_OK="[ok]"; IC_WARN="[!]"; IC_ERR="[x]"; IC_INFO="->"
fi

_has_gum() { command -v gum >/dev/null 2>&1; }

_ts() { date '+%Y-%m-%d %H:%M:%S'; }

# Log-only: written to $JIMDOTS_LOG with timestamp, dim echo to stderr.
log() { printf '%s[%s]%s %s\n' "$C_DIM" "$(_ts)" "$C_RESET" "$*" | tee -a "$JIMDOTS_LOG" >&2; }

# Status lines: also written to the log file (plain).
_logfile() { printf '[%s] %s %s\n' "$(_ts)" "$1" "$2" >> "$JIMDOTS_LOG"; }

info() {
    _logfile "INFO" "$*"
    printf '%s%s%s %s\n' "$C_BLU" "$IC_INFO" "$C_RESET" "$*" >&2
}

ok() {
    _logfile "OK  " "$*"
    printf '%s%s%s %s\n' "$C_GRN" "$IC_OK" "$C_RESET" "$*" >&2
}

warn() {
    _logfile "WARN" "$*"
    printf '%s%s%s %s\n' "$C_YEL" "$IC_WARN" "$C_RESET" "$*" >&2
}

die() {
    _logfile "ERR " "$*"
    printf '%s%s%s %s\n' "$C_RED" "$IC_ERR" "$C_RESET" "$*" >&2
    exit 1
}

# Banner shown at the start of each phase. Uses gum if available, otherwise plain.
banner() {
    local title="$1"
    _logfile "STEP" "$title"
    if _has_gum && [[ -t 1 ]]; then
        gum style \
            --border rounded --border-foreground 212 \
            --foreground 212 --padding "0 2" --margin "1 0" \
            "$title" >&2
    else
        printf '\n%s== %s ==%s\n' "$C_MAU" "$title" "$C_RESET" >&2
    fi
}

dry() { [[ "$JIMDOTS_DRY_RUN" == "1" ]]; }

run() {
    log "+ $*"
    if dry; then return 0; fi
    "$@"
}

sudo_run() {
    log "+ sudo $*"
    if dry; then return 0; fi
    sudo "$@"
}

confirm() {
    local q="$1" default="${2:-n}" reply
    if [[ "$JIMDOTS_ASSUME_YES" == "1" ]]; then return 0; fi
    if _has_gum && [[ -t 0 ]]; then
        if [[ "$default" == "y" ]]; then
            gum confirm --default=true "$q"
        else
            gum confirm --default=false "$q"
        fi
        return $?
    fi
    local hint="[y/N]"; [[ "$default" == "y" ]] && hint="[Y/n]"
    read -r -p "$q $hint " reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy]$ ]]
}

prompt_default() {
    local label="$1" def="${2:-}" reply
    if _has_gum && [[ -t 0 ]]; then
        if [[ -n "$def" ]]; then
            gum input --header "$label" --value "$def"
        else
            gum input --header "$label" --placeholder "empty to skip"
        fi
        return 0
    fi
    if [[ -n "$def" ]]; then
        read -r -p "$label [$def]: " reply
        echo "${reply:-$def}"
    else
        read -r -p "$label (empty to skip): " reply
        echo "$reply"
    fi
}

is_pkg_installed() { pacman -Qi "$1" &>/dev/null; }
is_aur_installed() { pacman -Qi "$1" &>/dev/null; }

safe_link() {
    local src="$1" dest="$2"
    run mkdir -p "$(dirname "$dest")"
    if [[ -L "$dest" ]]; then
        local cur; cur="$(readlink -f "$dest" || true)"
        if [[ "$cur" == "$(readlink -f "$src")" ]]; then
            ok "link ok: $dest -> $src"
            return 0
        fi
    fi
    if [[ -e "$dest" || -L "$dest" ]]; then
        local bak="${dest}.bak.$(date +%s)"
        warn "backing up existing $dest -> $bak"
        run mv "$dest" "$bak"
    fi
    run ln -sfn "$src" "$dest"
    ok "linked $dest -> $src"
}

copy_etc() {
    local src="$JIMDOTS_REPO/$1" dest="$2" mode="${3:-644}"
    if [[ ! -f "$src" ]]; then die "missing source: $src"; fi
    if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
        ok "etc up-to-date: $dest"
        return 0
    fi
    sudo_run install -Dm"$mode" "$src" "$dest"
    ok "installed $dest"
}

ensure_line() {
    local file="$1" line="$2"
    grep -qxF "$line" "$file" 2>/dev/null || run bash -c "printf '%s\n' \"$line\" >> \"$file\""
}

sudo_ensure_line() {
    local file="$1" line="$2"
    if sudo grep -qxF "$line" "$file" 2>/dev/null; then
        ok "line present in $file"
        return 0
    fi
    sudo_run bash -c "printf '%s\n' \"$line\" >> \"$file\""
}

load_machine_conf() {
    local f="$JIMDOTS_REPO/machine.local.conf"
    if [[ -f "$f" ]]; then
        # shellcheck source=/dev/null
        . "$f"
        log "loaded $f"
    fi
}

save_machine_conf() {
    local f="$JIMDOTS_REPO/machine.local.conf"
    {
        echo "# jimdots machine-local config — gitignored"
        echo "# generated $(_ts)"
        for var in HOSTNAME GIT_NAME GIT_EMAIL SWAP_UUID DDC_BUS ENABLE_HIBERNATE; do
            local val="${!var-}"
            [[ -n "$val" ]] && printf '%s=%q\n' "$var" "$val"
        done
    } > "$f"
    ok "wrote $f"
}
