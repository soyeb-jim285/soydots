# Unified Light/Dark Theme System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a centralized light/dark mode toggle that switches the entire desktop between Catppuccin Mocha (dark) and Catppuccin Latte (light), syncing quickshell, kitty, hyprland, tmux, GTK, and Qt apps in real-time.

**Architecture:** A `darkMode` boolean in Config.qml drives all theme switching. Toggling it swaps all 20 Catppuccin color properties atomically, which cascades through existing sync handlers (kitty, hyprland, tmux) and new ones (GTK gsettings, Qt/Kvantum config files). A keybind (Super+Shift+T) sends an IPC message to quickshell, and a toggle in the settings UI provides the same function.

**Tech Stack:** QML (Quickshell), Catppuccin color palettes, gsettings (GTK), Kvantum/qt6ct (Qt)

---

### Task 1: Add darkMode property and Latte palette to Config.qml

**Files:**
- Modify: `quickshell/Config.qml:135-148` (add darkMode to _doSave)
- Modify: `quickshell/Config.qml:813-834` (add darkMode property near appearance section)
- Modify: `quickshell/defaults.toml:35` (add darkMode default)

- [ ] **Step 1: Add darkMode property to Config.qml**

After line 834 (`property string lavender: ...`), add the darkMode property and Latte palette lookup:

```qml
    property bool darkMode: _data?.appearance?.darkMode ?? true

    // Catppuccin Latte palette for light mode
    readonly property var _lattePalette: ({
        base: "#eff1f5", mantle: "#e6e9ef", crust: "#dce0e8",
        surface0: "#ccd0da", surface1: "#bcc0cc", surface2: "#acb0be",
        overlay0: "#9ca0b0", overlay1: "#8c8fa1",
        text: "#4c4f69", subtext0: "#6c6f85", subtext1: "#5c5f77",
        red: "#d20f39", green: "#40a02b", yellow: "#df8e1d",
        blue: "#1e66f5", mauve: "#8839ef", pink: "#ea76cb",
        teal: "#179299", peach: "#fe640b", lavender: "#7287fd"
    })

    // Catppuccin Mocha palette for dark mode
    readonly property var _mochaPalette: ({
        base: "#1e1e2e", mantle: "#181825", crust: "#11111b",
        surface0: "#313244", surface1: "#45475a", surface2: "#585b70",
        overlay0: "#6c7086", overlay1: "#7f849c",
        text: "#cdd6f4", subtext0: "#a6adc8", subtext1: "#bac2de",
        red: "#f38ba8", green: "#a6e3a1", yellow: "#f9e2af",
        blue: "#89b4fa", mauve: "#cba6f7", pink: "#f5c2e7",
        teal: "#94e2d5", peach: "#fab387", lavender: "#b4befe"
    })

    function toggleDarkMode() {
        let newMode = !darkMode;
        let palette = newMode ? _mochaPalette : _lattePalette;
        let colors = ["base", "mantle", "crust", "surface0", "surface1", "surface2",
                      "overlay0", "overlay1", "text", "subtext0", "subtext1",
                      "red", "green", "yellow", "blue", "mauve", "pink", "teal", "peach", "lavender"];
        for (let c of colors)
            set("appearance", c, palette[c]);
        set("appearance", "darkMode", newMode);
    }
```

- [ ] **Step 2: Add darkMode to _doSave()**

In the `_doSave()` function, add `darkMode` to the appearance section. Find the line:

```qml
                transparencyEnabled: transparencyEnabled, transparencyLevel: transparencyLevel
```

Change it to:

```qml
                transparencyEnabled: transparencyEnabled, transparencyLevel: transparencyLevel,
                darkMode: darkMode
```

- [ ] **Step 3: Add darkMode default to defaults.toml**

In `quickshell/defaults.toml`, add `darkMode = true` to the `[appearance]` section, after the existing color entries. Add it before `fontFamily`:

```toml
darkMode = true
```

- [ ] **Step 4: Test manually**

Run quickshell and verify:
1. Open the settings TOML — confirm `darkMode = true` is present
2. In a QML console or by temporarily adding a keybind, call `Config.toggleDarkMode()` and verify all colors swap to Latte values
3. Call it again to verify colors swap back to Mocha

- [ ] **Step 5: Commit**

```bash
git add quickshell/Config.qml quickshell/defaults.toml
git commit -m "feat: add darkMode property and toggle to Config"
```

---

### Task 2: Fix Kitty theme for light mode

**Files:**
- Modify: `quickshell/Config.qml:460-509` (_buildKittyTheme function)

