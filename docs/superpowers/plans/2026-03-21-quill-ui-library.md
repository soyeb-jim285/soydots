# Quill UI Library Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reusable QML component library (21 components) for Quickshell with a live showcase panel.

**Architecture:** Top-level `quill/` directory with `qmldir` module manifest, singleton Theme with Catppuccin Mocha defaults, components in `quill/components/`, and showcase panel in `quill/showcase/`. Components use raw QtQuick (no Qt Quick Controls). Showcase is a standalone PanelWindow with sidebar navigation.

**Tech Stack:** QML/QtQuick, Quickshell APIs (PanelWindow, WlrLayershell, Scope, LazyLoader, IpcHandler, GlobalShortcut)

**Spec:** `docs/superpowers/specs/2026-03-21-quill-ui-library-design.md`

**Note on testing:** QML component libraries don't have a traditional unit test framework. Each task includes visual verification by running `quickshell` and opening the Showcase panel. The showcase itself serves as a living test suite — every component is interactive and demonstrates all its variants/states.

---

## File Structure

```
quill/
├── qmldir                          # Module manifest
├── Theme.qml                       # Theme singleton
├── Showcase.qml                    # Showcase panel (PanelWindow)
├── components/
│   ├── Label.qml                   # Styled text with variants
│   ├── Icon.qml                    # Nerd font icon wrapper
│   ├── Button.qml                  # Button with variants/sizes
│   ├── IconButton.qml              # Circular icon button
│   ├── Toggle.qml                  # Animated switch
│   ├── Checkbox.qml                # Checkbox with label
│   ├── Slider.qml                  # Range input
│   ├── TextField.qml               # Text input
│   ├── RadioButton.qml             # Radio option
│   ├── RadioGroup.qml              # Exclusive selection container
│   ├── Dropdown.qml                # Select from list
│   ├── Card.qml                    # Container with optional header
│   ├── Separator.qml               # Horizontal/vertical line
│   ├── Tabs.qml                    # Tab bar with underline
│   ├── Collapsible.qml             # Expand/collapse section
│   ├── ScrollableList.qml          # Styled ListView
│   ├── Tooltip.qml                 # Hover tooltip (child pattern)
│   ├── Badge.qml                   # Pill label/dot
│   ├── ProgressBar.qml             # Determinate/indeterminate
│   ├── Spinner.qml                 # Loading indicator
│   └── Avatar.qml                  # Image/initials circle
└── showcase/
    ├── InputsSection.qml           # Button, Toggle, Slider, TextField, etc.
    ├── LayoutSection.qml           # Card, Separator, Tabs, Collapsible, etc.
    ├── FeedbackSection.qml         # Tooltip, Badge, ProgressBar, Spinner
    └── DisplaySection.qml          # Icon, Label, Avatar
```

Additionally modified:
- `quickshell/shell.qml` — register Showcase via LazyLoader

---

### Task 1: Foundation — Directory Structure, qmldir, Theme

**Files:**
- Create: `quill/qmldir`
- Create: `quill/Theme.qml`
- Create: `quill/components/` (directory)
- Create: `quill/showcase/` (directory)

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p quill/components quill/showcase
```

- [ ] **Step 2: Create qmldir module manifest**

Create `quill/qmldir`:
```
module Quill
singleton Theme 1.0 Theme.qml
Button 1.0 components/Button.qml
IconButton 1.0 components/IconButton.qml
Toggle 1.0 components/Toggle.qml
Slider 1.0 components/Slider.qml
TextField 1.0 components/TextField.qml
Dropdown 1.0 components/Dropdown.qml
Checkbox 1.0 components/Checkbox.qml
RadioButton 1.0 components/RadioButton.qml
RadioGroup 1.0 components/RadioGroup.qml
Card 1.0 components/Card.qml
Separator 1.0 components/Separator.qml
Tabs 1.0 components/Tabs.qml
Collapsible 1.0 components/Collapsible.qml
ScrollableList 1.0 components/ScrollableList.qml
Tooltip 1.0 components/Tooltip.qml
Badge 1.0 components/Badge.qml
ProgressBar 1.0 components/ProgressBar.qml
Spinner 1.0 components/Spinner.qml
Icon 1.0 components/Icon.qml
Avatar 1.0 components/Avatar.qml
Label 1.0 components/Label.qml
```

- [ ] **Step 3: Create Theme.qml singleton**

Create `quill/Theme.qml` — the full theme contract with Catppuccin Mocha defaults:

```qml
pragma Singleton

import QtQuick

QtObject {
    id: root

    // Colors — Surface hierarchy
    property color background: "#1e1e2e"
    property color backgroundAlt: "#181825"
    property color backgroundDeep: "#11111b"
    property color surface0: "#313244"
    property color surface1: "#45475a"
    property color surface2: "#585b70"
    property color overlay0: "#6c7086"
    property color overlay1: "#7f849c"

    // Colors — Text
    property color textPrimary: "#cdd6f4"
    property color textSecondary: "#bac2de"
    property color textTertiary: "#a6adc8"

    // Colors — Semantic
    property color primary: "#89b4fa"
    property color secondary: "#b4befe"
    property color accent: "#cba6f7"
    property color success: "#a6e3a1"
    property color warning: "#f9e2af"
    property color error: "#f38ba8"
    property color info: "#89dceb"

    // Catppuccin aliases (readonly bindings for migration ease)
    readonly property color blue: primary
    readonly property color lavender: secondary
    readonly property color mauve: accent
    readonly property color green: success
    readonly property color yellow: warning
    readonly property color red: error
    readonly property color teal: info
    readonly property color base: background
    readonly property color mantle: backgroundAlt
    readonly property color crust: backgroundDeep
    readonly property color text: textPrimary
    readonly property color subtext1: textSecondary
    readonly property color subtext0: textTertiary

    // Typography
    property string fontFamily: "Maple Mono"
    property string iconFont: "Maple Mono NF"
    property int fontSizeSmall: 11
    property int fontSize: 13
    property int fontSizeLarge: 16
    property int fontSizeHeading: 20

    // Spacing
    property int spacingXs: 4
    property int spacingSm: 6
    property int spacing: 8
    property int spacingMd: 12
    property int spacingLg: 16
    property int spacingXl: 24

    // Radii
    property int radius: 8
    property int radiusSm: 4
    property int radiusLg: 12
    property int radiusFull: 9999

    // Animation
    property int animDuration: 200
    property int animDurationFast: 100
    property int animDurationSlow: 350

    // Transparency
    property bool transparencyEnabled: false
    property real transparencyLevel: 0.85

    function bg(color, opacity) {
        if (!transparencyEnabled) return color;
        return Qt.rgba(color.r, color.g, color.b, opacity !== undefined ? opacity : transparencyLevel);
    }
}
```

**Note on aliases:** These use `readonly property color` with binding expressions (e.g., `readonly property color blue: primary`). QML's binding system ensures that when `primary` changes, `blue` updates reactively. The `readonly` keyword prevents external code from writing to `blue` directly — changes must go through `primary`.

- [ ] **Step 4: Commit**

```bash
git add quill/
git commit -m "feat(quill): add foundation — qmldir, Theme singleton, directory structure"
```

---

### Task 2: Label + Icon (Display Primitives)

These are used by nearly every other component, so they come first.

**Files:**
- Create: `quill/components/Label.qml`
- Create: `quill/components/Icon.qml`

- [ ] **Step 1: Create Label.qml**

Create `quill/components/Label.qml`:

```qml
import QtQuick
import ".."

