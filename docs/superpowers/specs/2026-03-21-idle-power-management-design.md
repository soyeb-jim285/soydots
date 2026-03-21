# Idle & Power Management Design

## Overview

Implement a complete idle management pipeline with configurable timeouts and toggles, integrated into the Quickshell settings system. Replace the system-default hypridle.conf with a Quickshell-managed one. Enable hibernate via suspend-then-hibernate.

## Architecture

### Components

1. **`hypr/hypridle.conf`** — Generated config file, symlinked to `~/.config/hypr/hypridle.conf`
2. **`quickshell/IdleManager.qml`** — Watches Config idle properties, regenerates hypridle.conf and restarts hypridle on changes
3. **`quickshell/Config.qml`** — New `[idle]` section with properties for each stage
4. **`quickshell/settings/PowerIdlePage.qml`** — New settings page for Power & Idle configuration
5. **`quickshell/Settings.qml`** — Updated pages list to include new page

### Data Flow

```
Settings UI (sliders/toggles)
  → Config.qml properties (persisted to settings.toml)
    → IdleManager.qml (watches properties, debounced 500ms)
      → Writes hypr/hypridle.conf
        → Restarts hypridle process (pkill + wait + launch)
```

## Idle Stages

Each stage has an **enabled toggle** and a **timeout slider**.

| Stage | Default Timeout | Range | on-timeout | on-resume |
|-------|----------------|-------|------------|-----------|
| Dim | 180s (3min) | 30–600s | `brightnessctl -s set 10` | `brightnessctl -r` |
| Lock | 300s (5min) | 60–1800s | `loginctl lock-session` | — |
| DPMS Off | 330s (5.5min) | 60–1800s | `hyprctl dispatch dpms off` | `hyprctl dispatch dpms on` |
| Suspend | 1200s (20min) | 300–3600s | `systemctl suspend-then-hibernate` or `systemctl suspend` | — |

### Global Handlers

