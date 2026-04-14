#!/usr/bin/env bash
# Phase 30 — install /etc files, mkinitcpio resume hook, i2c group/module,
# print bootloader instructions (if hibernate enabled).
set -euo pipefail
. "$(dirname "$0")/lib.sh"
load_machine_conf

info "installing /etc files"
copy_etc etc/greetd/config.toml /etc/greetd/config.toml 644
copy_etc etc/vconsole.conf /etc/vconsole.conf 644
copy_etc etc/tty-colors.pal /etc/tty-colors.pal 644
copy_etc etc/systemd/system/tty-colors.service /etc/systemd/system/tty-colors.service 644

if [[ "${ENABLE_HIBERNATE:-0}" == "1" ]]; then
    copy_etc etc/systemd/sleep.conf.d/hibernate.conf /etc/systemd/sleep.conf.d/hibernate.conf 644
fi

info "configuring i2c (DDC brightness)"
if ! getent group i2c >/dev/null; then
    sudo_run groupadd -f i2c
fi
if ! id -nG "$USER" | tr ' ' '\n' | grep -qx i2c; then
    sudo_run usermod -aG i2c "$USER"
    warn "added $USER to group i2c — log out/in to pick it up"
fi
if ! id -nG "$USER" | tr ' ' '\n' | grep -qx video; then
    sudo_run usermod -aG video "$USER"
fi

sudo_run modprobe i2c-dev || true
if ! sudo grep -qxF i2c-dev /etc/modules-load.d/i2c-dev.conf 2>/dev/null; then
    sudo_run bash -c 'printf "i2c-dev\n" > /etc/modules-load.d/i2c-dev.conf'
fi

if [[ "${ENABLE_HIBERNATE:-0}" == "1" ]]; then
    info "ensuring resume hook in /etc/mkinitcpio.conf"
    if ! sudo grep -E '^HOOKS=.*\bresume\b' /etc/mkinitcpio.conf >/dev/null; then
        warn "inserting resume hook before filesystems in mkinitcpio.conf"
        sudo_run sed -i.bak -E 's/(^HOOKS=\([^)]*)\bfilesystems\b/\1resume filesystems/' /etc/mkinitcpio.conf
        sudo_run mkinitcpio -P
    else
        ok "mkinitcpio resume hook already present"
    fi

    if [[ -n "${SWAP_UUID:-}" ]]; then
        if [[ -d /boot/loader/entries ]]; then
            loader_dir=/boot/loader/entries
            entry="$(ls -1 "$loader_dir"/*.conf 2>/dev/null | head -n1 || true)"
            warn "systemd-boot detected. Add to options line in $entry (or your default entry):"
            warn "    resume=UUID=$SWAP_UUID"
        elif [[ -f /etc/default/grub ]]; then
            warn "GRUB detected. Edit /etc/default/grub GRUB_CMDLINE_LINUX_DEFAULT to include:"
            warn "    resume=UUID=$SWAP_UUID"
            warn "then run: sudo grub-mkconfig -o /boot/grub/grub.cfg"
        else
            warn "unknown bootloader — ensure your kernel cmdline includes: resume=UUID=$SWAP_UUID"
        fi
    else
        warn "ENABLE_HIBERNATE=1 but SWAP_UUID empty — skipping bootloader hint"
    fi
fi

ok "system configuration complete"
