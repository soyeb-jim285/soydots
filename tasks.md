# Arch Hyprland Setup

## Installed
- hyprpolkitagent (polkit authentication agent for Hyprland)
- git
- base-devel
- zen-browser-bin
- wl-clipboard
- zip, unzip
- maple mono fonts (Nerd Font)
- neovim (configured with LazyVim)
- quickshell (shell/panel framework for building the desktop UI)
- jq (JSON parser, used by claude code statusline)
- pipewire-pulse, pipewire-alsa (audio support for Pipewire)
- maple mono NF (Nerd Font variant, for bar/launcher icons)
- grim, slurp (Wayland screenshot tools)
- hyprshot (Hyprland screenshot tool with freeze/region/window support)
- swappy (screenshot annotation)
- cliphist (clipboard history manager)
- fuzzel (app launcher/picker)
- bluez, bluez-utils (Bluetooth stack and utilities)
- brightnessctl (backlight brightness control)
- hyprsunset (night light / warm color filter)
- hyprlock (Hyprland lock screen)
- hypridle (idle daemon, screen sleep management)
- nvidia-open-dkms, nvidia-utils, nvidia-settings (NVIDIA open kernel driver for GTX 1650 Mobile)
- linux-headers (needed for DKMS kernel module building)

## Configured
- kitty (Catppuccin Mocha theme, 0.6 background opacity)
- hyprland keybindings:
  - Meta+Return: terminal, Meta+Q: close, Meta+W: browser, Meta+R: app launcher
  - Meta+F5/F6: brightness down/up
  - Meta+Shift+P: region screenshot to clipboard, Meta+Shift+F: fullscreen to clipboard
  - Meta+Shift+A: region screenshot to file, Meta+Shift+W: window screenshot to clipboard
  - Meta+V: clipboard history, Meta+Alt+V: toggle floating, Meta+Shift+B: animation picker
- hyprland autostart: cliphist (text + image watchers)
- hyprland autostart: quickshell
- quickshell app launcher — Catppuccin Mocha themed, fuzzy search, keyboard navigation, IPC toggle
- quickshell clipboard history — Catppuccin Mocha themed, search, image preview, IPC toggle (Meta+V)
- quickshell animation picker — full-screen overlay with shadcn-style arc spinner speed variants (Slow/Gentle/Medium/Brisk/Fast/Rapid), elastic sweep animation around centered link icon (Meta+Shift+B)
- quickshell status bar — Catppuccin Mocha themed with:
  - Workspaces (left, animated pill indicators, clickable)
  - Clock + date (center, hover to open calendar panel with inverted corners, slide animation)
  - Media player (right, MPRIS, conditional visibility)
  - Volume (right, Pipewire, scroll to adjust, click to mute)
  - Battery (right, UPower, hidden on desktop, popup with stats)
  - Bluetooth (right, Quickshell.Bluetooth native D-Bus API, hover to open panel with paired devices, connect/disconnect with arc spinner animation, power toggle, reactive scan)
  - Network status (right, nmcli-based, hover to open WiFi panel with network list, signal strength, connect/password support, arc spinner connect animation)
  - Notification bell (right, unread badge, click to open notification center)
  - System tray (right)
- quickshell OSD overlay — Catppuccin themed, blurred background, auto-hide:
  - Volume (triggered by Pipewire changes)
  - Brightness (triggered by brightness keys via IPC)
  - Caps Lock / Num Lock (triggered by key press via IPC)
- quickshell notification system — Catppuccin themed, blurred:
  - Toast popups (top-right, slide-in/out animations, progress bar, auto-dismiss, urgency icons/colors)
  - Notification center panel (right side, full history, clear all, IPC toggle, click to focus app/switch workspace)
  - Bell icon in status bar with unread count badge
  - Quick settings panel: Wi-Fi, Bluetooth, DND, Night Light, Screenshot, Lock
  - Volume and brightness sliders in notification center
- hyprland layer rules for blur on quickshell-osd and quickshell-notif
- nvidia: open kernel driver (nvidia-open-dkms), nouveau blacklisted, DRM modeset via modprobe, PRIME offload ready, power management udev rules, Hyprland env vars configured

## Dotfiles Structure
All configs live in `~/jimdots/` and are symlinked to `~/.config/`:
- `kitty/` -> `~/.config/kitty` (kitty.conf, current-theme.conf)
- `quickshell/` -> `~/.config/quickshell` (shell.qml, AppLauncher.qml)
- `hypr/` -> `~/.config/hypr` (hyprland.conf)
- `claude/settings.json` -> `~/.claude/settings.json`
- `claude/statusline-command.sh` -> `~/.claude/statusline-command.sh`