- [ ] **Step 1: Update _buildKittyTheme() to use light-aware mappings**

Replace the entire `_buildKittyTheme()` function (lines 460-509) with:

```qml
    function _buildKittyTheme() {
        // Light mode (Latte) uses different mappings for color0/7/8/15 and cursor/selection
        let isLight = !darkMode;
        let cursorColor = isLight ? "#dc8a78" : lavender;  // rosewater for light
        let selBg = isLight ? "#dc8a78" : lavender;
        let c0 = isLight ? subtext1 : surface1;
        let c7 = isLight ? surface2 : subtext1;
        let c8 = isLight ? subtext0 : surface2;
        let c15 = isLight ? surface1 : subtext0;

        return "# Auto-generated by quickshell Config\n" +
            "# Theme synced from quickshell settings\n\n" +
            "# Basic colors\n" +
            "foreground              " + text + "\n" +
            "background              " + base + "\n" +
            "selection_foreground    " + base + "\n" +
            "selection_background    " + selBg + "\n\n" +
            "# Cursor\n" +
            "cursor                  " + cursorColor + "\n" +
            "cursor_text_color       " + base + "\n\n" +
            "# URL\n" +
            "url_color               " + cursorColor + "\n\n" +
            "# Borders\n" +
            "active_border_color     " + lavender + "\n" +
            "inactive_border_color   " + overlay0 + "\n" +
            "bell_border_color       " + yellow + "\n\n" +
            "# Titlebar\n" +
            "wayland_titlebar_color  system\n" +
            "macos_titlebar_color    system\n\n" +
            "# Tabs\n" +
            "active_tab_foreground   " + (isLight ? base : crust) + "\n" +
            "active_tab_background   " + mauve + "\n" +
            "inactive_tab_foreground " + text + "\n" +
            "inactive_tab_background " + (isLight ? surface0 : mantle) + "\n" +
            "tab_bar_background      " + (isLight ? mantle : crust) + "\n\n" +
            "# Marks\n" +
            "mark1_foreground " + base + "\n" +
            "mark1_background " + lavender + "\n" +
            "mark2_foreground " + base + "\n" +
            "mark2_background " + mauve + "\n" +
            "mark3_foreground " + base + "\n" +
            "mark3_background " + teal + "\n\n" +
            "# Terminal colors\n" +
            "color0  " + c0 + "\n" +
            "color8  " + c8 + "\n" +
            "color1  " + red + "\n" +
            "color9  " + red + "\n" +
            "color2  " + green + "\n" +
            "color10 " + green + "\n" +
            "color3  " + yellow + "\n" +
            "color11 " + yellow + "\n" +
            "color4  " + blue + "\n" +
            "color12 " + blue + "\n" +
            "color5  " + pink + "\n" +
            "color13 " + pink + "\n" +
            "color6  " + teal + "\n" +
            "color14 " + teal + "\n" +
            "color7  " + c7 + "\n" +
            "color15 " + c15 + "\n";
    }
```

- [ ] **Step 2: Add darkMode change handler to trigger kitty sync**

Find the line (around 338):
```qml
    onBaseChanged: { _syncHyprland(); _syncKitty(); _syncTmux(); }
```

Add after the `onPeachChanged` line (around 348):
```qml
    onDarkModeChanged: { _syncKitty(); _syncGtk(); _syncQt(); }
```

