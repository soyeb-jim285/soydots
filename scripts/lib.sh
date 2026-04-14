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
    C_RESET=$'\e[0m'; C_DIM=$'\e[2m'; C_RED=$'\e[31m'; C_YEL=$'\e[33m'; C_GRN=$'\e[32m'; C_BLU=$'\e[34m'
else
    C_RESET=""; C_DIM=""; C_RED=""; C_YEL=""; C_GRN=""; C_BLU=""
fi

_ts() { date '+%Y-%m-%d %H:%M:%S'; }

log()  { printf '%s[%s]%s %s\n' "$C_DIM" "$(_ts)" "$C_RESET" "$*" | tee -a "$JIMDOTS_LOG" >&2; }
info() { printf '%s==>%s %s\n' "$C_BLU" "$C_RESET" "$*" | tee -a "$JIMDOTS_LOG" >&2; }
ok()   { printf '%s ok%s %s\n' "$C_GRN" "$C_RESET" "$*" | tee -a "$JIMDOTS_LOG" >&2; }
warn() { printf '%s warn%s %s\n' "$C_YEL" "$C_RESET" "$*" | tee -a "$JIMDOTS_LOG" >&2; }
die()  { printf '%s err%s %s\n' "$C_RED" "$C_RESET" "$*" | tee -a "$JIMDOTS_LOG" >&2; exit 1; }

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
    local hint="[y/N]"; [[ "$default" == "y" ]] && hint="[Y/n]"
    read -r -p "$q $hint " reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy]$ ]]
}

prompt_default() {
    local label="$1" def="${2:-}" reply
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