Text {
    id: root

    property string variant: "body" // "heading" | "body" | "caption" | "overline"

    color: Theme.textPrimary
    font.family: Theme.fontFamily
    font.pixelSize: {
        switch (variant) {
            case "heading": return Theme.fontSizeHeading;
            case "caption": return Theme.fontSizeSmall;
            case "overline": return Theme.fontSizeSmall;
            default: return Theme.fontSize;
        }
    }
    font.bold: variant === "heading"
    font.capitalization: variant === "overline" ? Font.AllUppercase : Font.MixedCase
    font.letterSpacing: variant === "overline" ? 1.5 : 0

    opacity: variant === "caption" || variant === "overline" ? 0.7 : 1.0
}
```

- [ ] **Step 2: Create Icon.qml**

Create `quill/components/Icon.qml`:

```qml
import QtQuick
import ".."

Text {
    id: root

    property string glyph: ""
    property string size: "medium" // "small" | "medium" | "large"

    text: glyph
    color: Theme.textPrimary
    font.family: Theme.iconFont
    font.pixelSize: {
        switch (size) {
            case "small": return Theme.fontSizeSmall;
            case "large": return Theme.fontSizeLarge;
            default: return Theme.fontSize;
        }
    }
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
```

- [ ] **Step 3: Commit**

```bash
git add quill/components/Label.qml quill/components/Icon.qml
git commit -m "feat(quill): add Label and Icon display primitives"
```

---

### Task 3: Showcase Scaffold

Build the panel shell so components can be visually verified as they're built.

**Files:**
- Create: `quill/Showcase.qml`
- Create: `quill/showcase/InputsSection.qml` (placeholder)
- Create: `quill/showcase/LayoutSection.qml` (placeholder)
- Create: `quill/showcase/FeedbackSection.qml` (placeholder)
- Create: `quill/showcase/DisplaySection.qml` (placeholder)
- Modify: `quickshell/shell.qml` — add Showcase

- [ ] **Step 1: Create Showcase.qml**

Model after `quickshell/Settings.qml`. Create `quill/Showcase.qml`:

```qml
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "showcase"

Scope {
    id: root

    property bool visible: false
    property int activePage: 0

    function toggle() {
        root.visible = !root.visible;
    }

    IpcHandler {
        target: "quill-showcase"
        function toggle(): void {
            root.toggle();
        }
    }

    GlobalShortcut {
        name: "quillShowcaseToggle"
        description: "Toggle Quill component showcase"
        onPressed: root.toggle()
    }

    property var pages: [
        { name: "Inputs", icon: "\uf11c" },
        { name: "Layout", icon: "\uf009" },
        { name: "Feedback", icon: "\uf0a2" },
        { name: "Display", icon: "\uf06e" }
    ]

    LazyLoader {
        active: root.visible

        PanelWindow {
            id: window

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "quill-showcase"

            anchors {
                top: true; left: true; right: true; bottom: true
            }

            color: "transparent"

            // Backdrop
            Rectangle {
                anchors.fill: parent
                property real fadeIn: 0
                color: Qt.rgba(0, 0, 0, fadeIn * 0.25)

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.toggle()
                }

                NumberAnimation on fadeIn {
                    from: 0; to: 1
                    duration: Theme.animDuration
                    easing.type: Easing.OutCubic
                    running: true
                }
            }

            // Main panel
            Rectangle {
                id: panel
                anchors.centerIn: parent
                width: 900
                height: 650
                color: Theme.bg(Theme.backgroundAlt, Theme.transparencyLevel)
                radius: 20
                border.color: Theme.surface1
                border.width: 1

                scale: 0.92; opacity: 0

                NumberAnimation on scale {
                    from: 0.92; to: 1.0; duration: 250
                    easing.type: Easing.OutCubic; running: true
                }
                NumberAnimation on opacity {
                    from: 0; to: 1.0; duration: 200
                    easing.type: Easing.OutCubic; running: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: (event) => event.accepted = true
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Sidebar
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 180
                        color: Theme.backgroundDeep
                        radius: 20

                        // Cover right-side radius
                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 20
                            color: parent.color
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            anchors.topMargin: 16
                            spacing: 2

                            Text {
                                text: "\uf12e  Quill"
                                color: Theme.textPrimary
                                font.pixelSize: 16
                                font.family: Theme.fontFamily
                                font.bold: true
                                Layout.leftMargin: 12
                                Layout.bottomMargin: 12
                            }

                            Repeater {
                                model: root.pages

                                Rectangle {
                                    required property var modelData
                                    required property int index

                                    Layout.fillWidth: true
                                    height: 36; radius: 8
                                    color: root.activePage === index
                                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                        : navMouse.containsMouse ? Theme.surface0 : "transparent"
                                    Behavior on color { ColorAnimation { duration: 80 } }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        spacing: 10

                                        Text {
                                            text: modelData.icon
                                            color: root.activePage === index ? Theme.primary : Theme.overlay0
                                            font.pixelSize: 14; font.family: Theme.iconFont
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: modelData.name
                                            color: root.activePage === index ? Theme.primary : Theme.textPrimary
                                            font.pixelSize: 12; font.family: Theme.fontFamily
                                            font.bold: root.activePage === index
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: navMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.activePage = index
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // Separator
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: Theme.surface0
                    }

                    // Content area
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        RowLayout {
                            id: pageHeader
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 20

                            Text {
                                text: root.pages[root.activePage].name
                                color: Theme.textPrimary
                                font.pixelSize: 18
                                font.family: Theme.fontFamily
                                font.bold: true
                            }
                        }

                        Flickable {
                            anchors.top: pageHeader.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 20
                            anchors.topMargin: 12
                            contentHeight: pageLoader.item?.implicitHeight ?? 0
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Loader {
                                id: pageLoader
                                width: parent.width
                                source: {
                                    let names = ["InputsSection", "LayoutSection",
                                                 "FeedbackSection", "DisplaySection"];
                                    return "showcase/" + names[root.activePage] + ".qml";
                                }
                            }
                        }
                    }
                }

                Shortcut {
                    sequence: "Escape"
                    onActivated: root.toggle()
                }
            }
        }
    }
}
```

- [ ] **Step 2: Create placeholder showcase sections**

Create `quill/showcase/InputsSection.qml`:
```qml
import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: Theme.spacingLg

    Text {
        text: "Input components will appear here as they are built."
        color: Theme.textTertiary
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }
}
```

Create `quill/showcase/LayoutSection.qml`, `quill/showcase/FeedbackSection.qml`, `quill/showcase/DisplaySection.qml` with the same pattern (change the message text for each).

- [ ] **Step 3: Register Showcase in shell.qml**

Modify `quickshell/shell.qml` — add after the existing components inside `ShellRoot`:

```qml
import "../quill" as Quill
```

And inside ShellRoot, add:
```qml
Quill.Showcase {}
```

- [ ] **Step 4: Verify**

Run `quickshell`. Trigger the showcase via IPC (`quickshell ipc call quill-showcase toggle`) or the keybind. Confirm:
- Panel appears centered with backdrop
- Sidebar shows 4 categories with icons
- Clicking categories switches content
- Escape closes the panel

- [ ] **Step 5: Commit**

```bash
git add quill/Showcase.qml quill/showcase/ quickshell/shell.qml
git commit -m "feat(quill): add Showcase panel scaffold with sidebar navigation"
```

---

### Task 4: Button + IconButton

**Files:**
- Create: `quill/components/Button.qml`
- Create: `quill/components/IconButton.qml`
- Modify: `quill/showcase/InputsSection.qml`

- [ ] **Step 1: Create Button.qml**

Create `quill/components/Button.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property string variant: "primary"  // "primary" | "secondary" | "ghost" | "danger"
    property string size: "medium"      // "small" | "medium" | "large"
    property bool enabled: true

    signal clicked()

    // Size presets
    implicitWidth: contentRow.implicitWidth + (size === "small" ? 16 : size === "large" ? 32 : 24)
    implicitHeight: size === "small" ? 28 : size === "large" ? 40 : 34

    radius: Theme.radius
    color: {
        if (!enabled) return Theme.surface0;
        let base;
        switch (variant) {
            case "primary": base = Theme.primary; break;
            case "secondary": base = Theme.surface1; break;
            case "ghost": base = "transparent"; break;
            case "danger": base = Theme.error; break;
            default: base = Theme.primary;
        }
        if (mouse.pressed && enabled) return Qt.darker(base, 1.2);
        if (mouse.containsMouse && enabled) {
            if (variant === "ghost") return Theme.surface0;
            return Qt.lighter(base, 1.15);
        }
        return base;
    }
    opacity: enabled ? 1.0 : 0.5

    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: root.text && root.icon ? 6 : 0

        Text {
            visible: root.icon !== ""
            text: root.icon
            color: {
                if (root.variant === "ghost" || root.variant === "secondary")
                    return Theme.textPrimary;
                return Theme.backgroundDeep;
            }
            font.family: Theme.iconFont
            font.pixelSize: root.size === "small" ? 12 : root.size === "large" ? 16 : 14
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.text !== ""
            text: root.text
            color: {
                if (root.variant === "ghost" || root.variant === "secondary")
                    return Theme.textPrimary;
                return Theme.backgroundDeep;
            }
            font.family: Theme.fontFamily
            font.pixelSize: root.size === "small" ? 11 : root.size === "large" ? 15 : 13
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
```

- [ ] **Step 2: Create IconButton.qml**

Create `quill/components/IconButton.qml`:

```qml
import QtQuick
import ".."

Rectangle {
    id: root

    property string icon: ""
    property string tooltip: ""
    property string variant: "ghost"    // "primary" | "secondary" | "ghost" | "danger"
    property string size: "medium"      // "small" | "medium" | "large"
    property bool enabled: true

    signal clicked()

    implicitWidth: size === "small" ? 28 : size === "large" ? 40 : 34
    implicitHeight: implicitWidth
    radius: Theme.radiusFull

    color: {
        if (!enabled) return Theme.surface0;
        let base;
        switch (variant) {
            case "primary": base = Theme.primary; break;
            case "secondary": base = Theme.surface1; break;
            case "ghost": base = "transparent"; break;
            case "danger": base = Theme.error; break;
            default: base = "transparent";
        }
        if (mouse.pressed && enabled) return Qt.darker(base, 1.2);
        if (mouse.containsMouse && enabled) {
            if (variant === "ghost") return Theme.surface0;
            return Qt.lighter(base, 1.15);
        }
        return base;
    }
    opacity: enabled ? 1.0 : 0.5

    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: {
            if (root.variant === "ghost" || root.variant === "secondary")
                return Theme.textPrimary;
            return Theme.backgroundDeep;
        }
        font.family: Theme.iconFont
        font.pixelSize: root.size === "small" ? 12 : root.size === "large" ? 16 : 14
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabled) root.clicked()
    }

    // Internal tooltip
    Tooltip {
        target: root
        text: root.tooltip
        visible: root.tooltip !== "" && mouse.containsMouse
    }
}
```

**Note:** Tooltip component doesn't exist yet. This will show a warning but not crash. Tooltip is created in Task 13. For now, comment out the Tooltip block or skip it — it will be wired up when Tooltip is built.

- [ ] **Step 3: Update InputsSection with Button + IconButton demos**

Replace `quill/showcase/InputsSection.qml` with interactive demos showing all button variants and sizes. Include:
- Row of Button variants (primary, secondary, ghost, danger)
- Row of Button sizes (small, medium, large)
- Button with icon + text
- Row of IconButton variants
- Disabled state examples

Each group wrapped in a labeled section (Text heading + content).

- [ ] **Step 4: Verify**

Run quickshell, open showcase, check Inputs tab. Confirm buttons render, hover/press animations work, disabled state is dimmed.

- [ ] **Step 5: Commit**

```bash
git add quill/components/Button.qml quill/components/IconButton.qml quill/showcase/InputsSection.qml
git commit -m "feat(quill): add Button and IconButton components"
```

---

### Task 5: Toggle + Checkbox

**Files:**
- Create: `quill/components/Toggle.qml`
- Create: `quill/components/Checkbox.qml`
- Modify: `quill/showcase/InputsSection.qml`

- [ ] **Step 1: Create Toggle.qml**

Create `quill/components/Toggle.qml`. Model after `quickshell/settings/ToggleSetting.qml` but decouple from Config:

```qml
import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: root

    property bool checked: false
    property string label: ""
    property bool enabled: true

    signal toggled(bool value)

    spacing: Theme.spacingMd
    opacity: enabled ? 1.0 : 0.5

    Text {
        visible: root.label !== ""
        text: root.label
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        Layout.fillWidth: true
    }

    Rectangle {
        width: 40; height: 22; radius: 11
        color: root.checked ? Theme.primary : Theme.surface1
        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 18; height: 18; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 2 : 2
            color: Theme.textPrimary
            Behavior on x { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (!root.enabled) return;
                root.checked = !root.checked;
                root.toggled(root.checked);
            }
        }
    }
}
```

- [ ] **Step 2: Create Checkbox.qml**

Create `quill/components/Checkbox.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: root

    property bool checked: false
    property string label: ""
    property bool enabled: true

    signal toggled(bool value)

    spacing: Theme.spacing
    opacity: enabled ? 1.0 : 0.5

    Rectangle {
        width: 20; height: 20
        radius: Theme.radiusSm
        color: root.checked ? Theme.primary : "transparent"
        border.color: root.checked ? Theme.primary : Theme.surface2
        border.width: 2
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

        // Checkmark
        Text {
            anchors.centerIn: parent
            text: "\u{f00c}"
            color: Theme.backgroundDeep
            font.family: Theme.iconFont
            font.pixelSize: 12
            visible: root.checked
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (!root.enabled) return;
                root.checked = !root.checked;
                root.toggled(root.checked);
            }
        }
    }

    Text {
        visible: root.label !== ""
        text: root.label
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily

        MouseArea {
            anchors.fill: parent
            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (!root.enabled) return;
                root.checked = !root.checked;
                root.toggled(root.checked);
            }
        }
    }
}
```

- [ ] **Step 3: Add Toggle + Checkbox demos to InputsSection**

Add sections to `quill/showcase/InputsSection.qml`:
- Toggle on/off states with labels
- Toggle without label
- Disabled toggle
- Checkbox checked/unchecked with labels
- Disabled checkbox

- [ ] **Step 4: Verify and commit**

```bash
git add quill/components/Toggle.qml quill/components/Checkbox.qml quill/showcase/InputsSection.qml
git commit -m "feat(quill): add Toggle and Checkbox components"
```

---

### Task 6: Slider

**Files:**
- Create: `quill/components/Slider.qml`
- Modify: `quill/showcase/InputsSection.qml`

- [ ] **Step 1: Create Slider.qml**

Create `quill/components/Slider.qml`. Model after `quickshell/settings/SliderSetting.qml` but decouple from Config:

```qml
import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property string label: ""
    property bool showValue: false
    property int decimals: 0
    property bool enabled: true

    signal moved(real value)

    spacing: Theme.spacingMd
    opacity: enabled ? 1.0 : 0.5
    Layout.fillWidth: true

    Text {
        visible: root.label !== ""
        text: root.label
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
        Layout.preferredWidth: 140
    }

    Item {
        Layout.fillWidth: true
        height: 24

        property real ratio: Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from)))

        // Track background
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 4; radius: 2
            color: Theme.surface1
        }

        // Track fill
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * parent.ratio
            height: 4; radius: 2
            color: Theme.primary
        }

        // Thumb
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width * parent.ratio - 7
            width: 14; height: 14; radius: 7
            color: sliderMouse.pressed ? Theme.secondary : Theme.primary
            Behavior on color { ColorAnimation { duration: 80 } }
        }

        MouseArea {
            id: sliderMouse
            anchors.fill: parent
            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: (event) => { if (root.enabled) updateValue(event); }
            onPositionChanged: (event) => { if (pressed && root.enabled) updateValue(event); }

            function updateValue(event) {
                let r = Math.max(0, Math.min(1, event.x / width));
                let raw = root.from + r * (root.to - root.from);
                let step = root.stepSize;
                let val = Math.round(raw / step) * step;
                if (root.decimals > 0)
                    val = parseFloat(val.toFixed(root.decimals));
                root.value = val;
                root.moved(val);
            }
        }
    }

    Rectangle {
        visible: root.showValue
        width: 52; height: 24; radius: Theme.radiusSm
        color: Theme.surface0

        Text {
            anchors.centerIn: parent
            text: root.decimals > 0
                ? root.value.toFixed(root.decimals)
                : Math.round(root.value)
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
        }
    }
}
```

- [ ] **Step 2: Add Slider demo to InputsSection**

Add to `quill/showcase/InputsSection.qml`:
- Slider with label and showValue
- Slider with stepSize 10
- Slider with decimals
- Disabled slider

- [ ] **Step 3: Verify and commit**

```bash
git add quill/components/Slider.qml quill/showcase/InputsSection.qml
git commit -m "feat(quill): add Slider component"
```

---

### Task 7: TextField

**Files:**
- Create: `quill/components/TextField.qml`
- Modify: `quill/showcase/InputsSection.qml`

- [ ] **Step 1: Create TextField.qml**

Create `quill/components/TextField.qml`. Model after `quickshell/settings/TextSetting.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property string icon: ""
    property string variant: "default" // "default" | "filled"
    property bool enabled: true

    signal textEdited(string text)
    signal submitted(string text)

    implicitHeight: 34
    Layout.fillWidth: true
    radius: Theme.radius
    color: variant === "filled" ? Theme.surface0 : "transparent"
    border.color: input.activeFocus ? Theme.primary : Theme.surface1
    border.width: variant === "default" ? 1 : 0
    opacity: enabled ? 1.0 : 0.5

    Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

    Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing
        anchors.rightMargin: Theme.spacing
        spacing: Theme.spacing

        // Leading icon
        Text {
            visible: root.icon !== ""
            text: root.icon
            color: Theme.textTertiary
            font.family: Theme.iconFont
            font.pixelSize: Theme.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            width: parent.width - (root.icon !== "" ? Theme.fontSize + Theme.spacing : 0)
            height: parent.height

            TextInput {
                id: input
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                clip: true
                enabled: root.enabled
                onTextEdited: root.textEdited(text)
                onAccepted: root.submitted(text)
            }

            // Placeholder
            Text {
                visible: input.text === "" && !input.activeFocus
                text: root.placeholder
                color: Theme.textTertiary
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
```

- [ ] **Step 2: Add TextField demo to InputsSection**

Add to `quill/showcase/InputsSection.qml`:
- Default variant with placeholder
- Filled variant
- TextField with icon
- Disabled textfield

- [ ] **Step 3: Verify and commit**

```bash
git add quill/components/TextField.qml quill/showcase/InputsSection.qml
git commit -m "feat(quill): add TextField component"
```

---

### Task 8: RadioButton + RadioGroup

**Files:**
- Create: `quill/components/RadioButton.qml`
- Create: `quill/components/RadioGroup.qml`
- Modify: `quill/showcase/InputsSection.qml`

- [ ] **Step 1: Create RadioGroup.qml**

Create `quill/components/RadioGroup.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    id: root

    property string value: ""
    property bool enabled: true

    signal selected(string value)

    spacing: Theme.spacing
    opacity: enabled ? 1.0 : 0.5
}
```

- [ ] **Step 2: Create RadioButton.qml**

Create `quill/components/RadioButton.qml`. Uses a single MouseArea covering the entire row. Checks `parent.value` for RadioGroup coordination:

```qml
import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: root

    property string value: ""
    property string label: ""
    property bool checked: false
    property bool enabled: true

    signal toggled(bool value)

    // RadioGroup coordination: if parent has a `value` property, use it
    property bool _inGroup: parent && parent.value !== undefined
    property bool _isSelected: _inGroup ? parent.value === root.value : root.checked

    spacing: Theme.spacing
    opacity: enabled ? 1.0 : 0.5

    Rectangle {
        width: 20; height: 20
        radius: Theme.radiusFull
        color: "transparent"
        border.color: root._isSelected ? Theme.primary : Theme.surface2
        border.width: 2
        Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

        // Inner dot
        Rectangle {
            anchors.centerIn: parent
            width: 10; height: 10
            radius: Theme.radiusFull
            color: Theme.primary
            visible: root._isSelected
            scale: root._isSelected ? 1.0 : 0.0
            Behavior on scale { NumberAnimation { duration: Theme.animDurationFast; easing.type: Easing.OutCubic } }
        }
    }

    Text {
        visible: root.label !== ""
        text: root.label
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    // Single MouseArea covering entire row — avoids fragile parent chain issues
    MouseArea {
        anchors.fill: parent
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (!root.enabled) return;
            if (root._inGroup) {
                root.parent.value = root.value;
                root.parent.selected(root.value);
            } else {
                root.checked = !root.checked;
                root.toggled(root.checked);
            }
        }
    }
}
```

- [ ] **Step 3: Add RadioButton/RadioGroup demo to InputsSection**

Add to `quill/showcase/InputsSection.qml`:
- RadioGroup with 3 options, displaying selected value
- Standalone RadioButtons
- Disabled radio group

- [ ] **Step 4: Verify and commit**

```bash
git add quill/components/RadioButton.qml quill/components/RadioGroup.qml quill/showcase/InputsSection.qml
git commit -m "feat(quill): add RadioButton and RadioGroup components"
```

---

### Task 9: Dropdown

**Files:**
- Create: `quill/components/Dropdown.qml`
- Modify: `quill/showcase/InputsSection.qml`

- [ ] **Step 1: Create Dropdown.qml**

Create `quill/components/Dropdown.qml`. The dropdown list renders within the same component using absolute z-positioning:

```qml
import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    property var model: []
    property int currentIndex: 0
    property string label: ""
    property bool enabled: true

    signal selected(int index, string value)

    implicitHeight: 34
    implicitWidth: 200
    Layout.fillWidth: true
    z: dropdownOpen ? 100 : 0

    property bool dropdownOpen: false

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        height: 34
        spacing: Theme.spacingMd

        Text {
            visible: root.label !== ""
            text: root.label
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
            Layout.preferredWidth: 140
        }

        Rectangle {
            Layout.fillWidth: true
            height: 34
            radius: Theme.radius
            color: Theme.surface0
            border.color: root.dropdownOpen ? Theme.primary : Theme.surface1
            border.width: 1
            opacity: root.enabled ? 1.0 : 0.5

            Behavior on border.color { ColorAnimation { duration: Theme.animDurationFast } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacing
                anchors.rightMargin: Theme.spacing

                Text {
                    text: root.model[root.currentIndex] ?? ""
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - chevron.width
                    elide: Text.ElideRight
                }

                Text {
                    id: chevron
                    text: root.dropdownOpen ? "\uf077" : "\uf078"
                    color: Theme.textTertiary
                    font.family: Theme.iconFont
                    font.pixelSize: 10
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (!root.enabled) return;
                    root.dropdownOpen = !root.dropdownOpen;
                }
            }
        }
    }

    // Dropdown list
    Rectangle {
        id: dropdownList
        visible: root.dropdownOpen
        anchors.top: parent.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(root.model.length * 34, 200)
        radius: Theme.radius
        color: Theme.surface0
        border.color: Theme.surface1
        border.width: 1
        z: 100
        clip: true

        ListView {
            id: listView
            anchors.fill: parent
            anchors.margins: 4
            model: root.model
            currentIndex: root.currentIndex
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                required property string modelData
                required property int index

                width: listView.width
                height: 30
                radius: Theme.radiusSm
                color: index === root.currentIndex
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                    : itemMouse.containsMouse ? Theme.surface1 : "transparent"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacing
                    text: modelData
                    color: index === root.currentIndex ? Theme.primary : Theme.textPrimary
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentIndex = index;
                        root.selected(index, modelData);
                        root.dropdownOpen = false;
                    }
                }
            }
        }
    }

    // Click-outside overlay to close dropdown
    Rectangle {
        visible: root.dropdownOpen
        parent: root.parent  // Render in parent's coordinate space
        anchors.fill: parent
        color: "transparent"
        z: 99

        MouseArea {
            anchors.fill: parent
            onClicked: root.dropdownOpen = false
        }
    }

    onDropdownOpenChanged: {
        if (dropdownOpen) forceActiveFocus();
    }

    Keys.onEscapePressed: dropdownOpen = false
    Keys.onUpPressed: {
        if (dropdownOpen && currentIndex > 0) currentIndex--;
    }
    Keys.onDownPressed: {
        if (dropdownOpen && currentIndex < model.length - 1) currentIndex++;
    }
    Keys.onReturnPressed: {
        if (dropdownOpen) {
            selected(currentIndex, model[currentIndex]);
            dropdownOpen = false;
        }
    }
}
```

- [ ] **Step 2: Add Dropdown demo to InputsSection**

Add to `quill/showcase/InputsSection.qml`:
- Dropdown with label
- Dropdown without label
- Disabled dropdown
- Display selected value text

- [ ] **Step 3: Verify and commit**

```bash
git add quill/components/Dropdown.qml quill/showcase/InputsSection.qml
git commit -m "feat(quill): add Dropdown component"
```

---

### Task 10: Card + Separator

**Files:**
- Create: `quill/components/Card.qml`
- Create: `quill/components/Separator.qml`
- Modify: `quill/showcase/LayoutSection.qml`

- [ ] **Step 1: Create Card.qml**

Create `quill/components/Card.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""

    default property alias content: contentColumn.data

    implicitHeight: mainColumn.implicitHeight + padding * 2
    Layout.fillWidth: true
    padding: Theme.spacingLg

    radius: Theme.radiusLg
    color: Theme.surface0
    border.color: Theme.surface1
    border.width: 1

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: Theme.spacing

        // Header
        ColumnLayout {
            visible: root.title !== ""
            spacing: 2
            Layout.bottomMargin: Theme.spacing

            Text {
                text: root.title
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeLarge
                font.family: Theme.fontFamily
                font.bold: true
            }

            Text {
                visible: root.subtitle !== ""
                text: root.subtitle
                color: Theme.textTertiary
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
            }
        }

        // Content
        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            spacing: Theme.spacing
        }
    }
}
```

- [ ] **Step 2: Create Separator.qml**

Create `quill/components/Separator.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property int orientation: Qt.Horizontal

    Layout.fillWidth: orientation === Qt.Horizontal
    Layout.fillHeight: orientation === Qt.Vertical

    implicitWidth: orientation === Qt.Horizontal ? 100 : 1
    implicitHeight: orientation === Qt.Horizontal ? 1 : 100

    color: Theme.surface1
}
```

- [ ] **Step 3: Build LayoutSection with Card + Separator demos**

Replace `quill/showcase/LayoutSection.qml`:
- Card with title and subtitle, containing some sample text
- Card without header
- Horizontal separator
- Vertical separator (inside a Row)

- [ ] **Step 4: Verify and commit**

```bash
git add quill/components/Card.qml quill/components/Separator.qml quill/showcase/LayoutSection.qml
git commit -m "feat(quill): add Card and Separator components"
```

---

### Task 11: Tabs

**Files:**
- Create: `quill/components/Tabs.qml`
- Modify: `quill/showcase/LayoutSection.qml`

- [ ] **Step 1: Create Tabs.qml**

Create `quill/components/Tabs.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    property var model: []
    property int currentIndex: 0
    property bool enabled: true

    signal tabChanged(int index)

    implicitHeight: 36
    opacity: enabled ? 1.0 : 0.5
    Layout.fillWidth: true

    Row {
        id: tabRow
        anchors.fill: parent
        spacing: 0

        Repeater {
            id: tabRepeater
            model: root.model

            Item {
                required property string modelData
                required property int index

                width: tabText.implicitWidth + Theme.spacingXl * 2
                height: root.height

                Text {
                    id: tabText
                    anchors.centerIn: parent
                    text: modelData
                    color: index === root.currentIndex ? Theme.primary : Theme.textTertiary
                    font.pixelSize: Theme.fontSize
                    font.family: Theme.fontFamily
                    font.bold: index === root.currentIndex
                    Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.enabled) return;
                        root.currentIndex = index;
                        root.tabChanged(index);
                    }
                }
            }
        }
    }

    // Underline indicator
    Rectangle {
        id: underline
        height: 2
        radius: 1
        color: Theme.primary
        anchors.bottom: parent.bottom
        y: parent.height - 2

        // Use Repeater.itemAt() to avoid off-by-one from Repeater being in children list
        property Item currentTab: tabRepeater.itemAt(root.currentIndex)
        x: currentTab ? currentTab.x : 0
        width: currentTab ? currentTab.width : 0

        Behavior on x { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
    }

    // Bottom border
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.surface1
    }
}
```

- [ ] **Step 2: Add Tabs demo to LayoutSection**

Add to `quill/showcase/LayoutSection.qml`:
- Tabs with 3 items, switching content below using StackLayout or visibility toggle
- Display which tab is selected

- [ ] **Step 3: Verify and commit**

```bash
git add quill/components/Tabs.qml quill/showcase/LayoutSection.qml
git commit -m "feat(quill): add Tabs component"
```

---

### Task 12: Collapsible

**Files:**
- Create: `quill/components/Collapsible.qml`
- Modify: `quill/showcase/LayoutSection.qml`

- [ ] **Step 1: Create Collapsible.qml**

Create `quill/components/Collapsible.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    id: root

    property string title: ""
    property bool expanded: false
    property bool enabled: true

    default property alias content: contentContainer.data

    spacing: 0
    opacity: enabled ? 1.0 : 0.5
    Layout.fillWidth: true

    // Header
    Rectangle {
        Layout.fillWidth: true
        height: 40
        radius: Theme.radius
        color: headerMouse.containsMouse ? Theme.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacing
            anchors.rightMargin: Theme.spacing

            Text {
                text: root.title
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSize
                font.family: Theme.fontFamily
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: "\uf078"
                color: Theme.textTertiary
                font.family: Theme.iconFont
                font.pixelSize: 10
                rotation: root.expanded ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
            }
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: { if (root.enabled) root.expanded = !root.expanded; }
        }
    }

    // Content
    Item {
        Layout.fillWidth: true
        implicitHeight: root.expanded ? contentContainer.implicitHeight : 0
        clip: true

        Behavior on implicitHeight {
            NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: contentContainer
            width: parent.width
            spacing: Theme.spacing
        }
    }
}
```

- [ ] **Step 2: Add Collapsible demo to LayoutSection**

Add to `quill/showcase/LayoutSection.qml`:
- Collapsible with some content (text, a button)
- Initially expanded collapsible
- Nested collapsibles

- [ ] **Step 3: Verify and commit**

```bash
git add quill/components/Collapsible.qml quill/showcase/LayoutSection.qml
git commit -m "feat(quill): add Collapsible component"
```

---

### Task 13: ScrollableList

**Files:**
- Create: `quill/components/ScrollableList.qml`
- Modify: `quill/showcase/LayoutSection.qml`

- [ ] **Step 1: Create ScrollableList.qml**

Create `quill/components/ScrollableList.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    property alias model: listView.model
    property alias delegate: listView.delegate
    property string emptyText: "No items"

    implicitHeight: 200
    Layout.fillWidth: true

    // Empty state
    Text {
        visible: listView.count === 0
        anchors.centerIn: parent
        text: root.emptyText
        color: Theme.textTertiary
        font.pixelSize: Theme.fontSize
        font.family: Theme.fontFamily
    }

    ListView {
        id: listView
        anchors.fill: parent
        clip: true
        spacing: Theme.spacing
        boundsBehavior: Flickable.StopAtBounds
        visible: count > 0
    }

    // Styled scrollbar
    Rectangle {
        id: scrollbar
        visible: listView.contentHeight > listView.height
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 4
        color: "transparent"

        Rectangle {
            width: parent.width
            radius: 2
            color: Theme.surface2
            opacity: listView.moving ? 0.8 : 0.3
            Behavior on opacity { NumberAnimation { duration: Theme.animDuration } }

            y: listView.contentY / listView.contentHeight * parent.height
            height: Math.max(20, (listView.height / listView.contentHeight) * parent.height)
        }
    }
}
```

- [ ] **Step 2: Add ScrollableList demo to LayoutSection**

Add to `quill/showcase/LayoutSection.qml`:
- ScrollableList with 20+ sample items (simple text rectangles)
- ScrollableList with empty model showing emptyText

- [ ] **Step 3: Verify and commit**

```bash
git add quill/components/ScrollableList.qml quill/showcase/LayoutSection.qml
git commit -m "feat(quill): add ScrollableList component"
```

---

### Task 14: Tooltip + Badge

**Files:**
- Create: `quill/components/Tooltip.qml`
- Create: `quill/components/Badge.qml`
- Modify: `quill/showcase/FeedbackSection.qml`
- Modify: `quill/components/IconButton.qml` (uncomment Tooltip usage if commented)

- [ ] **Step 1: Create Tooltip.qml**

Create `quill/components/Tooltip.qml`. Visibility is controlled by the parent component (e.g., `visible: mouseArea.containsMouse`). The Tooltip handles positioning and rendering:

```qml
import QtQuick
import ".."

