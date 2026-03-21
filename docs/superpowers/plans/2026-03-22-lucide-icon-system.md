# Lucide Icon System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all Nerd Font unicode glyph icons with Lucide-based QML Shape+PathSvg icon components across the entire quickshell UI.

**Architecture:** Each icon is an individual QML file in `quickshell/icons/` using Qt Quick Shapes. Icons render Lucide SVG path data via `ShapePath` + `PathSvg`, with properties for `size`, `color`, and `strokeWidth`. Consumer files import via `import "icons"` and use icons as components (e.g., `IconWifi { size: 14; color: Theme.text }`).

**Tech Stack:** QML/Qt Quick, QtQuick.Shapes, Lucide icon SVG path data

**Spec:** `docs/superpowers/specs/2026-03-22-lucide-icon-system-design.md`

---

## SVG Element Conversion Reference

QML Shape only supports `PathSvg`. Convert non-path SVG elements as follows:

**`<circle cx="12" cy="12" r="3">`** → `PathSvg { path: "M9 12a3 3 0 1 0 6 0a3 3 0 1 0-6 0" }`
Formula: `M(cx-r) cy a r r 0 1 0 (2*r) 0 a r r 0 1 0 -(2*r) 0`

**`<rect x="3" y="4" width="18" height="18" rx="2">`** → `PathSvg { path: "M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z" }`
Formula: Convert to path with arcs for rounded corners.

**`<line x1="22" x2="16" y1="9" y2="15">`** → `PathSvg { path: "M22 9L16 15" }`

---

## Lucide Path Data Reference

All path data sourced from `unpkg.com/lucide-static@latest/icons/`. Each icon uses 24x24 viewBox, stroke-width 2, round cap/join. Elements marked `[fill]` need `fillColor: root.color` instead of stroke. Elements marked `[circle]` or `[rect]` or `[line]` need conversion per above.

### Bar Icons

**bell**
- `M10.268 21a2 2 0 0 0 3.464 0`
- `M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326`

**bell-off**
- `M10.268 21a2 2 0 0 0 3.464 0`
- `M17 17H4a1 1 0 0 1-.74-1.673C4.59 13.956 6 12.499 6 8a6 6 0 0 1 .258-1.742`
- `m2 2 20 20`
- `M8.668 3.01A6 6 0 0 1 18 8c0 2.687.77 4.653 1.707 6.05`

**bluetooth**
- `m7 7 10 10-5 5V2l5 5L7 17`

**bluetooth-off**
- `m17 17-5 5V12l-5 5`
- `m2 2 20 20`
- `M14.5 9.5 17 7l-5-5v4.5`

**bluetooth-connected** (custom: bluetooth paths + connection dots)
- `m7 7 10 10-5 5V2l5 5L7 17`
- `M18 12h.01` (connection indicator dot)
- `M6 12h.01` (connection indicator dot)

**wifi**
- `M12 20h.01`
- `M2 8.82a15 15 0 0 1 20 0`
- `M5 12.859a10 10 0 0 1 14 0`
- `M8.5 16.429a5 5 0 0 1 7 0`

**ethernet-port**
- `m15 20 3-3h2a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h2l3 3z`
- `M6 8v1`
- `M10 8v1`
- `M14 8v1`
- `M18 8v1`

**triangle-alert**
- `m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3`
- `M12 9v4`
- `M12 17h.01`

**volume-2**
- `M11 4.702a.705.705 0 0 0-1.203-.498L6.413 7.587A1.4 1.4 0 0 1 5.416 8H3a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h2.416a1.4 1.4 0 0 1 .997.413l3.383 3.384A.705.705 0 0 0 11 19.298z`
- `M16 9a5 5 0 0 1 0 6`
- `M19.364 18.364a9 9 0 0 0 0-12.728`

**volume-1**
- `M11 4.702a.705.705 0 0 0-1.203-.498L6.413 7.587A1.4 1.4 0 0 1 5.416 8H3a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h2.416a1.4 1.4 0 0 1 .997.413l3.383 3.384A.705.705 0 0 0 11 19.298z`
- `M16 9a5 5 0 0 1 0 6`

**volume**
- `M11 4.702a.705.705 0 0 0-1.203-.498L6.413 7.587A1.4 1.4 0 0 1 5.416 8H3a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h2.416a1.4 1.4 0 0 1 .997.413l3.383 3.384A.705.705 0 0 0 11 19.298z`

**volume-x**
- `M11 4.702a.705.705 0 0 0-1.203-.498L6.413 7.587A1.4 1.4 0 0 1 5.416 8H3a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h2.416a1.4 1.4 0 0 1 .997.413l3.383 3.384A.705.705 0 0 0 11 19.298z`
- `[line]` M22 9L16 15
- `[line]` M16 9L22 15

**play** `[fill]`
- `M5 5a2 2 0 0 1 3.008-1.728l11.997 6.998a2 2 0 0 1 .003 3.458l-12 7A2 2 0 0 1 5 19z`

**pause** `[rect-based]`
- `[rect]` x=14 y=3 width=5 height=18 rx=1 → `M15 3h3a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1h-3a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z`
- `[rect]` x=5 y=3 width=5 height=18 rx=1 → `M6 3h3a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z`

**zap** `[fill]`
- `M4 14a1 1 0 0 1-.78-1.63l9.9-10.2a.5.5 0 0 1 .86.46l-1.92 6.02A1 1 0 0 0 13 10h7a1 1 0 0 1 .78 1.63l-9.9 10.2a.5.5 0 0 1-.86-.46l1.92-6.02A1 1 0 0 0 11 14z`

### NotificationCenter / Quick Toggles

**moon**
- `M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401`

**camera**
- `M13.997 4a2 2 0 0 1 1.76 1.05l.486.9A2 2 0 0 0 18.003 7H20a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1.997a2 2 0 0 0 1.759-1.048l.489-.904A2 2 0 0 1 10.004 4z`
- `[circle]` cx=12 cy=13 r=3 → `M9 13a3 3 0 1 0 6 0a3 3 0 1 0-6 0`

**power**
- `M12 2v10`
- `M18.4 6.6a9 9 0 1 1-12.77.04`

**refresh-cw**
- `M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8`
- `M21 3v5h-5`
- `M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16`
- `M8 16H3v5`

**coffee**
- `M10 2v2`
- `M14 2v2`
- `M16 8a1 1 0 0 1 1 1v8a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V9a1 1 0 0 1 1-1h14a4 4 0 1 1 0 8h-1`
- `M6 2v2`

