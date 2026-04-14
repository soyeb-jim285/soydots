#!/usr/bin/env bash
# Phase 40 — enable systemd services (system + user).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

SYSTEM_SERVICES=(tty-colors.service greetd.service bluetooth.service)
USER_SERVICES=(hypridle.service pipewire.service pipewire-pulse.service wireplumber.service)

info "reloading systemd"
sudo_run systemctl daemon-reload
run systemctl --user daemon-reload || true

for s in "${SYSTEM_SERVICES[@]}"; do
    if ! systemctl list-unit-files "$s" --no-legend --quiet 2>/dev/null | grep -q .; then
        warn "system unit $s not installed — skipping"
        continue
    fi
    sudo_run systemctl enable --now "$s"
done

for s in "${USER_SERVICES[@]}"; do
    if ! systemctl --user list-unit-files "$s" --no-legend --quiet 2>/dev/null | grep -q .; then
        warn "user unit $s not installed — skipping"
        continue
    fi
    run systemctl --user enable --now "$s"
done

ok "services enabled"