Item {
    id: root

    property Item target: parent
    property string text: ""

    // visible is controlled externally by the parent component
    z: 1000

    // Position above target
    x: target ? (target.width - tooltipBg.width) / 2 : 0
    y: target ? -tooltipBg.height - 6 : 0

    Rectangle {
        id: tooltipBg
        width: tooltipText.implicitWidth + Theme.spacingMd * 2
        height: tooltipText.implicitHeight + Theme.spacing * 2
        radius: Theme.radiusSm
        color: Theme.surface2

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: root.text
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
        }
    }

    // Fade in/out
    opacity: visible ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: Theme.animDurationFast } }
}
```

Usage pattern — parent controls visibility:
```qml
IconButton {
    id: btn
    Tooltip { target: btn; text: "Settings"; visible: mouse.containsMouse }
}
```

- [ ] **Step 2: Wire up Tooltip in IconButton**

Update `quill/components/IconButton.qml` to properly show/hide the Tooltip:
```qml
Tooltip {
    target: root
    text: root.tooltip
    visible: root.tooltip !== "" && mouse.containsMouse
}
```

- [ ] **Step 3: Create Badge.qml**

Create `quill/components/Badge.qml`:

```qml
import QtQuick
import ".."

Rectangle {
    id: root

    property string text: ""
    property string variant: "primary" // "primary" | "success" | "warning" | "error"

    property bool _isDot: text === ""

    implicitWidth: _isDot ? 8 : badgeText.implicitWidth + Theme.spacingMd * 2
    implicitHeight: _isDot ? 8 : 20
    radius: Theme.radiusFull

    color: {
        switch (variant) {
            case "success": return Theme.success;
            case "warning": return Theme.warning;
            case "error": return Theme.error;
            default: return Theme.primary;
        }
    }

    Text {
        id: badgeText
        visible: !root._isDot
        anchors.centerIn: parent
        text: root.text
        color: Theme.backgroundDeep
        font.pixelSize: Theme.fontSizeSmall
        font.family: Theme.fontFamily
        font.bold: true
    }
}
```

- [ ] **Step 4: Build FeedbackSection with Tooltip + Badge demos**

Replace `quill/showcase/FeedbackSection.qml`:
- IconButton with tooltip (hover to see)
- Badge with text in all variants (primary, success, warning, error)
- Dot badges (no text)

- [ ] **Step 5: Verify and commit**

```bash
git add quill/components/Tooltip.qml quill/components/Badge.qml quill/components/IconButton.qml quill/showcase/FeedbackSection.qml
git commit -m "feat(quill): add Tooltip and Badge components"
```

---

### Task 15: ProgressBar + Spinner

**Files:**
- Create: `quill/components/ProgressBar.qml`
- Create: `quill/components/Spinner.qml`
- Modify: `quill/showcase/FeedbackSection.qml`

- [ ] **Step 1: Create ProgressBar.qml**

Create `quill/components/ProgressBar.qml`:

```qml
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property real value: 0.0        // 0.0 to 1.0
    property string variant: "primary"
    property bool indeterminate: false

    implicitHeight: 6
    Layout.fillWidth: true
    radius: Theme.radiusFull
    color: Theme.surface1

    property color _fillColor: {
        switch (variant) {
            case "success": return Theme.success;
            case "warning": return Theme.warning;
            case "error": return Theme.error;
            default: return Theme.primary;
        }
    }

    // Determinate fill
    Rectangle {
        visible: !root.indeterminate
        width: parent.width * Math.max(0, Math.min(1, root.value))
        height: parent.height
        radius: Theme.radiusFull
        color: root._fillColor

        Behavior on width { NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic } }
    }

    // Indeterminate animation
    Rectangle {
        id: indeterminateBar
        visible: root.indeterminate
        width: parent.width * 0.3
        height: parent.height
        radius: Theme.radiusFull
        color: root._fillColor

        SequentialAnimation on x {
            running: root.indeterminate
            loops: Animation.Infinite
            NumberAnimation {
                from: -indeterminateBar.width
                to: root.width
                duration: 1200
                easing.type: Easing.InOutCubic
            }
        }
    }

    clip: true
}
```

- [ ] **Step 2: Create Spinner.qml**

Create `quill/components/Spinner.qml`:

```qml
import QtQuick
import ".."