**settings**
- `M9.671 4.136a2.34 2.34 0 0 1 4.659 0 2.34 2.34 0 0 0 3.319 1.915 2.34 2.34 0 0 1 2.33 4.033 2.34 2.34 0 0 0 0 3.831 2.34 2.34 0 0 1-2.33 4.033 2.34 2.34 0 0 0-3.319 1.915 2.34 2.34 0 0 1-4.659 0 2.34 2.34 0 0 0-3.32-1.915 2.34 2.34 0 0 1-2.33-4.033 2.34 2.34 0 0 0 0-3.831A2.34 2.34 0 0 1 6.35 6.051a2.34 2.34 0 0 0 3.319-1.915`
- `[circle]` cx=12 cy=12 r=3 → `M9 12a3 3 0 1 0 6 0a3 3 0 1 0-6 0`

**sun**
- `[circle]` cx=12 cy=12 r=4 → `M8 12a4 4 0 1 0 8 0a4 4 0 1 0-8 0`
- `M12 2v2`
- `M12 20v2`
- `m4.93 4.93 1.41 1.41`
- `m17.66 17.66 1.41 1.41`
- `M2 12h2`
- `M20 12h2`
- `m6.34 17.66-1.41 1.41`
- `m19.07 4.93-1.41 1.41`

**trash-2**
- `M10 11v6`
- `M14 11v6`
- `M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6`
- `M3 6h18`
- `M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2`

### Settings Sidebar

**palette**
- `M12 22a1 1 0 0 1 0-20 10 9 0 0 1 10 9 5 5 0 0 1-5 5h-2.25a1.75 1.75 0 0 0-1.4 2.8l.3.4a1.75 1.75 0 0 1-1.4 2.8z`
- `[circle]` cx=13.5 cy=6.5 r=0.5 → `M13 6.5a.5.5 0 1 0 1 0a.5.5 0 1 0-1 0` `[fill]`
- `[circle]` cx=17.5 cy=10.5 r=0.5 → `M17 10.5a.5.5 0 1 0 1 0a.5.5 0 1 0-1 0` `[fill]`
- `[circle]` cx=6.5 cy=12.5 r=0.5 → `M6 12.5a.5.5 0 1 0 1 0a.5.5 0 1 0-1 0` `[fill]`
- `[circle]` cx=8.5 cy=7.5 r=0.5 → `M8 7.5a.5.5 0 1 0 1 0a.5.5 0 1 0-1 0` `[fill]`

**panel-top**
- `[rect]` x=3 y=3 width=18 height=18 rx=2 → `M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z`
- `M3 9h18`

**rocket**
- `M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5`
- `M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09`
- `M9 12a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.4 22.4 0 0 1-4 2z`
- `M9 12H4s.55-3.03 2-4c1.62-1.08 5 .05 5 .05`

**clipboard**
- `[rect]` x=8 y=2 width=8 height=4 rx=1 ry=1 → `M9 2h6a1 1 0 0 1 1 1v2a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1z`
- `M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2`

**sliders-horizontal**
- `M10 5H3`
- `M12 19H3`
- `M14 3v4`
- `M16 17v4`
- `M21 12h-9`
- `M21 19h-5`
- `M21 5h-7`
- `M8 10v4`
- `M8 12H3`

**calendar**
- `M8 2v4`
- `M16 2v4`
- `[rect]` x=3 y=4 width=18 height=18 rx=2 → `M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z`
- `M3 10h18`

**battery**
- `[rect]` x=2 y=6 width=16 height=12 rx=2 → `M4 6h12a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2z`
- `M22 10v4`

**link**
- `M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71`
- `M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71`

**undo-2**
- `M9 14 4 9l5-5`
- `M4 9h10.5a5.5 5.5 0 0 1 5.5 5.5a5.5 5.5 0 0 1-5.5 5.5H11`

### PowerMenu

**log-out**
- `m16 17 5-5-5-5`
- `M21 12H9`
- `M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4`

**cloud**
- `M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z`

### LockScreen

**check**
- `M20 6 9 17l-5-5`

**x**
- `M18 6 6 18`
- `m6 6 12 12`

**user**
- `M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2`
- `[circle]` cx=12 cy=7 r=4 → `M8 7a4 4 0 1 0 8 0a4 4 0 1 0-8 0`

**eye**
- `M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0`
- `[circle]` cx=12 cy=12 r=3 → `M9 12a3 3 0 1 0 6 0a3 3 0 1 0-6 0`

**eye-off**
- `M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49`
- `M14.084 14.158a3 3 0 0 1-4.242-4.242`
- `M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143`
- `m2 2 20 20`

### OSD

**lock**
- `[rect]` x=3 y=11 width=18 height=11 rx=2 ry=2 → `M5 11h14a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2z`
- `M7 11V7a5 5 0 0 1 10 0v4`

**lock-open**
- `M7 11V7a5 5 0 0 1 9.9-1`
- `[rect]` x=3 y=11 width=18 height=11 rx=2 ry=2 → `M5 11h14a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2z`

**keyboard**
- `M10 8h.01`
- `M12 12h.01`
- `M14 8h.01`
- `M16 12h.01`
- `M18 8h.01`
- `M6 8h.01`
- `M7 16h10`
- `M8 12h.01`
- `[rect]` x=2 y=4 width=20 height=16 rx=2 → `M4 4h16a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2z`

### Popups & Misc

**chevron-left**
- `m15 18-6-6 6-6`

**chevron-right**
- `m9 18 6-6-6-6`

**clock**
- `[circle]` cx=12 cy=12 r=10 → `M2 12a10 10 0 1 0 20 0a10 10 0 1 0-20 0`
- `M12 6v6l4 2`

**image**
- `[rect]` x=3 y=3 width=18 height=18 rx=2 ry=2 → `M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z`
- `[circle]` cx=9 cy=9 r=2 → `M7 9a2 2 0 1 0 4 0a2 2 0 1 0-4 0`
- `m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21`

**circle-alert**
- `[circle]` cx=12 cy=12 r=10 → `M2 12a10 10 0 1 0 20 0a10 10 0 1 0-20 0`
- `[line]` M12 8L12 12
- `[line]` M12 16L12.01 16

**info**
- `[circle]` cx=12 cy=12 r=10 → `M2 12a10 10 0 1 0 20 0a10 10 0 1 0-20 0`
- `M12 16v-4`
- `M12 8h.01`

**skip-back**
- `M17.971 4.285A2 2 0 0 1 21 6v12a2 2 0 0 1-3.029 1.715l-9.997-5.998a2 2 0 0 1-.003-3.432z` `[fill]`
- `M3 20V4`

**skip-forward**
- `M21 4v16`
- `M6.029 4.285A2 2 0 0 0 3 6v12a2 2 0 0 0 3.029 1.715l9.997-5.998a2 2 0 0 0 .003-3.432z` `[fill]`

**plus**
- `M5 12h14`
- `M12 5v14`

