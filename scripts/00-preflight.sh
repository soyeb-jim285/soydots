#!/usr/bin/env bash
# Phase 00 — preflight: verify env, bootstrap yay, collect machine config.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

[[ -f /etc/arch-release ]] || die "not running on Arch Linux"

info "refreshing sudo"
sudo -v
( while true; do sleep 60; sudo -n true 2>/dev/null || exit; done ) &
SUDO_KEEPALIVE=$!
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null || true' EXIT

info "network check"
if ! ping -c1 -W3 archlinux.org >/dev/null 2>&1; then
    die "no network connectivity to archlinux.org"
fi

info "ensuring base-devel, git, gum"
# gum is installed here so the remaining preflight prompts use its nicer UI.
if ! is_pkg_installed base-devel || ! is_pkg_installed git || ! command -v gum >/dev/null 2>&1; then
    sudo_run pacman -S --needed --noconfirm base-devel git gum
fi

if ! command -v yay >/dev/null 2>&1; then
    info "bootstrapping yay from AUR"
    local_tmp="$(mktemp -d)"
    run git clone https://aur.archlinux.org/yay.git "$local_tmp/yay"
    (
        cd "$local_tmp/yay"
        run makepkg -si --noconfirm
    )
    rm -rf "$local_tmp"
fi

# Load or build machine.local.conf
load_machine_conf

if [[ -z "${HOSTNAME:-}" ]]; then
    HOSTNAME="$(prompt_default "Hostname" "$(hostnamectl --static 2>/dev/null || hostname)")"
fi

if [[ -z "${GIT_NAME:-}" ]] && confirm "Configure global git user.name/user.email now?" y; then
    GIT_NAME="$(prompt_default "git user.name" "${GIT_NAME:-}")"
    GIT_EMAIL="$(prompt_default "git user.email" "${GIT_EMAIL:-}")"
fi

if [[ -z "${ENABLE_HIBERNATE:-}" ]]; then
    if confirm "Enable hibernate (requires swap partition)?" n; then
        ENABLE_HIBERNATE=1
    else
        ENABLE_HIBERNATE=0
    fi
fi

if [[ "${ENABLE_HIBERNATE:-0}" == "1" && -z "${SWAP_UUID:-}" ]]; then
    swap_dev="$(swapon --show=NAME --noheadings | head -n1 || true)"
    detected=""
    if [[ -n "$swap_dev" && -b "$swap_dev" ]]; then
        detected="$(blkid -s UUID -o value "$swap_dev" 2>/dev/null || true)"
    fi
    SWAP_UUID="$(prompt_default "Swap partition UUID" "$detected")"
fi

if [[ -z "${DDC_BUS:-}" ]] && command -v ddcutil >/dev/null 2>&1; then
    info "detecting DDC bus (may take a moment)"
    detected_bus="$(ddcutil detect 2>/dev/null | awk '/I2C bus/ {gsub(/[^0-9]/,"",$NF); print $NF; exit}')"
    if [[ -n "$detected_bus" ]]; then
        if confirm "Use detected DDC bus $detected_bus?" y; then
            DDC_BUS="$detected_bus"
        fi
    fi
fi

export HOSTNAME GIT_NAME GIT_EMAIL SWAP_UUID DDC_BUS ENABLE_HIBERNATE
save_machine_conf
ok "preflight complete"