(The _syncGtk, _syncQt functions don't exist yet — they'll be added in later tasks. This line will cause warnings until then, which is fine since we'll add them in order.)

- [ ] **Step 3: Test manually**

1. Toggle dark mode and check that `kitty/current-theme.conf` updates
2. In light mode, verify `color0` is `#5c5f77` (subtext1) not `#bcc0cc` (surface1)
3. Verify cursor is `#dc8a78` (rosewater) in light mode
4. Open a kitty terminal and confirm text is readable in both modes

- [ ] **Step 4: Commit**

```bash
git add quickshell/Config.qml
git commit -m "fix: use official Catppuccin Latte mappings for kitty light mode"
```

---

### Task 3: Add GTK sync (_syncGtk)

**Files:**
- Modify: `quickshell/Config.qml` (add _syncGtk function after the kitty sync section, around line 458)

- [ ] **Step 1: Add _syncGtk function to Config.qml**

Add after the `_kittyApplyProc` property (around line 458):

```qml
    // ===== GTK Sync =====

    property var _gtkSyncTimer: Timer {
        interval: 100
        onTriggered: config._doSyncGtk()
    }

    function _syncGtk() { _gtkSyncTimer.restart(); }

    function _doSyncGtk() {
        let scheme = darkMode ? "prefer-dark" : "prefer-light";
        _gtkProc.command = ["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", scheme];
        _gtkProc.running = true;
    }

    property var _gtkProc: Process {
        command: ["true"]
    }
```

- [ ] **Step 2: Remove hardcoded gsettings from hyprland.conf**

In `hypr/hyprland.conf`, find and remove this line:
```
exec-once = gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

- [ ] **Step 3: Add startup GTK sync**

The `onDarkModeChanged` handler added in Task 2 already calls `_syncGtk()`. On startup, the `darkMode` property loads from settings.toml which triggers `onDarkModeChanged`, so GTK will be synced on launch automatically.

Verify this works by restarting quickshell — GTK apps should follow the persisted mode.

- [ ] **Step 4: Commit**

```bash
git add quickshell/Config.qml hypr/hyprland.conf
git commit -m "feat: add GTK color-scheme sync on theme toggle"
```

---

### Task 4: Add Qt sync (_syncQt) and Latte color scheme

**Files:**
- Modify: `quickshell/Config.qml` (add _syncQt function)
- Create: `qt6ct/colors/catppuccin-latte.conf`

- [ ] **Step 1: Create the Catppuccin Latte qt6ct color scheme**

Create `qt6ct/colors/catppuccin-latte.conf`:

```ini
[ColorScheme]
active_colors=#ff4c4f69, #ffccd0da, #ffacb0be, #ffbcc0cc, #ffdce0e8, #ff9ca0b0, #ff4c4f69, #ff4c4f69, #ff4c4f69, #ffe6e9ef, #ffeff1f5, #ffdce0e8, #ff1e66f5, #ffdce0e8, #ff1e66f5, #ff8839ef, #ffccd0da, #ffccd0da, #ff4c4f69, #ff9ca0b0, #ff7287fd
disabled_colors=#ff9ca0b0, #ffccd0da, #ffacb0be, #ffbcc0cc, #ffdce0e8, #ff9ca0b0, #ff9ca0b0, #ff4c4f69, #ff9ca0b0, #ffe6e9ef, #ffeff1f5, #ffdce0e8, #ffbcc0cc, #ff9ca0b0, #ff1e66f5, #ff8839ef, #ffccd0da, #ffccd0da, #ff4c4f69, #ff9ca0b0, #ff7287fd
inactive_colors=#ff4c4f69, #ffccd0da, #ffacb0be, #ffbcc0cc, #ffdce0e8, #ff9ca0b0, #ff4c4f69, #ff4c4f69, #ff4c4f69, #ffe6e9ef, #ffeff1f5, #ffdce0e8, #ff1e66f5, #ffdce0e8, #ff1e66f5, #ff8839ef, #ffccd0da, #ffccd0da, #ff4c4f69, #ff9ca0b0, #ff7287fd
```

The color order in qt6ct ColorScheme is: WindowText, Button, Light, Midlight, Dark, Mid, Text, BrightText, ButtonText, Base, Window, Shadow, Highlight, HighlightedText, Link, LinkVisited, AlternateBase, ToolTipBase, ToolTipText, PlaceholderText, Accent.

- [ ] **Step 2: Add _syncQt function to Config.qml**

Add after the GTK sync section:

```qml
    // ===== Qt Sync =====

    property var _qtSyncTimer: Timer {
        interval: 100
        onTriggered: config._doSyncQt()
    }

    function _syncQt() { _qtSyncTimer.restart(); }

    function _doSyncQt() {
        let kvTheme = darkMode ? "catppuccin-mocha-lavender" : "catppuccin-latte-lavender";
        let qtColorFile = darkMode ? "catppuccin-mocha.conf" : "catppuccin-latte.conf";
        let kvConf = "[General]\ntheme=" + kvTheme + "\n";
        let qtConfPath = _homeDir + "/.config/qt6ct/qt6ct.conf";
        let kvConfPath = _homeDir + "/.config/Kvantum/kvantum.kvconfig";
        let qtColorPath = _homeDir + "/jimdots/qt6ct/colors/" + qtColorFile;

        // Write Kvantum config
        _qtKvWriteProc.command = ["bash", "-c", "echo '" + kvConf + "' > " + kvConfPath];
        _qtKvWriteProc.running = true;

        // Update qt6ct color_scheme_path using sed
        _qtCtWriteProc.command = ["bash", "-c",
            "sed -i 's|color_scheme_path=.*|color_scheme_path=" + qtColorPath + "|' " + qtConfPath];
        _qtCtWriteProc.running = true;
    }

    property var _qtKvWriteProc: Process { command: ["true"] }
    property var _qtCtWriteProc: Process { command: ["true"] }
```

- [ ] **Step 3: Test manually**

1. Toggle dark mode
2. Check `~/.config/Kvantum/kvantum.kvconfig` — should show `theme=catppuccin-latte-lavender` in light mode
3. Check `~/.config/qt6ct/qt6ct.conf` — should point to `catppuccin-latte.conf` in light mode
4. Open a Qt app (e.g., dolphin) to verify it picks up the new theme on next launch

- [ ] **Step 4: Commit**

```bash
git add quickshell/Config.qml qt6ct/colors/catppuccin-latte.conf
git commit -m "feat: add Qt/Kvantum theme sync on dark mode toggle"
```

---

### Task 9: Add IPC handler and keybind

**Files:**
- Modify: `quickshell/shell.qml` (add IPC handler)
- Modify: `hypr/hyprland.conf` (add keybind)

- [ ] **Step 1: Add IPC handler to shell.qml**

In `quickshell/shell.qml`, add an IPC handler inside the `ShellRoot` block, after the `Component.onCompleted` block (after line 34):

```qml
    IpcHandler {
        target: "theme"
        function toggle(): void {
            Config.toggleDarkMode();
        }
    }
```

Also add the import for IpcHandler if not already present. Check the existing imports — `Quickshell` module provides `IpcHandler`, which is already imported.

- [ ] **Step 2: Add keybind to hyprland.conf**

In `hypr/hyprland.conf`, add after the `bind = $mainMod, U, exec, quickshell msg quill-showcase toggle` line (around line 288):

```
bind = $mainMod SHIFT, T, exec, quickshell msg theme toggle
```

- [ ] **Step 3: Test manually**

1. Reload hyprland config: `hyprctl reload`
2. Press Super+Shift+T — verify all apps toggle between light and dark
3. Press again — verify they toggle back
4. Check `quickshell/settings.toml` — verify `darkMode` persists correctly

- [ ] **Step 4: Commit**

```bash
git add quickshell/shell.qml hypr/hyprland.conf
git commit -m "feat: add Super+Shift+T keybind and IPC for theme toggle"
```

---

### Task 10: Add dark mode toggle to AppearancePage

**Files:**
- Modify: `quickshell/settings/AppearancePage.qml:1-16` (add toggle at top)

- [ ] **Step 1: Add dark mode toggle to top of AppearancePage**

In `quickshell/settings/AppearancePage.qml`, add a toggle at the very beginning of the `ColumnLayout`, before the "Theme Presets" text (before line 10):

```qml
    // Dark Mode Toggle
    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        spacing: 12

        Text {
            text: "Dark Mode"
            color: Config.text
            font.pixelSize: 14; font.family: Config.fontFamily; font.bold: true
        }

        Item { Layout.fillWidth: true }

        ToggleSetting {
            label: ""
            section: "appearance"
            key: "darkMode"
            value: Config.darkMode
            onValueChanged: {
                if (value !== Config.darkMode)
                    Config.toggleDarkMode();
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Config.surface1
        Layout.bottomMargin: 8
    }
```

- [ ] **Step 2: Test manually**

1. Open quickshell settings (Super+,)
2. Navigate to Appearance page
3. Verify the dark mode toggle appears at the top
4. Flip it — verify everything switches to light mode
5. Flip back — verify everything returns to dark mode
6. Verify the toggle state persists after closing and reopening settings

- [ ] **Step 3: Commit**

```bash
git add quickshell/settings/AppearancePage.qml
git commit -m "feat: add dark mode toggle to AppearancePage settings UI"
```

---

### Task 11: End-to-end verification

**Files:** None (testing only)

- [ ] **Step 1: Verify keybind toggle**

Press `Super+Shift+T` and check each app:
- Quickshell bar/panels switch to light colors
- Kitty terminal shows readable text with Latte colors (dark text on light background)
- Hyprland borders update
- GTK apps (e.g., nautilus/dolphin if GTK) follow light theme

- [ ] **Step 2: Verify settings toggle**

Open settings (Super+,), go to Appearance, flip the dark mode toggle. Verify the same results as step 1.

- [ ] **Step 3: Verify persistence**

1. Toggle to light mode
2. Kill and restart quickshell: `quickshell &`
3. Verify it starts in light mode
4. Verify GTK apps are still in prefer-light mode
5. Verify kitty theme file still has Latte colors

- [ ] **Step 4: Verify toggle back to dark**

Press `Super+Shift+T` again. All apps should return to Mocha dark theme. Kitty text should be readable (light text on dark background).