**unlink**
- `m18.84 12.25 1.72-1.71h-.02a5.004 5.004 0 0 0-.12-7.07 5.006 5.006 0 0 0-6.95 0l-1.72 1.71`
- `m5.17 11.75-1.71 1.71a5.004 5.004 0 0 0 .12 7.07 5.006 5.006 0 0 0 6.95 0l1.71-1.71`
- `[line]` M8 2L8 5
- `[line]` M2 8L5 8
- `[line]` M16 19L16 22
- `[line]` M19 16L22 16

---

## File Structure

### New files
- `quickshell/icons/qmldir` — module registration
- `quickshell/icons/IconBell.qml` — and 42 other icon components (see inventory above)
- `quickshell/settings/IconGalleryPage.qml` — icon gallery preview page

### Modified files
- `quickshell/bar/NotificationBell.qml` — replace nerd font bell icon
- `quickshell/bar/Bluetooth.qml` — replace nerd font bluetooth icons
- `quickshell/bar/NetworkStatus.qml` — replace nerd font wifi/ethernet/alert icons
- `quickshell/bar/Volume.qml` — replace nerd font volume icons
- `quickshell/bar/MediaPlayer.qml` — replace nerd font play/pause icons
- `quickshell/bar/Battery.qml` — replace charging bolt icon
- `quickshell/NotificationCenter.qml` — replace all quick toggle + control icons
- `quickshell/Settings.qml` — replace sidebar icons, header icon, reset icons
- `quickshell/PowerMenu.qml` — replace action icons
- `quickshell/LockScreen.qml` — replace status + password toggle icons
- `quickshell/OSD.qml` — replace volume/brightness/caps/num icons
- `quickshell/popups/ClockPopup.qml` — replace chevron + clock icons
- `quickshell/popups/MediaPopup.qml` — replace skip/play/pause icons
- `quickshell/NotificationPopup.qml` — replace urgency + close icons
- `quickshell/ClipboardHistory.qml` — replace image icon
- `quickshell/settings/LauncherPage.qml` — replace close + add icons
- `quickshell/settings/qmldir` — add IconGalleryPage
- `quickshell/settings/AppearancePage.qml` — update icon font settings UI

---

## Task 1: Create icon infrastructure and stroke-only icons

**Files:**
- Create: `quickshell/icons/qmldir`
- Create: `quickshell/icons/IconBell.qml`
- Create: `quickshell/icons/IconBellOff.qml`
- Create: `quickshell/icons/IconBluetooth.qml`
- Create: `quickshell/icons/IconBluetoothOff.qml`
- Create: `quickshell/icons/IconBluetoothConnected.qml`
- Create: `quickshell/icons/IconWifi.qml`
- Create: `quickshell/icons/IconEthernet.qml`
- Create: `quickshell/icons/IconTriangleAlert.qml`
- Create: `quickshell/icons/IconVolume2.qml`
- Create: `quickshell/icons/IconVolume1.qml`
- Create: `quickshell/icons/IconVolume.qml`
- Create: `quickshell/icons/IconVolumeX.qml`
- Create: `quickshell/icons/IconMoon.qml`
- Create: `quickshell/icons/IconPower.qml`
- Create: `quickshell/icons/IconRefreshCw.qml`
- Create: `quickshell/icons/IconCoffee.qml`
- Create: `quickshell/icons/IconLink.qml`
- Create: `quickshell/icons/IconUnlink.qml`
- Create: `quickshell/icons/IconChevronLeft.qml`
- Create: `quickshell/icons/IconChevronRight.qml`
- Create: `quickshell/icons/IconCheck.qml`
- Create: `quickshell/icons/IconX.qml`
- Create: `quickshell/icons/IconPlus.qml`
- Create: `quickshell/icons/IconLogOut.qml`
- Create: `quickshell/icons/IconCloud.qml`
- Create: `quickshell/icons/IconRocket.qml`
- Create: `quickshell/icons/IconUndo.qml`
- Create: `quickshell/icons/IconLockOpen.qml`

All icons in this task are pure stroke icons (no fills, circles, or rects to convert).

- [ ] **Step 1: Create `quickshell/icons/` directory**

```bash
mkdir -p quickshell/icons
```

- [ ] **Step 2: Create stroke-only icon components**

Each icon follows this template — create one file per icon using the path data from the reference above:

```qml
// Example: quickshell/icons/IconWifi.qml
import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property real size: 24
    property color color: "#ffffff"
    property real strokeWidth: Math.max(1, size / 12)
    width: size; height: size
    clip: false
    layer.enabled: visible; layer.smooth: true

    ShapePath {
        strokeColor: root.color; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M12 20h.01" }
    }
    ShapePath {
        strokeColor: root.color; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M2 8.82a15 15 0 0 1 20 0" }
    }
    ShapePath {
        strokeColor: root.color; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M5 12.859a10 10 0 0 1 14 0" }
    }
    ShapePath {
        strokeColor: root.color; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M8.5 16.429a5 5 0 0 1 7 0" }
    }
}
```

Create all 29 stroke-only icons listed above using their respective path data from the reference section. Each `ShapePath` gets one path from the reference. Every ShapePath uses the same boilerplate properties (strokeColor, strokeWidth, fillColor, capStyle, joinStyle, scale).

- [ ] **Step 3: Commit**

```bash
git add quickshell/icons/
git commit -m "feat(icons): add stroke-only Lucide icon components (29 icons)"
```

---

## Task 2: Create icons with fills, circles, and rects

**Files:**
- Create: `quickshell/icons/IconPlay.qml`
- Create: `quickshell/icons/IconPause.qml`
- Create: `quickshell/icons/IconZap.qml`
- Create: `quickshell/icons/IconSkipBack.qml`
- Create: `quickshell/icons/IconSkipForward.qml`
- Create: `quickshell/icons/IconCamera.qml`
- Create: `quickshell/icons/IconSettings.qml`
- Create: `quickshell/icons/IconSun.qml`
- Create: `quickshell/icons/IconTrash.qml`
- Create: `quickshell/icons/IconPalette.qml`
- Create: `quickshell/icons/IconPanelTop.qml`
- Create: `quickshell/icons/IconClipboard.qml`
- Create: `quickshell/icons/IconSlidersH.qml`
- Create: `quickshell/icons/IconCalendar.qml`
- Create: `quickshell/icons/IconBattery.qml`
- Create: `quickshell/icons/IconUser.qml`
- Create: `quickshell/icons/IconEye.qml`
- Create: `quickshell/icons/IconEyeOff.qml`
- Create: `quickshell/icons/IconLock.qml`
- Create: `quickshell/icons/IconKeyboard.qml`
- Create: `quickshell/icons/IconClock.qml`
- Create: `quickshell/icons/IconImage.qml`
- Create: `quickshell/icons/IconAlertCircle.qml`
- Create: `quickshell/icons/IconInfo.qml`

