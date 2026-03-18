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
- fuzzel (app launcher/picker, used for clipboard history UI)

## Configured
- kitty (Catppuccin Mocha theme, 0.6 background opacity)
- hyprland keybindings:
  - Meta+Return: terminal, Meta+Q: close, Meta+W: browser, Meta+R: app launcher
  - Meta+Shift+S: region screenshot to clipboard, Meta+Shift+F: fullscreen to clipboard
  - Meta+Shift+A: region screenshot to file, Meta+Shift+W: window screenshot to clipboard
  - Meta+V: clipboard history, Meta+Alt+V: toggle floating
- hyprland autostart: cliphist (text + image watchers)
- hyprland autostart: quickshell
- quickshell app launcher — Catppuccin Mocha themed, fuzzy search, keyboard navigation, IPC toggle
- quickshell clipboard history — Catppuccin Mocha themed, search, image preview, IPC toggle (Meta+V)
- quickshell status bar — Catppuccin Mocha themed with:
  - Workspaces (left, animated pill indicators, clickable)
  - Clock + date (center, hover to open calendar panel with inverted corners, slide animation)
  - Media player (right, MPRIS, conditional visibility)
  - Volume (right, Pipewire, scroll to adjust, popup slider)
  - Battery (right, UPower, hidden on desktop, popup with stats)
  - Network status (right, nmcli-based)
  - System tray (right)

## Dotfiles Structure
All configs live in `~/jimdots/` and are symlinked to `~/.config/`:
- `kitty/` -> `~/.config/kitty` (kitty.conf, current-theme.conf)
- `quickshell/` -> `~/.config/quickshell` (shell.qml, AppLauncher.qml)
- `hypr/` -> `~/.config/hypr` (hyprland.conf)
- `claude/settings.json` -> `~/.claude/settings.json`
- `claude/statusline-command.sh` -> `~/.claude/statusline-command.sh`