Item {
    id: root

    property string size: "medium" // "small" | "medium" | "large"
    property color color: Theme.primary
    property bool running: true

    property int _size: size === "small" ? 16 : size === "large" ? 32 : 24

    implicitWidth: _size
    implicitHeight: _size

    Rectangle {
        id: spinner
        anchors.fill: parent
        radius: Theme.radiusFull
        color: "transparent"
        border.color: Theme.surface1
        border.width: 2

        // Rotating partial arc using Canvas
        Canvas {
            id: canvas
            anchors.fill: parent
            onPaint: {
                let ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = root.color.toString();
                ctx.lineWidth = 2;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, width / 2 - 2, 0, Math.PI * 1.2);
                ctx.stroke();
            }
            Component.onCompleted: requestPaint()
        }

        RotationAnimation on rotation {
            running: root.running
            from: 0; to: 360
            duration: 1000
            loops: Animation.Infinite
        }
    }

    onColorChanged: canvas.requestPaint()
}
```

- [ ] **Step 3: Add ProgressBar + Spinner demos to FeedbackSection**

Add to `quill/showcase/FeedbackSection.qml`:
- ProgressBar at various values (0.25, 0.5, 0.75)
- ProgressBar with slider to control value interactively
- Indeterminate ProgressBar
- ProgressBar variants (primary, success, warning, error)
- Spinner in all sizes
- Spinner with custom color

- [ ] **Step 4: Verify and commit**

```bash
git add quill/components/ProgressBar.qml quill/components/Spinner.qml quill/showcase/FeedbackSection.qml
git commit -m "feat(quill): add ProgressBar and Spinner components"
```

---

### Task 16: Avatar + DisplaySection

**Files:**
- Create: `quill/components/Avatar.qml`
- Modify: `quill/showcase/DisplaySection.qml`

- [ ] **Step 1: Create Avatar.qml**

Create `quill/components/Avatar.qml`:

```qml
import QtQuick
import ".."