Icons in this task require special handling for fills, circles, or rects.

- [ ] **Step 1: Create filled icon components**

For filled icons (play, zap, skip-back triangle, skip-forward triangle), the ShapePath uses `fillColor: root.color` and `strokeColor: "transparent"`:

```qml
// Example: quickshell/icons/IconPlay.qml
import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property real size: 24
    property color color: "#ffffff"
    property real strokeWidth: Math.max(1, size / 12)
    width: size; height: size
    clip: false
    layer.enabled: visible; layer.smooth: true

    ShapePath {
        fillColor: root.color; strokeColor: "transparent"
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M5 5a2 2 0 0 1 3.008-1.728l11.997 6.998a2 2 0 0 1 .003 3.458l-12 7A2 2 0 0 1 5 19z" }
    }
}
```

For mixed icons (skip-back, skip-forward) that have both filled and stroked paths, use separate ShapePaths — filled for the triangle, stroked for the line:

```qml
// Example: quickshell/icons/IconSkipBack.qml
import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property real size: 24
    property color color: "#ffffff"
    property real strokeWidth: Math.max(1, size / 12)
    width: size; height: size
    clip: false
    layer.enabled: visible; layer.smooth: true

    ShapePath {
        fillColor: root.color; strokeColor: "transparent"
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M17.971 4.285A2 2 0 0 1 21 6v12a2 2 0 0 1-3.029 1.715l-9.997-5.998a2 2 0 0 1-.003-3.432z" }
    }
    ShapePath {
        strokeColor: root.color; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M3 20V4" }
    }
}
```

- [ ] **Step 2: Create icons with converted circles and rects**

For icons containing `<circle>` or `<rect>` SVG elements, use the converted path data from the reference section. Circle-based ShapePaths that represent dots (like palette color dots) use `fillColor: root.color`. Rect-based ShapePaths for outlines use stroke.

```qml
// Example: quickshell/icons/IconCamera.qml
import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property real size: 24
    property color color: "#ffffff"
    property real strokeWidth: Math.max(1, size / 12)
    width: size; height: size
    clip: false
    layer.enabled: visible; layer.smooth: true

    ShapePath {
        strokeColor: root.color; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M13.997 4a2 2 0 0 1 1.76 1.05l.486.9A2 2 0 0 0 18.003 7H20a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1.997a2 2 0 0 0 1.759-1.048l.489-.904A2 2 0 0 1 10.004 4z" }
    }
    // circle cx=12 cy=13 r=3 converted to arc path
    ShapePath {
        strokeColor: root.color; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M9 13a3 3 0 1 0 6 0a3 3 0 1 0-6 0" }
    }
}
```

Create all 24 icons listed above using the converted path data from the reference. For `IconPause`, use the rect-to-path conversions. For `IconPalette`, the small circle dots use `fillColor: root.color` with `strokeColor: "transparent"`.

- [ ] **Step 3: Commit**

```bash
git add quickshell/icons/
git commit -m "feat(icons): add filled/circle/rect Lucide icon components (24 icons)"
```

---

## Task 3: Create qmldir and IconGallery page

**Files:**
- Create: `quickshell/icons/qmldir`
- Create: `quickshell/settings/IconGalleryPage.qml`
- Modify: `quickshell/settings/qmldir`
- Modify: `quickshell/Settings.qml:34-48` (pages array)

- [ ] **Step 1: Create `quickshell/icons/qmldir`**

List every icon component created in Tasks 1 and 2. Use `1.0` versioning:

```
module Icons

IconAlertCircle 1.0 IconAlertCircle.qml
IconBattery 1.0 IconBattery.qml
IconBell 1.0 IconBell.qml
IconBellOff 1.0 IconBellOff.qml
IconBluetooth 1.0 IconBluetooth.qml
IconBluetoothConnected 1.0 IconBluetoothConnected.qml
IconBluetoothOff 1.0 IconBluetoothOff.qml
IconCalendar 1.0 IconCalendar.qml
IconCamera 1.0 IconCamera.qml
IconCheck 1.0 IconCheck.qml
IconChevronLeft 1.0 IconChevronLeft.qml
IconChevronRight 1.0 IconChevronRight.qml
IconClipboard 1.0 IconClipboard.qml
IconClock 1.0 IconClock.qml
IconCloud 1.0 IconCloud.qml
IconCoffee 1.0 IconCoffee.qml
IconEthernet 1.0 IconEthernet.qml
IconEye 1.0 IconEye.qml
IconEyeOff 1.0 IconEyeOff.qml
IconImage 1.0 IconImage.qml
IconInfo 1.0 IconInfo.qml
IconKeyboard 1.0 IconKeyboard.qml
IconLink 1.0 IconLink.qml
IconLock 1.0 IconLock.qml
IconLockOpen 1.0 IconLockOpen.qml
IconLogOut 1.0 IconLogOut.qml
IconMoon 1.0 IconMoon.qml
IconPalette 1.0 IconPalette.qml
IconPanelTop 1.0 IconPanelTop.qml
IconPause 1.0 IconPause.qml
IconPlay 1.0 IconPlay.qml
IconPlus 1.0 IconPlus.qml
IconPower 1.0 IconPower.qml
IconRefreshCw 1.0 IconRefreshCw.qml
IconRocket 1.0 IconRocket.qml
IconSettings 1.0 IconSettings.qml
IconSkipBack 1.0 IconSkipBack.qml
IconSkipForward 1.0 IconSkipForward.qml
IconSlidersH 1.0 IconSlidersH.qml
IconSun 1.0 IconSun.qml
IconTrash 1.0 IconTrash.qml
IconTriangleAlert 1.0 IconTriangleAlert.qml
IconUndo 1.0 IconUndo.qml
IconUnlink 1.0 IconUnlink.qml
IconUser 1.0 IconUser.qml
IconVolume 1.0 IconVolume.qml
IconVolume1 1.0 IconVolume1.qml
IconVolume2 1.0 IconVolume2.qml
IconVolumeX 1.0 IconVolumeX.qml
IconWifi 1.0 IconWifi.qml
IconX 1.0 IconX.qml
```

- [ ] **Step 2: Create IconGalleryPage.qml**

Create `quickshell/settings/IconGalleryPage.qml`:

```qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../icons"
import ".."

Item {
    id: root

    // Icon names — Loader constructs path as "../icons/Icon" + name + ".qml"
    property var iconNames: [
        "AlertCircle", "Battery", "Bell", "BellOff", "Bluetooth",
        "BluetoothConnected", "BluetoothOff", "Calendar", "Camera",
        "Check", "ChevronLeft", "ChevronRight", "Clipboard", "Clock",
        "Cloud", "Coffee", "Ethernet", "Eye", "EyeOff", "Image",
        "Info", "Keyboard", "Link", "Lock", "LockOpen", "LogOut",
        "Moon", "Palette", "PanelTop", "Pause", "Play", "Plus",
        "Power", "RefreshCw", "Rocket", "Settings", "SkipBack",
        "SkipForward", "SlidersH", "Sun", "Trash", "TriangleAlert",
        "Undo", "Unlink", "User", "Volume", "Volume1", "Volume2",
        "VolumeX", "Wifi", "X"
    ]

    property real iconSize: 24
    property color iconColor: Config.text
    property string searchText: ""

    property var filteredIcons: {
        if (!searchText) return iconNames;
        let s = searchText.toLowerCase();
        return iconNames.filter(n => n.toLowerCase().includes(s));
    }

    property var colorOptions: [
        { name: "Text", color: Config.text },
        { name: "Subtext", color: Config.subtext0 },
        { name: "Blue", color: Config.blue },
        { name: "Red", color: Config.red },
        { name: "Green", color: Config.green },
        { name: "Yellow", color: Config.yellow },
        { name: "Mauve", color: Config.mauve },
        { name: "Peach", color: Config.peach },
        { name: "Teal", color: Config.teal }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Search bar
        Rectangle {
            Layout.fillWidth: true; height: 32; radius: 6
            color: Config.surface0
            TextInput {
                anchors.fill: parent; anchors.margins: 8
                color: Config.text; font.pixelSize: 12; font.family: Config.fontFamily
                onTextChanged: root.searchText = text
                Text {
                    visible: !parent.text
                    text: "Search icons..."; color: Config.overlay0
                    font.pixelSize: 12; font.family: Config.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Size buttons (no QtQuick.Controls dependency)
        Row {
            spacing: 6
            Text { text: "Size:"; color: Config.text; font.pixelSize: 12; font.family: Config.fontFamily; anchors.verticalCenter: parent.verticalCenter }
            Repeater {
                model: [12, 16, 20, 24, 32, 48]
                Rectangle {
                    required property int modelData
                    width: 32; height: 24; radius: 4
                    color: root.iconSize === modelData ? Config.blue : Config.surface0
                    Text {
                        anchors.centerIn: parent; text: parent.modelData
                        color: root.iconSize === parent.modelData ? Config.crust : Config.text
                        font.pixelSize: 10; font.family: Config.fontFamily
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.iconSize = parent.modelData
                    }
                }
            }
        }

        // Color picker row
        Row {
            spacing: 6
            Repeater {
                model: root.colorOptions
                Rectangle {
                    required property var modelData
                    width: 24; height: 24; radius: 12
                    color: modelData.color
                    border.width: root.iconColor === modelData.color ? 2 : 0
                    border.color: Config.text
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.iconColor = parent.modelData.color
                    }
                }
            }
        }

        // Icon grid
        GridView {
            Layout.fillWidth: true; Layout.fillHeight: true
            cellWidth: Math.max(80, root.iconSize + 40)
            cellHeight: root.iconSize + 50
            clip: true
            model: root.filteredIcons

            delegate: Item {
                required property string modelData
                width: GridView.view.cellWidth
                height: GridView.view.cellHeight

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Loader {
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: "../icons/Icon" + modelData + ".qml"
                        onLoaded: {
                            item.size = Qt.binding(() => root.iconSize);
                            item.color = Qt.binding(() => root.iconColor);
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData
                        color: Config.subtext0
                        font.pixelSize: 9; font.family: Config.fontFamily
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 3: Register IconGalleryPage in settings/qmldir**

Add to `quickshell/settings/qmldir`:
```
IconGalleryPage 1.0 IconGalleryPage.qml
```

- [ ] **Step 4: Add Icon Gallery to Settings sidebar**

In `quickshell/Settings.qml`, add to the `pages` array (after the Integrations entry):
```qml
{ name: "Icon Gallery", icon: "\uf03e", section: "icons" }
```

And add the corresponding page component in the Loader/StackLayout section that renders settings pages.

- [ ] **Step 5: Verify icons render by opening Settings → Icon Gallery**

Run quickshell, open Settings, navigate to Icon Gallery. Verify all 43+ icons render correctly at different sizes and colors.

- [ ] **Step 6: Commit**

```bash
git add quickshell/icons/qmldir quickshell/settings/IconGalleryPage.qml quickshell/settings/qmldir quickshell/Settings.qml
git commit -m "feat(icons): add qmldir and Icon Gallery settings page"
```

---

## Task 4: Migrate bar components

**Files:**
- Modify: `quickshell/bar/NotificationBell.qml:22-30`
- Modify: `quickshell/bar/Bluetooth.qml:27-53`
- Modify: `quickshell/bar/NetworkStatus.qml:18-24`
- Modify: `quickshell/bar/Volume.qml:24-48`
- Modify: `quickshell/bar/MediaPlayer.qml:38-42`
- Modify: `quickshell/bar/Battery.qml:107-115`

- [ ] **Step 1: Migrate NotificationBell.qml**

Add `import "../icons"` at the top. Replace the icon Text element (lines 22-30) with stacked icons:

```qml
// Before:
// Text { text: root.unreadCount > 0 ? "\uf0f3" : "\uf0a2"; ... }

// After:
Item {
    width: Theme.fontSizeIcon; height: Theme.fontSizeIcon
    anchors.centerIn: parent
    IconBell {
        visible: root.unreadCount > 0
        size: Theme.fontSizeIcon; color: bellColor
        anchors.centerIn: parent
        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
    }
    IconBellOff {
        visible: root.unreadCount <= 0
        size: Theme.fontSizeIcon; color: bellColor
        anchors.centerIn: parent
        Behavior on color { ColorAnimation { duration: Theme.animDuration } }
    }
}
```

Where `bellColor` replaces the inline color ternary: `property color bellColor: root.unreadCount > 0 ? Theme.peach : Theme.text`.

- [ ] **Step 2: Migrate Bluetooth.qml**

Add `import "../icons"` at the top. Replace the icon property + Text with stacked icons:

```qml
// Remove: property string icon: { ... }
// Replace Text { text: root.icon; ... } with:

