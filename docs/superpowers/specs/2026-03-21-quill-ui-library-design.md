# Quill — QML Component Library for Quickshell

**Date:** 2026-03-21
**Status:** Approved

## Overview

Quill is a reusable QML component library for Quickshell, similar to shadcn/ui for web. It provides styled, themeable UI primitives (buttons, inputs, layout containers, feedback indicators, display elements) with Catppuccin Mocha defaults. Designed for personal use and shareability.

## Project Structure

```
quill/
├── qmldir                  # Module manifest — "import Quill"
├── Theme.qml               # Theme interface + defaults (singleton)
├── Showcase.qml            # Standalone panel showing all components
│
├── components/
│   ├── Button.qml
│   ├── IconButton.qml
│   ├── Toggle.qml
│   ├── Slider.qml
│   ├── TextField.qml
│   ├── Dropdown.qml
│   ├── Checkbox.qml
│   ├── RadioButton.qml
│   ├── RadioGroup.qml
│   ├── Card.qml
│   ├── Separator.qml
│   ├── Tabs.qml
│   ├── Collapsible.qml
│   ├── ScrollableList.qml
│   ├── Tooltip.qml
│   ├── Badge.qml
│   ├── ProgressBar.qml
│   ├── Spinner.qml
│   ├── Icon.qml
│   ├── Avatar.qml
│   └── Label.qml
│
└── showcase/
    ├── InputsSection.qml
    ├── LayoutSection.qml
    ├── FeedbackSection.qml
    └── DisplaySection.qml
```

### qmldir Registration

The `qmldir` file must explicitly list each component with its relative path since they live in a subdirectory. Showcase files are deliberately excluded — they are internal.

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

## Theme System

Singleton `Theme.qml` defining the full contract. Ships with Catppuccin Mocha defaults. All properties are bindable — runtime changes update every component reactively.

### Properties