Rectangle {
    id: root

    property string source: ""
    property string fallback: ""
    property string size: "medium"  // "small" | "medium" | "large"
    property bool rounded: true

    property int _size: size === "small" ? 28 : size === "large" ? 48 : 36

    implicitWidth: _size
    implicitHeight: _size
    radius: rounded ? Theme.radiusFull : Theme.radius
    color: Theme.surface1
    clip: true

    // Image (clipping handled by parent's clip + radius)
    Image {
        id: img
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
    }

    // Fallback initials
    Text {
        visible: img.status !== Image.Ready
        anchors.centerIn: parent
        text: root.fallback
        color: Theme.textPrimary
        font.pixelSize: root._size * 0.4
        font.family: Theme.fontFamily
        font.bold: true
    }
}
```

- [ ] **Step 2: Build DisplaySection**

Replace `quill/showcase/DisplaySection.qml`:

**Icon demos:**
- Grid of common nerd font icons in all sizes
- Icons with different colors

**Label demos:**
- All 4 variants stacked (heading, body, caption, overline)

**Avatar demos:**
- Avatar with fallback initials in all sizes
- Avatar with rounded vs square
- Note: image source demo can use a placeholder or skip if no image available

- [ ] **Step 3: Verify and commit**

```bash
git add quill/components/Avatar.qml quill/showcase/DisplaySection.qml
git commit -m "feat(quill): add Avatar component and complete DisplaySection"
```

---

### Task 17: Final Integration + Polish

**Files:**
- Modify: `quickshell/shell.qml` (verify integration)
- Review all showcase sections for completeness

- [ ] **Step 1: Verify shell.qml integration**

Confirm `quickshell/shell.qml` has:
```qml
import "../quill" as Quill
```
And inside ShellRoot:
```qml
Quill.Showcase {}
```

- [ ] **Step 2: Full visual verification**

Run quickshell and open the showcase. Walk through every section:
- **Inputs:** All 8 input components render and are interactive
- **Layout:** Card, Separator, Tabs, Collapsible, ScrollableList all work
- **Feedback:** Tooltip appears on hover, badges render, progress bar animates, spinner spins
- **Display:** Icons render with correct font, labels show all variants, avatars show initials

Fix any issues found.

- [ ] **Step 3: Commit any fixes**

```bash
git add -A quill/
git commit -m "fix(quill): polish showcase and fix visual issues"
```

- [ ] **Step 4: Update tasks.md**

Per CLAUDE.md rules, update `tasks.md` with the new Quill library entry under an appropriate category.

- [ ] **Step 5: Final commit**

```bash
git add tasks.md
git commit -m "docs: add Quill UI library to tasks.md"
```