Item {
    width: Theme.fontSizeIcon; height: Theme.fontSizeIcon
    anchors.centerIn: parent
    IconBluetooth {
        visible: !root.connected
        size: Theme.fontSizeIcon; color: root.iconColor
        anchors.centerIn: parent
    }
    IconBluetoothConnected {
        visible: root.connected
        size: Theme.fontSizeIcon; color: root.iconColor
        anchors.centerIn: parent
    }
    Behavior on iconColor { ColorAnimation { duration: Theme.animDuration } }
}
```

Keep the existing `iconColor` property as-is (it handles powered/connected states).

- [ ] **Step 3: Migrate NetworkStatus.qml**

Add `import "../icons"` at the top. Replace the icon text with stacked icons:

```qml
Item {
    width: Theme.fontSizeIcon; height: Theme.fontSizeIcon
    anchors.centerIn: parent
    IconWifi { visible: root.connectionType === "wifi"; size: Theme.fontSizeIcon; color: Theme.text; anchors.centerIn: parent }
    IconEthernet { visible: root.connectionType === "ethernet"; size: Theme.fontSizeIcon; color: Theme.text; anchors.centerIn: parent }
    IconTriangleAlert { visible: root.connectionType === "none"; size: Theme.fontSizeIcon; color: Theme.red; anchors.centerIn: parent }
}
```

- [ ] **Step 4: Migrate Volume.qml**

Add `import "../icons"` at the top. Remove the `property string icon` block. Replace the Text element (lines 38-48) with:

```qml
Item {
    width: Theme.fontSizeIcon; height: Theme.fontSizeIcon
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Theme.widgetPadding / 2

    IconVolumeX { visible: root.muted; size: Theme.fontSizeIcon; color: volColor; anchors.centerIn: parent }
    IconVolume2 { visible: !root.muted && root.volume > 0.66; size: Theme.fontSizeIcon; color: volColor; anchors.centerIn: parent }
    IconVolume1 { visible: !root.muted && root.volume > 0.33 && root.volume <= 0.66; size: Theme.fontSizeIcon; color: volColor; anchors.centerIn: parent }
    IconVolume { visible: !root.muted && root.volume <= 0.33; size: Theme.fontSizeIcon; color: volColor; anchors.centerIn: parent }

    property color volColor: root.muted ? Theme.red : Theme.blue
    Behavior on volColor { ColorAnimation { duration: Theme.animDuration } }
}
```

- [ ] **Step 5: Migrate MediaPlayer.qml**

Add `import "../icons"` at the top. Replace the play/pause Text with:

```qml
Item {
    width: 12; height: 12
    anchors.centerIn: parent
    IconPlay { visible: !root.isPlaying; size: 12; color: Theme.text; anchors.centerIn: parent }
    IconPause { visible: root.isPlaying; size: 12; color: Theme.text; anchors.centerIn: parent }
}
```

Adapt the size and property names to match the actual code — read the file first.

- [ ] **Step 6: Migrate Battery.qml charging bolt**

Add `import "../icons"` at the top. Replace the charging bolt Text (lines 107-115):

```qml
// Before:
// Text { text: "\uf0e7"; font.family: Config.iconFont; ... }

// After:
IconZap {
    anchors.centerIn: batBody
    size: 8; color: root.percentage > 50 ? Theme.crust : Theme.text
    visible: root.charging
}
```

- [ ] **Step 7: Test visually**

Run quickshell and verify all bar icons render correctly. Check: volume changes, bluetooth states, wifi/ethernet, notification bell, battery charging, media player.

- [ ] **Step 8: Commit**

```bash
git add quickshell/bar/
git commit -m "feat(icons): migrate bar components to Lucide icons"
```

---

## Task 5: Migrate NotificationCenter

**Files:**
- Modify: `quickshell/NotificationCenter.qml`

This file has ~13 quick toggle icons, volume/mute icon, brightness icon, notification header icon, trash icon, and notification dismiss icons.

- [ ] **Step 1: Read NotificationCenter.qml fully**

Understand all icon usages and their surrounding layout structures before making changes.

- [ ] **Step 2: Add import and replace all icon Text elements**

Add `import "icons"` at the top.

For each quick toggle icon, replace. Note: `\uf1f6` (bell-slash / DND toggle) maps to `IconBellOff` — the Lucide bell-off icon has a diagonal slash which matches DND semantics. Replace:
```qml
// Before:
Text { text: "\uf1eb"; color: ...; font.pixelSize: ...; font.family: Theme.iconFont }

// After:
IconWifi { size: ...; color: ... }
```

For the volume/mute toggle, use stacked icons like Volume.qml migration.

For the brightness sun icon, replace with `IconSun`.

For notification header bell, replace with `IconBell`.

For trash/clear, replace with `IconTrash`.

For dismiss X buttons, replace with `IconX`.

Preserve all existing color bindings, Behavior animations, and anchoring.

- [ ] **Step 3: Test visually**

Open the notification center panel. Verify all quick toggles render, toggle states work, volume/brightness controls show correct icons, notifications render properly.

- [ ] **Step 4: Commit**

```bash
git add quickshell/NotificationCenter.qml
git commit -m "feat(icons): migrate NotificationCenter to Lucide icons"
```

---

## Task 6: Migrate Settings.qml

**Files:**
- Modify: `quickshell/Settings.qml:34-48,149,192-207,234,299`

Settings.qml has three icon patterns: sidebar page icons (ListModel), header text+icon inline, and reset buttons.

- [ ] **Step 1: Read Settings.qml fully to understand current structure**

- [ ] **Step 2: Migrate sidebar pages array**

Add `import "icons"` at the top. Change the pages array to use component source paths instead of unicode strings:

```qml
property var pages: [
    { name: "Appearance", iconSource: "icons/IconPalette.qml", section: "appearance" },
    { name: "Bar", iconSource: "icons/IconPanelTop.qml", section: "bar" },
    { name: "Notifications", iconSource: "icons/IconBell.qml", section: "notifications" },
    { name: "Launcher", iconSource: "icons/IconRocket.qml", section: "launcher" },
    { name: "Clipboard", iconSource: "icons/IconClipboard.qml", section: "clipboard" },
    { name: "OSD", iconSource: "icons/IconSlidersH.qml", section: "osd" },
    { name: "Animations", iconSource: "icons/IconRefreshCw.qml", section: "animations" },
    { name: "Network", iconSource: "icons/IconWifi.qml", section: "network" },
    { name: "Calendar", iconSource: "icons/IconCalendar.qml", section: "calendar" },
    { name: "Battery", iconSource: "icons/IconBattery.qml", section: "battery" },
    { name: "Lock Screen", iconSource: "icons/IconLock.qml", section: "lockscreen" },
    { name: "Power & Idle", iconSource: "icons/IconZap.qml", section: "idle" },
    { name: "Integrations", iconSource: "icons/IconLink.qml", section: "hyprland" },
    { name: "Icon Gallery", iconSource: "icons/IconImage.qml", section: "icons" }
]
```

- [ ] **Step 3: Update sidebar icon rendering**

Replace the icon Text element in the sidebar delegate (around lines 192-200). Note: capture `index` in a `required property int index` on the delegate to ensure it's in scope for bindings:

```qml
// Before:
Text {
    text: modelData.icon
    color: root.activePage === index ? Config.blue : Config.overlay0
    font.pixelSize: 14; font.family: Config.iconFont
    anchors.verticalCenter: parent.verticalCenter
}

