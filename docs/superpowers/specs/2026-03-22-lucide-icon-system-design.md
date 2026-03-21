# Lucide Icon System Design

## Overview

Replace all Nerd Font unicode glyph icons across the quickshell UI with Lucide-based QML Shape components using PathSvg. This gives crisp vector rendering at any size, theme-aware coloring via direct property bindings, per-path color override capability, and zero font dependency.

## Architecture

### Icon Component Structure

Each icon is an individual QML file in `quickshell/icons/` (e.g., `IconWifi.qml`). All icons follow the same base API:

**Common properties:**
- `size: 24` — width and height (square, matches Lucide's 24x24 viewBox)
- `color: "#ffffff"` — default stroke color applied to all paths
- `strokeWidth: size / 12` — scales with size, matches Lucide's default 2px at 24px

**Rendering approach:**
- Each icon is a `Shape` element containing one or more `ShapePath` + `PathSvg` entries
- Raw Lucide SVG path data is used unmodified
- Scaling is handled via `scale: Qt.size(size / 24, size / 24)` with `transformOrigin: Item.TopLeft`
- `capStyle: ShapePath.RoundCap` and `joinStyle: ShapePath.RoundJoin` match Lucide's stroke style
- `layer.enabled: true; layer.smooth: true` for anti-aliasing

**Per-path coloring:**
- All ShapePaths default to `root.color`
- Since each is a separate ShapePath, consumers can override individual path colors via states or JavaScript for special cases (e.g., animating wifi signal bars)

### Example Component

```qml
// quickshell/icons/IconWifi.qml
import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property real size: 24
    property color color: "#ffffff"
    property real strokeWidth: size / 12
    width: size; height: size
    layer.enabled: true; layer.smooth: true

    ShapePath {
        strokeColor: root.color; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M5 12.55a11 11 0 0 1 14.08 0" }
    }
    ShapePath {
        strokeColor: root.color; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M1.42 9a16 16 0 0 1 21.16 0" }
    }
    ShapePath {
        strokeColor: root.color; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M8.53 16.11a6 6 0 0 1 6.95 0" }
    }
    ShapePath {
        strokeColor: root.color; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M2 20h.01" }
    }
}
```

### Module Registration

`quickshell/icons/qmldir` registers all components:

```
module Icons

IconBell 1.0 IconBell.qml
IconBellOff 1.0 IconBellOff.qml
...
```

Consumer files use direct imports:

```qml
import "icons"

IconWifi { size: 14; color: Theme.text }
```

## Icon Inventory (~40 unique components)

### Bar Icons
| Component | Lucide Name | Used In |
|-----------|-------------|---------|
| IconBell | bell | NotificationBell.qml |
| IconBellOff | bell-off | NotificationBell.qml |
| IconBluetooth | bluetooth | Bluetooth.qml |
| IconBluetoothOff | bluetooth-off | Bluetooth.qml |
| IconWifi | wifi | NetworkStatus.qml |
| IconEthernet | ethernet (cable) | NetworkStatus.qml |
| IconTriangleAlert | triangle-alert | NetworkStatus.qml |
| IconVolume2 | volume-2 | Volume.qml |
| IconVolume1 | volume-1 | Volume.qml |
| IconVolume | volume | Volume.qml |
| IconVolumeX | volume-x | Volume.qml |
| IconPlay | play | MediaPlayer.qml |
| IconPause | pause | MediaPlayer.qml |
| IconZap | zap | Battery.qml |

### NotificationCenter Quick Toggles
| Component | Lucide Name | Purpose |
|-----------|-------------|---------|
| IconMoon | moon | Night light toggle |
| IconCamera | camera | Screenshot button |
| IconPower | power | Power menu button |
| IconRefreshCw | refresh-cw | Reload button |
| IconCoffee | coffee | Caffeine toggle |
| IconSettings | settings | Settings button |
| IconSun | sun | Brightness control |
| IconTrash | trash-2 | Clear notifications |

### Settings Sidebar
| Component | Lucide Name | Page |
|-----------|-------------|------|
| IconPalette | palette | Appearance |
| IconPanelTop | panel-top | Bar |
| IconRocket | rocket | Launcher |
| IconClipboard | clipboard | Clipboard |
| IconSliders | sliders-horizontal | OSD |
| IconCalendar | calendar | Calendar |
| IconBattery | battery | Battery |
| IconLink | link | Integrations |
| IconUndo | undo-2 | Reset buttons |

### PowerMenu
| Component | Lucide Name | Action |
|-----------|-------------|--------|
| IconLogOut | log-out | Logout |
| IconCloud | cloud | Hibernate |

### LockScreen
| Component | Lucide Name | Purpose |
|-----------|-------------|---------|
| IconCheck | check | Success status |
| IconX | x | Error status |
| IconUser | user | Default user icon |
| IconEye | eye | Show password |
| IconEyeOff | eye-off | Hide password |

### OSD
| Component | Lucide Name | Purpose |
|-----------|-------------|---------|
| IconLock | lock | Caps lock on |
| IconUnlock | lock-open | Caps lock off |
| IconKeyboard | keyboard | Num lock |

### Popups & Misc
| Component | Lucide Name | Purpose |
|-----------|-------------|---------|
| IconChevronLeft | chevron-left | Navigation |
| IconChevronRight | chevron-right | Navigation |
| IconClock | clock | Uptime display |
| IconImage | image | Clipboard image item |
| IconAlertCircle | alert-circle | Critical notification |
| IconInfo | info | Low urgency notification |
| IconSkipBack | skip-back | Previous track |
| IconSkipForward | skip-forward | Next track |

### Reuse Summary
Many icons are shared across components: IconBell (bar + notifications + settings), IconWifi (bar + notification center + settings), IconPower (notification center + power menu), IconLock (settings + OSD + power menu), IconRefreshCw (notification center + power menu + StatusBar), etc.

## Icon Gallery Page

A new `IconGalleryPage.qml` settings page showing all available icons:

- **Grid layout** of all icons with names below each
- **Size slider** to preview at 12, 16, 20, 24, 32, 48px
- **Color selector** toggling between theme colors (text, subtext0, blue, red, green, yellow, etc.)
- **Search/filter** text field to filter icons by name
- Added to the Settings sidebar alongside existing pages

## Migration Strategy

### What Changes
- All `Text { text: "\uXXXX"; font.family: Theme.iconFont }` patterns replaced with corresponding icon components
- `import "icons"` added to every file using icons
- Layout adjustments as needed (Text has baseline alignment, Shape does not)

### What Stays
- QML-drawn battery body in Battery.qml (only the charging bolt `\uf0e7` becomes IconZap)
- Dynamic system icons in SysTray, AppLauncher, StatusBar menu entries (loaded via `Image {}` from system theme)

### Migration Order
1. Create all ~40 icon components in `quickshell/icons/`
2. Add `qmldir` in `quickshell/icons/`
3. Build IconGallery page to verify rendering
4. Migrate file-by-file: bar -> notification center -> settings -> power menu -> lock screen -> OSD -> popups
5. Clean up unused `iconFont` references from Config/Theme if no longer needed

### Post-Migration Cleanup
- Remove `Config.iconFont` / `Theme.iconFont` if no remaining usages
- Remove nerd font icon dependency if fully replaced
