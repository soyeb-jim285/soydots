# Quill Component Migration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace hand-rolled QML primitives across the shell UI with Quill library components.

**Architecture:** Extend 2 Quill components (TextField, Slider) with missing properties needed by the shell, then swap hand-rolled code for Quill components file-by-file. Rewrite the settings wrappers (ToggleSetting, SliderSetting) to delegate to Quill internally.

**Tech Stack:** QML/Qt Quick, Quill component library (`quickshell/quill/`)

---

## Compatibility Notes

**What maps cleanly to Quill:**
- Toggle → BT power toggle, ToggleSetting wrapper
- Slider → SliderSetting wrapper, font size sliders
- TextField → search boxes, password input, text inputs (after extension)
- Separator → all `Rectangle { height: 1; color: ... }` dividers
- Badge → notification unread badge

**What needs Quill extension first:**
- TextField needs: `focus` alias, `echoMode` property, `Keys` signal forwarding
- Slider needs: `trackColor` property (volume uses red when muted, brightness uses yellow)

**What stays hand-rolled (too custom for Quill):**
- Quick settings grid buttons (toggle state with per-button custom colors + Lucide icons)
- Icon buttons (Quill.IconButton uses Nerd Font glyphs, shell uses Lucide SVG Shape components)
- Calendar nav buttons, connect/disconnect buttons, clear-all button (all use Lucide)

---

### Task 1: Extend Quill.TextField with focus, echoMode, and key forwarding

**Files:**
- Modify: `quickshell/quill/components/TextField.qml`

- [ ] **Step 1: Add focus alias, echoMode, and key signals**

Add these properties/aliases to the root Rectangle in `TextField.qml`:

```qml
// After existing properties:
property alias focus: input.focus
property alias activeFocus: input.activeFocus
property int echoMode: TextInput.Normal
property alias inputItem: input
```

Set `echoMode` on the TextInput:

```qml
TextInput {
    id: input
    // ... existing properties ...
    echoMode: root.echoMode
}
```

This lets callers do `focus: root.visible`, `echoMode: TextInput.Password`, and attach `Keys.forwardTo: [textField.inputItem]`.

- [ ] **Step 2: Verify showcase still works**

Run quickshell, open Showcase (Super+U), navigate to Inputs section. TextField demos should render unchanged.

- [ ] **Step 3: Commit**

```bash
git add quickshell/quill/components/TextField.qml
git commit -m "feat(quill): extend TextField with focus, echoMode, and input alias"
```

---

### Task 2: Extend Quill.Slider with trackColor property

**Files:**
- Modify: `quickshell/quill/components/Slider.qml`

- [ ] **Step 1: Add trackColor property**

Add a `trackColor` property defaulting to `Theme.primary`:

```qml
property color trackColor: Theme.primary
```

Replace the three hardcoded `Theme.primary` references in the track fill and thumb:

```qml
// Fill bar — change Theme.primary → root.trackColor
color: root.trackColor

// Thumb — change Theme.primary → root.trackColor, Theme.secondary stays for pressed state
color: sliderMouse.pressed ? Qt.lighter(root.trackColor, 1.2) : root.trackColor
```

- [ ] **Step 2: Verify showcase still works**

Showcase Slider demos should look identical (trackColor defaults to Theme.primary = blue).

- [ ] **Step 3: Commit**

```bash
git add quickshell/quill/components/Slider.qml
git commit -m "feat(quill): add trackColor property to Slider"
```

---

### Task 3: Rewrite ToggleSetting to wrap Quill.Toggle

**Files:**
- Modify: `quickshell/settings/ToggleSetting.qml`

- [ ] **Step 1: Replace implementation with Quill.Toggle**

```qml
import QtQuick
import QtQuick.Layouts
import ".."
import "../quill" as Quill

Quill.Toggle {
    id: root
    Layout.fillWidth: true

    property string section: ""
    property string key: ""
    property bool value: false

    checked: value
    label: ""

    onToggled: (val) => Config.set(root.section, root.key, val)
}
```

Note: The `label` property is inherited from Quill.Toggle. Callers already set it as `label: "..."`.

- [ ] **Step 2: Test in Settings panel**

Open Settings (Super+U from notif center or keybind), go to Appearance page. The "Enable Transparency" toggle should look and work identically.

- [ ] **Step 3: Commit**

