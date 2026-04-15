#!/usr/bin/env bash
# Phase 10 — install all packages via yay (repo + AUR through one tool).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

read_list() {
    local f="$1"
    [[ -f "$f" ]] || die "missing package list: $f"
    grep -v '^\s*#' "$f" | grep -v '^\s*$' | awk '{print $1}'
}

mapfile -t PKGS < <(read_list "$JIMDOTS_REPO/packages/packages.txt")

if ! command -v yay >/dev/null 2>&1; then
    die "yay missing — preflight phase must run first"
fi

info "installing ${#PKGS[@]} packages via yay"
if (( ${#PKGS[@]} > 0 )); then
    run yay -S --needed --noconfirm "${PKGS[@]}"
fi

ok "packages installed"