// After:
// Ensure delegate has: required property int index
Loader {
    id: sidebarIconLoader
    property int pageIndex: index  // capture delegate index
    source: modelData.iconSource
    anchors.verticalCenter: parent.verticalCenter
    onLoaded: {
        item.size = 14;
        item.color = Qt.binding(() => root.activePage === sidebarIconLoader.pageIndex ? Config.blue : Config.overlay0);
    }
}
```

- [ ] **Step 4: Migrate header icon**

Replace the inline text+icon pattern (around line 149):

```qml
// Before:
text: "\uf013  Settings"

// After (restructure to Row — transfer any Layout.* properties from the old Text to the Row):
Row {
    Layout.leftMargin: 12; Layout.bottomMargin: 12  // preserve existing Layout properties
    spacing: 6
    // Note: do NOT use anchors.verticalCenter inside Row children — Row handles positioning
    IconSettings { size: 16; color: Config.text }
    Text { text: "Settings"; color: Config.text; font.pixelSize: 14; font.family: Config.fontFamily; font.bold: true }
}
```

- [ ] **Step 5: Migrate reset button icons**

Replace the reset icon Text elements (lines ~234, ~299):

```qml
// Before:
Text { text: "\uf2ea"; ... }

// After:
IconUndo { size: 12; color: ... }
```

- [ ] **Step 6: Add IconGallery page to the page rendering section**

In the StackLayout or Loader that renders pages based on `activePage`, add the IconGalleryPage case.

- [ ] **Step 7: Test visually**

Open Settings. Verify sidebar icons render correctly, active page highlighting works, reset buttons show undo icon, Icon Gallery page loads and works.

- [ ] **Step 8: Commit**

```bash
git add quickshell/Settings.qml
git commit -m "feat(icons): migrate Settings sidebar/header/reset to Lucide icons"
```

---

## Task 7: Migrate PowerMenu.qml

**Files:**
- Modify: `quickshell/PowerMenu.qml:32-39,277-284`

- [ ] **Step 1: Read PowerMenu.qml fully**

- [ ] **Step 2: Migrate actions array and icon rendering**

Add `import "icons"` at the top. Change actions array to use component sources:

```qml
property var actions: [
    { name: "Lock", iconSource: "icons/IconLock.qml", color: Theme.blue },
    { name: "Logout", iconSource: "icons/IconLogOut.qml", color: Theme.yellow },
    { name: "Suspend", iconSource: "icons/IconMoon.qml", color: Theme.mauve },
    { name: "Hibernate", iconSource: "icons/IconCloud.qml", color: Theme.teal },
    { name: "Reboot", iconSource: "icons/IconRefreshCw.qml", color: Theme.peach },
    { name: "Shutdown", iconSource: "icons/IconPower.qml", color: Theme.red }
]
```

Replace the icon Text element in the action card delegate. Capture `isSelected` and `modelData.color` on the Loader to avoid scope issues:

```qml
// Before:
Text { text: modelData.icon; color: ...; font.pixelSize: 18; font.family: Config.iconFont; Behavior on color { ... } }

// After:
Loader {
    id: actionIconLoader
    property bool selected: actionCard.isSelected
    property color defaultColor: modelData.color
    anchors.centerIn: parent
    source: modelData.iconSource
    onLoaded: {
        item.size = 18;
        item.color = Qt.binding(() => actionIconLoader.selected ? Theme.crust : actionIconLoader.defaultColor);
    }
}
```

Also update the title area if it has `\uf011` (power icon) — replace with `IconPower`.

- [ ] **Step 3: Test visually**

Open power menu. Verify all 6 action icons render, hover/selection color changes work.

- [ ] **Step 4: Commit**

```bash
git add quickshell/PowerMenu.qml
git commit -m "feat(icons): migrate PowerMenu to Lucide icons"
```

---

## Task 8: Migrate LockScreen.qml

**Files:**
- Modify: `quickshell/LockScreen.qml`

- [ ] **Step 1: Read LockScreen.qml fully**

Locate the status icons (check/x/user at ~lines 222-224) and eye/eye-off toggle (~line 394).

- [ ] **Step 2: Add import and replace icons**

Add `import "icons"` at the top.

Replace status icon (lines ~222-224) — this is likely a conditional:
```qml
// Stacked approach:
Item {
    width: statusSize; height: statusSize
    IconCheck { visible: status === "success"; size: statusSize; color: Theme.green; anchors.centerIn: parent }
    IconX { visible: status === "error"; size: statusSize; color: Theme.red; anchors.centerIn: parent }
    IconUser { visible: status === "idle"; size: statusSize; color: Theme.text; anchors.centerIn: parent }
}
```

Replace eye/eye-off toggle:
```qml
Item {
    width: 16; height: 16
    IconEye { visible: showPassword; size: 16; color: Theme.text; anchors.centerIn: parent }
    IconEyeOff { visible: !showPassword; size: 16; color: Theme.text; anchors.centerIn: parent }
}
```

Adapt sizes and property names to match the actual code.

- [ ] **Step 3: Test visually**

Lock screen → verify user icon shows, password field eye toggle works, success/error states display correctly.

- [ ] **Step 4: Commit**

```bash
git add quickshell/LockScreen.qml
git commit -m "feat(icons): migrate LockScreen to Lucide icons"
```

---

## Task 9: Migrate OSD.qml

**Files:**
- Modify: `quickshell/OSD.qml:128-143,221`

- [ ] **Step 1: Read OSD.qml fully**

Understand the `getIcon()` function and how it's consumed.

- [ ] **Step 2: Replace getIcon text rendering with stacked icon components**

Add `import "icons"` at the top. Replace the icon Text element (~line 221) with stacked icons driven by osdType and osdValue:

```qml
// Remove getIcon() function
// Replace Text { text: root.getIcon(); ... } with:

