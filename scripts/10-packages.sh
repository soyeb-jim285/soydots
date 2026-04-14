#!/usr/bin/env bash
# Phase 10 — install pacman + AUR packages.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

read_list() {
    local f="$1"
    [[ -f "$f" ]] || die "missing package list: $f"
    grep -v '^\s*#' "$f" | grep -v '^\s*$' | awk '{print $1}'
}

mapfile -t PAC < <(read_list "$JIMDOTS_REPO/packages/pacman.txt")
mapfile -t AUR < <(read_list "$JIMDOTS_REPO/packages/aur.txt")

info "installing ${#PAC[@]} pacman packages"
if (( ${#PAC[@]} > 0 )); then
    sudo_run pacman -S --needed --noconfirm "${PAC[@]}"
fi

if ! command -v yay >/dev/null 2>&1; then
    die "yay missing — preflight phase must run first"
fi

info "installing ${#AUR[@]} AUR packages"
if (( ${#AUR[@]} > 0 )); then
    run yay -S --needed --noconfirm "${AUR[@]}"
fi

ok "packages installed"