```bash
git add quickshell/settings/ToggleSetting.qml
git commit -m "refactor(settings): rewrite ToggleSetting to wrap Quill.Toggle"
```

---

### Task 4: Rewrite SliderSetting to wrap Quill.Slider

**Files:**
- Modify: `quickshell/settings/SliderSetting.qml`

- [ ] **Step 1: Replace implementation with Quill.Slider**

```qml
import QtQuick
import QtQuick.Layouts
import ".."
import "../quill" as Quill

Quill.Slider {
    id: root
    Layout.fillWidth: true

    property string section: ""
    property string key: ""

    showValue: true

    onMoved: (val) => Config.set(root.section, root.key, val)
}
```

Callers already set `label`, `value`, `from`, `to`, `decimals`, `stepSize` — all of which are inherited from Quill.Slider.

- [ ] **Step 2: Test in Settings panel**

Open Appearance page. "Global Opacity" and per-component opacity sliders should look and function identically.

- [ ] **Step 3: Commit**

```bash
git add quickshell/settings/SliderSetting.qml
git commit -m "refactor(settings): rewrite SliderSetting to wrap Quill.Slider"
```

---

### Task 5: AppearancePage — Replace inline font size sliders with SliderSetting

**Files:**
- Modify: `quickshell/settings/AppearancePage.qml:315-365`

- [ ] **Step 1: Replace three inline slider blocks with SliderSetting**

Replace lines 316-331 (Small Font Size inline slider):
```qml
SliderSetting {
    label: "Small Font Size"; section: "appearance"; key: "fontSizeSmall"
    value: Config.fontSizeSmall; from: 6; to: 26; stepSize: 1
}
```

Replace lines 333-348 (Regular Font Size inline slider):
```qml
SliderSetting {
    label: "Regular Font Size"; section: "appearance"; key: "fontSize"
    value: Config.fontSize; from: 6; to: 26; stepSize: 1
}
```

Replace lines 350-365 (Icon Font Size inline slider):
```qml
SliderSetting {
    label: "Icon Font Size"; section: "appearance"; key: "fontSizeIcon"
    value: Config.fontSizeIcon; from: 6; to: 26; stepSize: 1
}
```

- [ ] **Step 2: Test in Settings → Appearance**

Font size sliders should work, dragging should update sizes in real time.

- [ ] **Step 3: Commit**

```bash
git add quickshell/settings/AppearancePage.qml
git commit -m "refactor(settings): replace inline font sliders with SliderSetting"
```

---

### Task 6: AppearancePage — Replace text inputs with Quill.TextField

**Files:**
- Modify: `quickshell/settings/AppearancePage.qml`

- [ ] **Step 1: Add Quill import**

Add to top of file:
```qml
import "../quill" as Quill
```

- [ ] **Step 2: Replace font family input (lines 288-297)**

Replace the hand-rolled Rectangle+TextInput:

```qml
Quill.TextField {
    Layout.fillWidth: true
    variant: "filled"
    text: Config.fontFamily
    placeholder: "Font family..."
    onSubmitted: (val) => Config.set("appearance", "fontFamily", val)
}
```

- [ ] **Step 3: Replace icon font input (lines 303-312)**

```qml
Quill.TextField {
    Layout.fillWidth: true
    variant: "filled"
    text: Config.iconFont
    placeholder: "Icon font..."
    onSubmitted: (val) => Config.set("appearance", "iconFont", val)
}
```

- [ ] **Step 4: Replace hex color editor input (lines 242-261)**

```qml
Quill.TextField {
    id: hexInput
    property string colorKey: ""
    Layout.preferredWidth: 120
    variant: "default"
    placeholder: "#hexcolor"
    onSubmitted: (val) => {
        if (colorKey !== "" && val.match(/^#[0-9a-fA-F]{6}$/))
            Config.set("appearance", colorKey, val.toLowerCase());
    }
}
```

- [ ] **Step 5: Test in Settings → Appearance**

Font family, icon font, and hex color inputs should accept text, submit on Enter.

- [ ] **Step 6: Commit**

```bash
git add quickshell/settings/AppearancePage.qml
git commit -m "refactor(settings): replace hand-rolled text inputs with Quill.TextField"
```

---

### Task 7: NotificationCenter — Replace sliders with Quill.Slider

**Files:**
- Modify: `quickshell/NotificationCenter.qml`