Item {
    width: 16; height: 16
    anchors.verticalCenter: parent.verticalCenter

    // Volume icons
    IconVolumeX { visible: osdType === "volume" && osdBool; size: 16; color: root.getColor(); anchors.centerIn: parent }
    IconVolume2 { visible: osdType === "volume" && !osdBool && osdValue > 0.66; size: 16; color: root.getColor(); anchors.centerIn: parent }
    IconVolume1 { visible: osdType === "volume" && !osdBool && osdValue > 0.33 && osdValue <= 0.66; size: 16; color: root.getColor(); anchors.centerIn: parent }
    IconVolume { visible: osdType === "volume" && !osdBool && osdValue <= 0.33; size: 16; color: root.getColor(); anchors.centerIn: parent }

    // Brightness icon
    IconSun { visible: osdType === "brightness"; size: 16; color: root.getColor(); anchors.centerIn: parent }

    // Caps lock icons
    IconLock { visible: osdType === "capslock" && osdBool; size: 16; color: root.getColor(); anchors.centerIn: parent }
    IconLockOpen { visible: osdType === "capslock" && !osdBool; size: 16; color: root.getColor(); anchors.centerIn: parent }

    // Num lock icon
    IconKeyboard { visible: osdType === "numlock"; size: 16; color: root.getColor(); anchors.centerIn: parent }
}
```

Keep `getColor()` and `getLabel()` functions as-is.

- [ ] **Step 3: Test visually**

Change volume, brightness, toggle caps/num lock. Verify OSD popup shows correct icons.

- [ ] **Step 4: Commit**

```bash
git add quickshell/OSD.qml
git commit -m "feat(icons): migrate OSD to Lucide icons"
```

---

## Task 10: Migrate popups and misc

**Files:**
- Modify: `quickshell/popups/ClockPopup.qml`
- Modify: `quickshell/popups/MediaPopup.qml`
- Modify: `quickshell/NotificationPopup.qml`
- Modify: `quickshell/ClipboardHistory.qml`
- Modify: `quickshell/settings/LauncherPage.qml`

- [ ] **Step 1: Migrate ClockPopup.qml**

Add `import "../icons"`. Replace:
- Chevron left/right (`\uf053`, `\uf054`) → `IconChevronLeft`, `IconChevronRight`
- Clock icon (`\uf017`) → `IconClock`

- [ ] **Step 2: Migrate MediaPopup.qml**

Add `import "../icons"`. Replace:
- Skip back (`\uf048`) → `IconSkipBack`
- Play/pause (`\uf04b`/`\uf04c`) → stacked `IconPlay`/`IconPause` with visible bindings
- Skip forward (`\uf051`) → `IconSkipForward`

- [ ] **Step 3: Migrate NotificationPopup.qml**

Add `import "icons"`. Replace:
- Urgency icons (`\uf06a`, `\uf05a`, `\uf0f3`) → `IconAlertCircle`, `IconInfo`, `IconBell` (stacked with visible based on urgency)
- Close button (`\uf00d`) → `IconX`

- [ ] **Step 4: Migrate ClipboardHistory.qml**

Add `import "icons"`. Replace:
- Image icon (`\uf03e  Image`) → Row with `IconImage` + Text "Image"

- [ ] **Step 5: Migrate LauncherPage.qml**

Add `import "../icons"`. Replace:
- Close button (`\uf00d`) → `IconX`
- Add button (`\uf067`) → `IconPlus`

- [ ] **Step 6: Test visually**

Test clock popup navigation, media controls, notification toasts at different urgencies, clipboard panel with image items, launcher settings page add/remove.

- [ ] **Step 7: Commit**

```bash
git add quickshell/popups/ quickshell/NotificationPopup.qml quickshell/ClipboardHistory.qml quickshell/settings/LauncherPage.qml
git commit -m "feat(icons): migrate popups, notifications, clipboard, launcher to Lucide icons"
```

---

## Task 11: Migrate StatusBar.qml remaining icons

**Files:**
- Modify: `quickshell/StatusBar.qml`

StatusBar has icons at lines: 424, 450, 532, 591, 687, 724, 862, 949, 1087 — chevrons, refresh, wifi, link, bluetooth in the expanded panel sections.

- [ ] **Step 1: Read StatusBar.qml and identify all icon Text elements**

- [ ] **Step 2: Add import and replace all icons**

Add `import "icons"` at the top. Replace each icon:
- `\uf053` / `\uf054` → `IconChevronLeft` / `IconChevronRight`
- `\uf2f1` → `IconRefreshCw`
- `\uf1eb` → `IconWifi`
- `\uf0c1` → `IconLink`
- `\uf293` → `IconBluetooth`

For each replacement, match the existing size (font.pixelSize), color, and anchoring. The StatusBar uses `Theme.iconFont` and various sizes (10-14px).

- [ ] **Step 3: Test visually**

Open StatusBar panels (wifi, bluetooth). Verify chevron navigation, rescan spinner, connection/link icons.

- [ ] **Step 4: Commit**

```bash
git add quickshell/StatusBar.qml
git commit -m "feat(icons): migrate StatusBar panel icons to Lucide icons"
```

---

## Task 12: Post-migration cleanup

**Files:**
- Modify: `quickshell/Config.qml`
- Modify: `quickshell/Theme.qml`
- Modify: `quickshell/settings/AppearancePage.qml`
- Modify: `tasks.md`

- [ ] **Step 1: Check for remaining iconFont usages**

Search the entire `quickshell/` directory for remaining `iconFont` and nerd font unicode references. Expected remaining usages:
- `IntegrationsPage.qml` (tmux preview — excluded from migration, uses `Config.fontFamily` which is "Maple Mono NF", a nerd font)
- `shell.qml` (binds `Quill.Theme.iconFont = Qt.binding(() => Config.iconFont)` — check if Quill theme system still needs this)

```bash
grep -r "iconFont\|\\\\uf\|font.family.*icon" quickshell/ --include="*.qml"
```

- [ ] **Step 2: Clean up Config/Theme icon font properties**

If `iconFont` is only used by IntegrationsPage.qml and shell.qml's Quill binding, keep it but add a comment noting it's only for legacy nerd font usages. Note that `Config.fontFamily` ("Maple Mono NF") is itself a nerd font, so IntegrationsPage tmux preview icons will keep working regardless.

If `fontSizeIcon` exists, consider keeping it as the default icon size for components.

Also check `shell.qml` for the `Quill.Theme.iconFont` binding — update or remove if the Quill theme system no longer needs it.

- [ ] **Step 3: Update AppearancePage.qml**

If there's an "Icon Font" name setting, remove or hide it. If there's an "Icon Font Size" setting, rename the label to "Icon Size".

- [ ] **Step 4: Update tasks.md**

Add entry documenting the Lucide icon system:
- 43 icon components in `quickshell/icons/`
- Icon Gallery page in Settings
- All nerd font icons replaced except IntegrationsPage tmux preview

- [ ] **Step 5: Final visual test**

Do a complete walkthrough: bar, notification center, settings (all pages including Icon Gallery), power menu, lock screen, OSD (volume/brightness/caps/num), clock popup, media popup, notification toasts, clipboard panel.

- [ ] **Step 6: Commit**

```bash
git add quickshell/Config.qml quickshell/Theme.qml quickshell/settings/AppearancePage.qml tasks.md
git commit -m "chore(icons): post-migration cleanup and tasks.md update"
```
