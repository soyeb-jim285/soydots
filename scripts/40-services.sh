#!/usr/bin/env bash
# Phase 40 — enable systemd services (system + user).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

# Services enabled-and-started immediately (safe to start during setup).
SYSTEM_SERVICES_NOW=(tty-colors.service bluetooth.service)
# Services enabled only — started on next boot. greetd would hijack the
# running TTY/session mid-setup if started now.
SYSTEM_SERVICES_ENABLE_ONLY=(greetd.service)
USER_SERVICES=(hypridle.service pipewire.service pipewire-pulse.service wireplumber.service)

_user_bus_up() {
    [[ -n "${XDG_RUNTIME_DIR:-}" ]] \
        && [[ -S "$XDG_RUNTIME_DIR/bus" || -S "$XDG_RUNTIME_DIR/systemd/private" ]]
}

info "reloading systemd"
sudo_run systemctl daemon-reload
if _user_bus_up; then
    run timeout 10 systemctl --user daemon-reload || warn "user daemon-reload failed/timed out"
else
    warn "no user systemd bus — skipping user daemon-reload"
fi

for s in "${SYSTEM_SERVICES_NOW[@]}"; do
    if ! systemctl list-unit-files "$s" --no-legend --quiet 2>/dev/null | grep -q .; then
        warn "system unit $s not installed — skipping"
        continue
    fi
    sudo_run systemctl enable --now "$s"
done

for s in "${SYSTEM_SERVICES_ENABLE_ONLY[@]}"; do
    if ! systemctl list-unit-files "$s" --no-legend --quiet 2>/dev/null | grep -q .; then
        warn "system unit $s not installed — skipping"
        continue
    fi
    sudo_run systemctl enable "$s"
    info "$s enabled (will start on next boot)"
done

if _user_bus_up; then
    for s in "${USER_SERVICES[@]}"; do
        if ! timeout 5 systemctl --user list-unit-files "$s" --no-legend --quiet 2>/dev/null | grep -q .; then
            warn "user unit $s not installed — skipping"
            continue
        fi
        run timeout 15 systemctl --user enable --now "$s" || warn "enable $s failed/timed out"
    done
else
    warn "no user systemd bus — skipping user services (run again from a graphical session)"
fi

ok "services enabled"
