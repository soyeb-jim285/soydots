# Unified Light/Dark Theme System

## Overview

A centralized light/dark mode toggle that switches the entire desktop between Catppuccin Mocha (dark) and Catppuccin Latte (light). Triggered via keybind (Super+Shift+T) or a settings toggle in quickshell. All synced apps update in real-time or near-real-time.

## 1. Core Mode Property

A `darkMode` boolean in `Config.qml`, persisted in `settings.toml` under `[appearance]`. Defaults to `true` (Mocha).

Toggling `darkMode` swaps all 20 Catppuccin color properties to the corresponding Mocha or Latte values in one atomic operation. This triggers all existing `onColorChanged` handlers, which cascade into the per-app sync functions.

## 2. Kitty Sync — Light-Aware Mappings

`_buildKittyTheme()` uses different color mappings based on `darkMode`:

**Dark mode (Mocha)** — current mappings:
- `color0 = surface1`, `color7 = subtext1`, `color8 = surface2`, `color15 = subtext0`
- cursor/selection use `lavender`

**Light mode (Latte)** — official Catppuccin Latte mappings:
- `color0 = subtext1` (#5c5f77), `color7 = surface2` (#acb0be), `color8 = subtext0` (#6c6f85), `color15 = surface1` (#bcc0cc)
- cursor/selection use `rosewater` (#dc8a78) instead of `lavender`

ANSI colors 1-6 and 9-14 continue mapping directly from the palette (red, green, yellow, blue, pink, teal) — correct in both modes.

## 3. GTK / Zen Browser (gsettings)

New `_syncGtk()` function runs on toggle:
```
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'   // dark
gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'  // light
```

The hardcoded `exec-once = gsettings ... prefer-dark` in `hyprland.conf` is removed. Config.qml handles this on startup based on the persisted `darkMode` value.

## 4. Qt Apps — Kvantum + qt6ct

New `_syncQt()` function rewrites two config files on toggle:

**Kvantum** (`~/.config/Kvantum/kvantum.kvconfig`):
- Dark: `theme=catppuccin-mocha-lavender`
- Light: `theme=catppuccin-latte-lavender`

Requires `catppuccin-latte-lavender` Kvantum theme to be installed.

**qt6ct** (`~/.config/qt6ct/qt6ct.conf`):
- Swaps `color_scheme_path` between `catppuccin-mocha.conf` and `catppuccin-latte.conf`
- A new `catppuccin-latte.conf` color scheme file is added alongside the existing mocha one

Qt apps pick up changes on next launch (Qt limitation).

## 5. Zen Browser Extension

A lightweight WebExtension with file-based IPC for real-time browser theming.

### Extension behavior
- Polls `~/.config/zen-theme.json` every 1 second
- On change, calls `browser.theme.update()` with new colors
- Maps Catppuccin palette to Firefox theme properties (toolbar, toolbar_text, frame, tab_background_text, popup, etc.)

### zen-theme.json format
```json
{
  "mode": "dark",
  "colors": {
    "base": "#1e1e2e",
    "mantle": "#181825",
    "crust": "#11111b",
    "text": "#cdd6f4",
    "subtext0": "#a6adc8",
    "subtext1": "#bac2de",
    "surface0": "#313244",
    "surface1": "#45475a",
    "surface2": "#585b70",
    "overlay0": "#6c7086",
    "blue": "#89b4fa",
    "lavender": "#b4befe",
    "red": "#f38ba8",
    "green": "#a6e3a1",
    "yellow": "#f9e2af",
    "mauve": "#cba6f7",
    "pink": "#f5c2e7",
    "teal": "#94e2d5",
    "peach": "#fab387"
  }
}
```

### Installation
- Extension source lives in dotfiles repo at `zen/theme-sync/`
- Setup script places `policies.json` in Zen's distribution folder to force-install the extension
- Sets `xpinstall.signatures.required = false` via policies if needed

### Quickshell side
- New `_syncZen()` function writes `zen-theme.json` on toggle, same debounced Process pattern as kitty/hyprland sync

## 6. Keybind + Settings Toggle

### Keybind
Added to `hyprland.conf`:
```
bind = $mainMod SHIFT, T, exec, quickshell msg theme toggle
```

Quickshell receives the IPC message and flips `darkMode`.

### Settings UI
A toggle switch at the top of `AppearancePage.qml` — "Dark Mode" on/off. Existing theme preset buttons (Mocha/Macchiato/Frappe/Latte) remain for manual color customization.

### Startup
On quickshell launch, the persisted `darkMode` value drives an initial sync to all apps (gsettings, kvantum, qt6ct, zen-theme.json). Replaces the hardcoded `exec-once = gsettings ... prefer-dark` in hyprland.conf.

## 7. Sync Flow

```
User presses Super+Shift+T  OR  flips toggle in Settings
  -> Config.darkMode flips
  -> Persisted to settings.toml
  -> All 20 color properties swap (Mocha <-> Latte)
  -> Triggers existing onChange handlers:
      |-- _syncKitty()      -> writes current-theme.conf (light-aware), live-reloads
      |-- _syncHyprland()   -> writes quickshell-theme.conf, reloads borders
      |-- _syncTmux()       -> updates tmux theme
      |-- _syncGtk()  [NEW] -> gsettings prefer-dark/prefer-light
      |-- _syncQt()   [NEW] -> rewrites kvantum.kvconfig + qt6ct.conf
      |-- _syncZen()  [NEW] -> writes zen-theme.json
  -> Quickshell UI updates instantly (Theme.qml reads from Config)
```

### Update latency
- Kitty, Hyprland, Tmux, Quickshell: real-time
- GTK/Zen (gsettings): real-time for most apps
- Zen (extension): ~1 second delay (polling)
- Qt apps: next launch (Qt limitation)

## Files Modified

- `quickshell/Config.qml` — darkMode property, color swap logic, _syncGtk(), _syncQt(), _syncZen()
- `quickshell/settings/AppearancePage.qml` — dark mode toggle at top
- `quickshell/shell.qml` — IPC handler for `theme toggle` message
- `quickshell/defaults.toml` — darkMode default
- `hypr/hyprland.conf` — add keybind, remove hardcoded gsettings exec-once
- `qt6ct/colors/catppuccin-latte.conf` — new file
- `zen/theme-sync/` — new extension (manifest.json, background.js)
- `zen/install-extension.sh` — setup script for policies.json
