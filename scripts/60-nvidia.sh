#!/usr/bin/env bash
# Phase 60 — optional NVIDIA setup (detect + prompt).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

if ! lspci | grep -qi nvidia; then
    log "no NVIDIA GPU detected — skipping"
    exit 0
fi

info "NVIDIA GPU detected"
if ! confirm "Run setup-nvidia.sh now?" n; then
    warn "skipping NVIDIA setup at user's request"
    exit 0
fi

script="$JIMDOTS_REPO/setup-nvidia.sh"
[[ -x "$script" ]] || die "setup-nvidia.sh missing or not executable"
run bash "$script"
ok "NVIDIA setup complete"