**Colors — Surface hierarchy:**
- `background` (#1e1e2e), `backgroundAlt` (#181825), `backgroundDeep` (#11111b)
- `surface0` (#313244), `surface1` (#45475a), `surface2` (#585b70)
- `overlay0` (#6c7086), `overlay1` (#7f849c)

**Colors — Text:**
- `textPrimary` (#cdd6f4), `textSecondary` (#bac2de), `textTertiary` (#a6adc8)

**Colors — Semantic:**
- `primary` (#89b4fa/blue), `secondary` (#b4befe/lavender), `accent` (#cba6f7/mauve)
- `success` (#a6e3a1/green), `warning` (#f9e2af/yellow), `error` (#f38ba8/red), `info` (#89dceb/teal)

**Colors — Catppuccin aliases** (for migration ease, map to the semantic names above):
- `blue` → `primary`, `lavender` → `secondary`, `mauve` → `accent`
- `green` → `success`, `yellow` → `warning`, `red` → `error`, `teal` → `info`
- `base` → `background`, `mantle` → `backgroundAlt`, `crust` → `backgroundDeep`
- `text` → `textPrimary`, `subtext1` → `textSecondary`, `subtext0` → `textTertiary`

These are readonly property aliases, not separate values. Changing `primary` also changes `blue`.

**Typography:**
- `fontFamily` ("Maple Mono"), `iconFont` ("Maple Mono NF")
- `fontSizeSmall` (11), `fontSize` (13), `fontSizeLarge` (16), `fontSizeHeading` (20)

**Spacing:**
- `spacingXs` (4), `spacingSm` (6), `spacing` (8), `spacingMd` (12), `spacingLg` (16), `spacingXl` (24)

**Radii:**
- `radius` (8), `radiusSm` (4), `radiusLg` (12), `radiusFull` (9999)

**Animation:**
- `animDuration` (200), `animDurationFast` (100), `animDurationSlow` (350)

**Transparency:**
- `transparencyEnabled` (false), `transparencyLevel` (0.85)
- `bg(color, opacity)` helper — applies transparency when enabled. Inside Quill components, called as `Theme.bg(color, 0.5)`. External consumers call `Quill.Theme.bg(color, 0.5)` (where `Quill` is the import qualifier).

### Consumer Override

```qml
import "../quill" as Quill

// In Component.onCompleted or bindings:
Quill.Theme.primary = "#ff6600"
Quill.Theme.fontFamily = "JetBrains Mono"
```

### Sizing Philosophy

Components have sensible implicit sizes but respect explicit `width`/`height`. Layout-aware components (Card, TextField, Tabs) support `Layout.fillWidth`. Buttons and inputs have size presets (`"small"`, `"medium"`, `"large"`) that set implicit dimensions.

## Component APIs

All interactive components support `enabled: true` (default). When disabled: reduced opacity (0.5), no hover effects, no click handling.

### Inputs & Controls

**Button** — Text, icon, or both. Variants: `"primary"`, `"secondary"`, `"ghost"`, `"danger"`. Sizes: `"small"`, `"medium"`, `"large"`. Press/hover animations.
```qml
Button { text: "Save"; icon: "\u{f0c7}"; variant: "primary"; onClicked: { } }
```

**IconButton** — Circular icon-only button. Same variants/sizes as Button. Optional `tooltip` property (renders a Tooltip child internally).
```qml
IconButton { icon: "\u{f011}"; tooltip: "Power off"; onClicked: { } }
```

**Toggle** — Animated sliding switch. Optional `label`.
```qml
Toggle { checked: true; label: "Enable notifications"; onToggled: (value) => { } }
```

**Slider** — Range input with optional value display. Properties: `value`, `from`, `to`, `stepSize`, `label`, `showValue`.
```qml
Slider { value: 75; from: 0; to: 100; stepSize: 1; label: "Volume"; showValue: true; onMoved: (value) => { } }
```

**TextField** — Text input with optional leading icon. Variants: `"default"`, `"filled"`.
```qml
TextField { placeholder: "Search..."; icon: "\u{f002}"; onSubmitted: (text) => { } }
```

**Dropdown** — Select from a list. The dropdown list renders as a sibling item within the same parent, positioned absolutely with a high z-index. Keyboard navigable (arrow keys + Enter).
```qml
Dropdown { model: ["A", "B", "C"]; currentIndex: 0; label: "Theme"; onSelected: (index, value) => { } }
```

**Checkbox** — Standard checkbox with label.
```qml
Checkbox { checked: false; label: "Remember me"; onToggled: (value) => { } }
```

**RadioButton / RadioGroup** — Exclusive selection. RadioButton checks `parent.value === value` for its selected state and calls `parent.selected(value)` when clicked. Works standalone too (manages its own `checked` property).
```qml
RadioGroup {
    value: "left"; onSelected: (value) => { }
    RadioButton { value: "left"; label: "Left" }
    RadioButton { value: "center"; label: "Center" }
}
```

### Layout & Containers

**Card** — Rounded rectangle with optional `title` and `subtitle` header. Children are content.
```qml
Card { title: "Network"; padding: Theme.spacing; ColumnLayout { ... } }
```

**Separator** — Horizontal or vertical line.
```qml
Separator { orientation: Qt.Horizontal }
```

**Tabs** — Horizontal tab bar with animated underline. Consumer handles content switching.
```qml
Tabs { model: ["General", "Advanced"]; currentIndex: 0; onTabChanged: (index) => { } }
```

**Collapsible** — Animated expand/collapse with chevron. Children shown when expanded.
```qml
Collapsible { title: "Advanced options"; expanded: false; ColumnLayout { ... } }
```

**ScrollableList** — ListView with styled scrollbar and empty state.
```qml
ScrollableList { model: myModel; delegate: Component { Card { ... } }; emptyText: "No items" }
```

### Feedback & Overlays

**Tooltip** — Child component pattern (not attached properties, as those require C++ in QML). Watches parent's MouseArea hover state. Auto-positioned above/below parent.
```qml
IconButton {
    id: btn
    Tooltip { target: btn; text: "Settings"; delay: 500 }
}
```
Note: `IconButton.tooltip` string property creates a Tooltip child internally for convenience.

**Badge** — Pill-shaped label. Variants: `"primary"`, `"success"`, `"warning"`, `"error"`. No text = dot indicator.
```qml
Badge { text: "3"; variant: "primary" }
```

**ProgressBar** — Determinate or indeterminate. Value 0.0–1.0.
```qml
ProgressBar { value: 0.65; variant: "primary"; indeterminate: false }
```

**Spinner** — Animated rotating indicator.
```qml
Spinner { size: "medium"; color: Theme.primary; running: true }
```

### Display

**Icon** — Nerd font icon wrapper with standardized sizing. `glyph` is the Unicode codepoint.
```qml
Icon { glyph: "\u{f015}"; size: "medium"; color: Theme.textPrimary }
```

**Avatar** — Image or initials fallback. Circle or rounded square.
```qml
Avatar { source: "/path/to/image"; fallback: "JD"; size: "medium"; rounded: true }
```

**Label** — Styled text. Variants: `"heading"`, `"body"`, `"caption"`, `"overline"`.
```qml
Label { text: "Heading"; variant: "heading" }
```

## Keyboard Navigation

V1 is mouse-primary. Dropdown supports arrow keys + Enter for selection. TextField handles standard text input keys. Other keyboard navigation (tab focus order, Space to toggle) is a v2 concern.

## Showcase Panel

Standalone `PanelWindow` launched via keybind. Layout:
- **Left sidebar** — category navigation (Inputs, Layout, Feedback, Display)
- **Main area** — components in selected category, each in a Card with name, description, live interactive example, and QML usage snippet

Sections:
- **InputsSection** — All button variants, toggle states, draggable slider, typeable text field, openable dropdown, checkbox/radio interactive
- **LayoutSection** — Card with content, separators, tab switching, collapsible opening/closing, scrollable list with sample items
- **FeedbackSection** — Tooltip hover demo, badge variants, progress bar with slider control, running spinner
- **DisplaySection** — Icon grid of common icons, avatar with image and fallback, label variants stacked

Integration: registered in `shell.qml` via LazyLoader, opened via IpcHandler keybind. Uses Quill's own Theme defaults.

## Integration with Existing Dotfiles

Not part of v1 scope, but the migration path:

**Import:** `import "../quill" as Quill` from quickshell files.

**Theme bridging:** Map Config values to Quill.Theme properties in `Component.onCompleted`. Catppuccin aliases make this straightforward — `Quill.Theme.blue` works if you prefer the original names.

**Gradual adoption:** Existing `ToggleSetting`, `SliderSetting`, `TextSetting` become thin wrappers around Quill.Toggle, Quill.Slider, Quill.TextField. Swap components one at a time — nothing breaks.
