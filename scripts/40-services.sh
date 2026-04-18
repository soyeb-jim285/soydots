#!/usr/bin/env bash
# Phase 40 — enable systemd services (system + user).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

# Services enabled-and-started immediately (safe to start during setup).
SYSTEM_SERVICES_NOW=(tty-colors.service bluetooth.service plocate-updatedb.timer)
# Services enabled only — started on next boot. greetd would hijack the
# running TTY/session mid-setup if started now.
SYSTEM_SERVICES_ENABLE_ONLY=(greetd.service)
USER_SERVICES=(hypridle.service pipewire.service pipewire-pulse.service wireplumber.service)

_user_bus_up() {
    [[ -n "${XDG_RUNTIME_DIR:-}" ]] \
        && [[ -S "$XDG_RUNTIME_DIR/bus" || -S "$XDG_RUNTIME_DIR/systemd/private" ]]
}

# Detect whether we're running inside a live graphical session. If not,
# user services are only `enable`d (not `--now` started) — starting them
# from a TTY without WAYLAND_DISPLAY/DBUS coordination tends to wedge
# `systemctl --user` on a fresh install.
_graphical_session() {
    [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]]
}

info "reloading systemd"
sudo_run systemctl daemon-reload
if _user_bus_up; then
    run timeout --kill-after=5 10 systemctl --user daemon-reload \
        || warn "user daemon-reload failed/timed out"
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
    if _graphical_session; then
        user_enable_args=(enable --now)
        info "graphical session detected — enabling + starting user services now"
    else
        user_enable_args=(enable)
        info "TTY session — enabling user services only (start on next graphical login)"
    fi
    for s in "${USER_SERVICES[@]}"; do
        if ! timeout --kill-after=5 5 systemctl --user list-unit-files "$s" \
                --no-legend --quiet 2>/dev/null | grep -q .; then
            warn "user unit $s not installed — skipping"
            continue
        fi
        run timeout --kill-after=5 15 systemctl --user "${user_enable_args[@]}" "$s" \
            || warn "enable $s failed/timed out"
    done
else
    warn "no user systemd bus — skipping user services (run again from a graphical session)"
fi

ok "services enabled"