- `lock_cmd = loginctl lock-session` — Handles lock signal (triggers Quickshell's WlSessionLock)
- `before_sleep_cmd = loginctl lock-session` — Always lock before suspend
- `after_sleep_cmd = hyprctl dispatch dpms on` — Turn screen on after wake

### Hibernate

- Suspend action uses `systemctl suspend-then-hibernate` when hibernate is enabled, otherwise `systemctl suspend`
- Hibernate delay is configured via systemd's `HibernateDelaySec` in `/etc/systemd/sleep.conf.d/`
- Default hibernate delay: 7200s (2 hours)
- The hibernate delay slider in the settings UI is **display-only for the current value** — changing it shows an info message that the system config must be updated manually with a `sudo` command (since writing to `/etc/systemd/sleep.conf.d/` requires root)

## Config.qml Changes

### New Properties (`[idle]` section)

```qml
// ===== IDLE =====

property bool idleDimEnabled: _data?.idle?.dimEnabled ?? true
property int idleDimTimeout: _data?.idle?.dimTimeout ?? 180
property bool idleLockEnabled: _data?.idle?.lockEnabled ?? true
property int idleLockTimeout: _data?.idle?.lockTimeout ?? 300
property bool idleDpmsEnabled: _data?.idle?.dpmsEnabled ?? true
property int idleDpmsTimeout: _data?.idle?.dpmsTimeout ?? 330
property bool idleSuspendEnabled: _data?.idle?.suspendEnabled ?? true
property int idleSuspendTimeout: _data?.idle?.suspendTimeout ?? 1200
property bool idleHibernateEnabled: _data?.idle?.hibernateEnabled ?? true
property int idleHibernateDelay: _data?.idle?.hibernateDelay ?? 7200
```

### _doSave() Addition

Add to the `d` object in `_doSave()`:

```javascript
idle: {
    dimEnabled: idleDimEnabled, dimTimeout: idleDimTimeout,
    lockEnabled: idleLockEnabled, lockTimeout: idleLockTimeout,
    dpmsEnabled: idleDpmsEnabled, dpmsTimeout: idleDpmsTimeout,
    suspendEnabled: idleSuspendEnabled, suspendTimeout: idleSuspendTimeout,
    hibernateEnabled: idleHibernateEnabled, hibernateDelay: idleHibernateDelay
},
```

### _defaultsTOML Addition

Add to the defaults string:

```toml
[idle]
dimEnabled = true
dimTimeout = 180
dpmsEnabled = true
dpmsTimeout = 330
hibernateDelay = 7200
hibernateEnabled = true
lockEnabled = true
lockTimeout = 300
suspendEnabled = true
suspendTimeout = 1200
```

### sectionNames Addition

Add `"idle"` to the `sectionNames` array.

## IdleManager.qml

A `Scope` loaded in `shell.qml`:

- Watches all `Config.idle*` properties via `Connections`
- On any change, starts a 500ms debounce `Timer`
- When timer fires:
  1. Builds hypridle.conf string from current Config values (only includes enabled stages)
  2. Writes to `~/jimdots/hypr/hypridle.conf` via `Process` (bash heredoc)
  3. On write complete, restarts hypridle robustly: `pkill -x hypridle; while pgrep -x hypridle >/dev/null; do sleep 0.1; done; hypridle &`
- **Always regenerates on startup** (compares current Config values with what would be generated, writes if different or file doesn't exist) — ensures config is never stale after crashes
- **Respects caffeine state**: before restarting hypridle, checks `NotificationCenter.caffeineEnabled` (or a shared caffeine property). If caffeine is active, writes the config but does NOT restart hypridle. The caffeine-off handler will pick up the new config when it restarts hypridle.

### Caffeine Interaction

The caffeine toggle in NotificationCenter.qml currently does `pkill hypridle` / `hypridle &`. When IdleManager regenerates config while caffeine is active:
- Config file is updated (so next restart uses new settings)
- hypridle is NOT restarted (respecting caffeine)
- When user disables caffeine, `hypridle &` launches with the latest config

To implement this, add a `property bool caffeineEnabled` to the IdleManager (or read it from a shared location), and skip the restart step when true.

### Generated hypridle.conf Format

```
# Auto-generated by Quickshell IdleManager — do not edit manually

general {
    lock_cmd = loginctl lock-session
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener {
    timeout = 180
    on-timeout = brightnessctl -s set 10
    on-resume = brightnessctl -r
}

listener {
    timeout = 300
    on-timeout = loginctl lock-session
}

listener {
    timeout = 330
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}

listener {
    timeout = 1200
    on-timeout = systemctl suspend-then-hibernate
}
```

Only enabled stages are included. If e.g. dimming is disabled, the first listener block is omitted entirely.

## PowerIdlePage.qml

Settings page with sections. All timeout sliders show formatted time (e.g. "3m 0s", "20m 0s") using a helper function `formatTime(seconds)` defined in the page.

### Screen Dimming
- `ToggleSetting` — Enable/disable dimming
- `SliderSetting` — Dim timeout (30–600s)

### Auto Lock
- `ToggleSetting` — Enable/disable auto-lock
- `SliderSetting` — Lock timeout (60–1800s)

### Screen Off (DPMS)
- `ToggleSetting` — Enable/disable DPMS
- `SliderSetting` — DPMS timeout (60–1800s)

### Auto Suspend
- `ToggleSetting` — Enable/disable auto-suspend
- `SliderSetting` — Suspend timeout (300–3600s)

### Hibernate
- `ToggleSetting` — Enable hibernate (uses suspend-then-hibernate vs plain suspend)
- `SliderSetting` — Hibernate delay after suspend (1800–14400s)
- Info text: "Requires system setup (see below). Change delay with: `sudo mkdir -p /etc/systemd/sleep.conf.d && echo '[Sleep]\nHibernateDelaySec=Xh' | sudo tee /etc/systemd/sleep.conf.d/hibernate.conf`"

### System Requirements
- Static info text listing the manual commands needed for hibernate:
  - Add `resume` hook to `/etc/mkinitcpio.conf` HOOKS
  - Add `resume=<swap-partition>` kernel parameter (note: varies per system, currently `/dev/nvme0n1p2`)
  - Rebuild initramfs: `sudo mkinitcpio -P`
  - Create `/etc/systemd/sleep.conf.d/hibernate.conf` with `HibernateDelaySec`
  - Reboot for kernel param to take effect

## Settings.qml Changes

Updated pages array (new entry at index 11, Integrations moves to 12):

```qml
property var pages: [
    { name: "Appearance", icon: "\uf53f", section: "appearance" },
    { name: "Bar", icon: "\uf0c9", section: "bar" },
    { name: "Notifications", icon: "\uf0f3", section: "notifications" },
    { name: "Launcher", icon: "\uf135", section: "launcher" },
    { name: "Clipboard", icon: "\uf328", section: "clipboard" },
    { name: "OSD", icon: "\uf26c", section: "osd" },
    { name: "Animations", icon: "\uf021", section: "animations" },
    { name: "Network", icon: "\uf1eb", section: "network" },
    { name: "Calendar", icon: "\uf073", section: "calendar" },
    { name: "Battery", icon: "\uf240", section: "battery" },
    { name: "Lock Screen", icon: "\uf023", section: "lockscreen" },
    { name: "Power & Idle", icon: "\uf0e7", section: "idle" },
    { name: "Integrations", icon: "\uf0c1", section: "hyprland" }
]
```

Updated loader names array:

```qml
let names = ["AppearancePage", "BarPage", "NotificationsPage",
             "LauncherPage", "ClipboardPage", "OsdPage",
             "AnimationsPage", "NetworkPage", "CalendarPage",
             "BatteryPage", "LockScreenPage", "PowerIdlePage",
             "IntegrationsPage"];
```

## PowerMenu.qml Changes

Update suspend action to respect `Config.idleHibernateEnabled`:

```qml
Process { id: suspendProc; command: ["systemctl", Config.idleHibernateEnabled ? "suspend-then-hibernate" : "suspend"] }
```

This keeps the power menu's manual suspend consistent with the idle behavior.

## Existing Integration

### Caffeine (NotificationCenter.qml)
Mostly unchanged. The `hypridle &` restart on caffeine-off picks up the latest generated config. IdleManager skips restarting hypridle when caffeine is active.

### Lock Screen (LockScreen.qml)
No changes needed. `loginctl lock-session` triggers the Wayland session lock protocol which Quickshell's `WlSessionLock` handles.

## System-Level Prerequisites (Manual)

These commands must be run manually (documented in tasks.md for the setup script):

```bash
# 1. Add resume hook to initramfs
sudo sed -i 's/HOOKS=(\(.*\)filesystems/HOOKS=(\1resume filesystems/' /etc/mkinitcpio.conf

# 2. Add resume kernel parameter (depends on bootloader)
# For systemd-boot: edit /boot/loader/entries/*.conf, add resume=/dev/nvme0n1p2
# For GRUB: edit /etc/default/grub GRUB_CMDLINE_LINUX_DEFAULT, run grub-mkconfig
# Note: swap partition path varies per system

# 3. Rebuild initramfs
sudo mkinitcpio -P

# 4. Create systemd sleep config
sudo mkdir -p /etc/systemd/sleep.conf.d
echo -e "[Sleep]\nHibernateDelaySec=2h" | sudo tee /etc/systemd/sleep.conf.d/hibernate.conf

# 5. Reboot for kernel param to take effect
```

## Symlink

Ensure `~/.config/hypr/hypridle.conf` symlinks to `~/jimdots/hypr/hypridle.conf`. Add to setup/symlink instructions in tasks.md.

## tasks.md Updates

Add to Configured section:
- hypridle custom config (Quickshell-managed, auto-generated from settings)
- Idle pipeline: dim (3min) → lock (5min) → DPMS off (5.5min) → suspend-then-hibernate (20min)
- Power & Idle settings page in Quickshell settings (configurable timeouts and toggles for each stage)

Add to a new "System Setup Required" section:
- Hibernate prerequisites: resume hook in mkinitcpio, resume= kernel parameter for swap partition, mkinitcpio rebuild, systemd sleep.conf.d/hibernate.conf with HibernateDelaySec, reboot
- Symlink: `~/.config/hypr/hypridle.conf` → `~/jimdots/hypr/hypridle.conf`