- [ ] **Step 1: Add Quill import**

Add after existing imports:
```qml
import "quill" as Quill
```

- [ ] **Step 2: Replace volume slider (lines 558-594)**

Replace the hand-rolled Item with track/fill/thumb/MouseArea:

```qml
Quill.Slider {
    Layout.fillWidth: true
    value: Math.round(root.volume * 100)
    from: 0; to: 100; stepSize: 1
    trackColor: root.muted ? Theme.red : Theme.blue
    onMoved: (val) => {
        if (root.sink?.audio)
            root.sink.audio.volume = val / 100;
    }
}
```

Keep the volume label RowLayout above it (lines 522-555) unchanged — it has the mute toggle icon and percentage text.

- [ ] **Step 3: Replace brightness slider (lines 621-660)**

```qml
Quill.Slider {
    Layout.fillWidth: true
    value: Math.round(root.brightness * 100)
    from: 0; to: 100; stepSize: 1
    trackColor: Theme.yellow
    onMoved: (val) => {
        root.brightness = val / 100;
        brightnessSetProc.pct = Math.round(val);
        brightnessSetProc.running = true;
    }
}
```

Keep the brightness label RowLayout above it (lines 602-618) unchanged.

- [ ] **Step 4: Replace separator line (line 664)**

Replace `Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.surface0 }` with:

```qml
Quill.Separator { Layout.fillWidth: true }
```

- [ ] **Step 5: Test notification center**

Open notification center. Volume slider should be blue (red when muted), brightness yellow. Dragging should adjust levels. Separator should look identical.

- [ ] **Step 6: Commit**

```bash
git add quickshell/NotificationCenter.qml
git commit -m "refactor(notifcenter): replace hand-rolled sliders and separator with Quill components"
```

---

### Task 8: StatusBar — Replace BT toggle and separators with Quill components

**Files:**
- Modify: `quickshell/StatusBar.qml`

- [ ] **Step 1: Add Quill import**

Add after existing imports:
```qml
import "quill" as Quill
```

- [ ] **Step 2: Replace BT power toggle (lines 847-868)**

Replace the hand-rolled Rectangle+Rectangle+MouseArea toggle:

```qml
Quill.Toggle {
    checked: root.btPowered
    onToggled: (val) => {
        if (root.btAdapter)
            root.btAdapter.enabled = val;
    }
}
```

- [ ] **Step 3: Replace WiFi panel separator (line 560)**

Replace `Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface1 }` with:

```qml
Quill.Separator { Layout.fillWidth: true }
```

- [ ] **Step 4: Replace BT panel separator (line 871)**

Same replacement:

```qml
Quill.Separator { Layout.fillWidth: true }
```

- [ ] **Step 5: Replace WiFi password separator (line 717)**

Same replacement:

```qml
Quill.Separator { Layout.fillWidth: true }
```

- [ ] **Step 6: Replace WiFi password input (lines 721-731)**

Replace the hand-rolled Rectangle+TextInput with:

```qml
Quill.TextField {
    id: wifiPassInput
    Layout.fillWidth: true
    variant: "filled"
    placeholder: "Password..."
    echoMode: TextInput.Password
    onSubmitted: root.submitWifiPassword()
}
```

Update `submitWifiPassword()` (line 141-148) — it references `wifiPassInput.text` which still works since Quill.TextField has a `text` property. But the `wifiPassInput.text = ""` clear also works via the alias.

Also update `focusTimer` (line 167): `wifiPassInput.forceActiveFocus()` — need to change to `wifiPassInput.inputItem.forceActiveFocus()` since focus goes to the inner TextInput.

- [ ] **Step 7: Test StatusBar panels**

Open WiFi panel (hover network icon). Password prompt should work. Open BT panel, toggle should flip power on/off. Separators should render identically.

- [ ] **Step 8: Commit**

```bash
git add quickshell/StatusBar.qml
git commit -m "refactor(statusbar): replace BT toggle, separators, and password input with Quill components"
```

---

### Task 9: AppLauncher — Replace search box with Quill.TextField

**Files:**
- Modify: `quickshell/AppLauncher.qml`

- [ ] **Step 1: Add Quill import**

```qml
import "quill" as Quill
```

- [ ] **Step 2: Replace search box (lines 160-197)**

Replace the Rectangle+TextInput+placeholder with:

```qml
Quill.TextField {
    id: searchBox
    Layout.fillWidth: true
    variant: "filled"
    placeholder: "Search apps..."
    focus: root.visible
    onTextEdited: (val) => root.searchText = val

    // Key forwarding — attach to the inner input
    Component.onCompleted: {
        inputItem.Keys.escapePressed.connect(() => root.toggle());
        inputItem.Keys.downPressed.connect(() => resultsView.forceActiveFocus());
        inputItem.Keys.returnPressed.connect(() => {
            if (root.filteredApps.length > 0) root.launch(root.filteredApps[0]);
        });
    }
}
```

Update references: `searchInput.forceActiveFocus()` → `searchBox.inputItem.forceActiveFocus()`, `searchInput.text` → `searchBox.text`.

In the ListView Keys.onPressed handler (line 284-289), change `searchInput.forceActiveFocus()` and `searchInput.text += event.text` to use `searchBox.inputItem`.

- [ ] **Step 3: Test app launcher**

Open launcher. Type to search, press Escape to close, Down arrow to navigate list, Enter to launch. All should work.

- [ ] **Step 4: Commit**

```bash
git add quickshell/AppLauncher.qml
git commit -m "refactor(launcher): replace search box with Quill.TextField"
```

---

### Task 10: ClipboardHistory — Replace search box with Quill.TextField

**Files:**
- Modify: `quickshell/ClipboardHistory.qml`

- [ ] **Step 1: Add Quill import**

```qml
import "quill" as Quill
```

- [ ] **Step 2: Replace search box (lines 166-203)**

```qml
Quill.TextField {
    id: searchBox
    Layout.fillWidth: true
    variant: "filled"
    placeholder: "Search clipboard..."
    focus: root.visible
    onTextEdited: (val) => root.searchText = val

    Component.onCompleted: {
        inputItem.Keys.escapePressed.connect(() => root.toggle());
        inputItem.Keys.downPressed.connect(() => clipList.forceActiveFocus());
        inputItem.Keys.returnPressed.connect(() => {
            if (root.filteredItems.length > 0) root.paste(root.filteredItems[0]);
        });
    }
}
```

Update references: `searchInput.forceActiveFocus()` → `searchBox.inputItem.forceActiveFocus()`, `searchInput.text += event.text` → `searchBox.inputItem.text += event.text`.

- [ ] **Step 3: Test clipboard history**

Open clipboard panel. Type to filter, navigate, paste. All keyboard shortcuts should work.

- [ ] **Step 4: Commit**

```bash
git add quickshell/ClipboardHistory.qml
git commit -m "refactor(clipboard): replace search box with Quill.TextField"
```

---

### Task 11: NotificationBell — Replace unread badge with Quill.Badge

**Files:**
- Modify: `quickshell/bar/NotificationBell.qml`

- [ ] **Step 1: Add Quill import**

```qml
import "../quill" as Quill
```

- [ ] **Step 2: Replace hand-rolled badge (lines 44-65)**

Replace the Rectangle+Text badge:

```qml
Quill.Badge {
    visible: root.unreadCount > 0
    text: root.unreadCount > 99 ? "99+" : "" + root.unreadCount
    variant: "error"
    anchors.top: bellIcon.top
    anchors.right: bellIcon.right
    anchors.topMargin: -2
    anchors.rightMargin: -4
}
```

- [ ] **Step 3: Test notification bell**

Trigger a notification. Badge should appear with count, colored red.

- [ ] **Step 4: Commit**

```bash
git add quickshell/bar/NotificationBell.qml
git commit -m "refactor(bar): replace notification badge with Quill.Badge"
```

---

### Task 12: Settings — Replace sidebar separator with Quill.Separator

**Files:**
- Modify: `quickshell/Settings.qml`

- [ ] **Step 1: Add Quill import**

```qml
import "quill" as Quill
```

- [ ] **Step 2: Replace separator (lines 256-259)**

Replace `Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 1; color: Config.surface0 }` with:

```qml
Quill.Separator { orientation: Qt.Vertical; Layout.fillHeight: true }
```

- [ ] **Step 3: Test Settings panel**

Open Settings. Vertical separator between sidebar and content should render identically.

- [ ] **Step 4: Commit**

```bash
git add quickshell/Settings.qml
git commit -m "refactor(settings): replace sidebar separator with Quill.Separator"
```
