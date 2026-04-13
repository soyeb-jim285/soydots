# Notification Action Buttons

## Goal

Show action buttons on notifications that provide them via the D-Bus notification spec, and create a screenshot wrapper script that sends notifications with "Open" and "Delete" actions.

## Part 1: Action Button UI

### Toast Popups (always visible)

When a notification has actions, render a row of buttons below the text content inside the toast card.

- **Layout**: `Row` of buttons below the existing text `Column`, inside the toast `Rectangle`
- **Visibility**: Always visible when actions exist — toasts are transient so the user needs to see and act quickly
- **Toast height**: Grows dynamically when actions are present. The toast `Rectangle` height should use `implicitHeight` from its content rather than the fixed `Config.notifPopupHeight` when actions exist
- **Button styling**:
  - Background: `Theme.surface0`, hover: `Theme.surface1`
  - Text color: `Theme.subtext0`, hover: `Theme.text`
  - Font: `Theme.fontFamily`, `pixelSize: 10`
  - Corner radius: 6
  - Each button fills equal width via `Layout.fillWidth: true`
  - Spacing between buttons: 6px
- **Click behavior**: Call `action.invoke()` which triggers the D-Bus `ActionInvoked` signal and dismisses the notification (unless `resident` is true)
- **Data access**: The toast model already stores notification refs in `root.toastNotifs[toastId]`. Access actions via `root.toastNotifs[toast.toastId].actions`.

### History Items (hover reveal)

When a history item has actions, a button row appears below the text on hover.

- **Layout**: Same button row as toasts, placed below the text `Column` inside `histRow`
- **Visibility**: Hidden by default, shown when `histMouse.containsMouse` is true
- **Animation**: Fade in with `Behavior on opacity`, duration 150ms
- **Height change**: The history item `implicitHeight` grows to accommodate buttons on hover, with `Behavior on implicitHeight` for smooth animation
- **Button styling**: Same as toast buttons
- **Click behavior**: Call `action.invoke()` and dismiss from history
- **Data access**: History objects already store `actions` array from `notification.actions`

### Shared Button Behavior

- Buttons use the action's `text` property for the label (from `NotificationAction.text`)
- Maximum 3 buttons shown — if more actions exist, truncate (rare in practice)
- No buttons rendered when `actions` is empty or undefined — existing layout unchanged

## Part 2: Screenshot Wrapper Script

### Script: `hypr/screenshot.sh`

A bash script that wraps hyprshot and sends an actionable notification:

```
Usage: screenshot.sh <mode>
  mode: region, window, output
```

**Flow:**
1. Run `hyprshot -m <mode> --freeze -o ~/Pictures/Screenshots -s` (with `-s` for silent — suppress hyprshot's own notification)
2. Find the newest screenshot file in `~/Pictures/Screenshots` (hyprshot creates it with a timestamp name)
3. Send notification via `notify-send`:
   - Summary: "Screenshot saved"
   - Body: filename
   - Icon (`-i`): full path to the screenshot file (enables preview via our icon support)
   - App name (`-a`): "Hyprshot"
   - Actions: `-A "open=Open" -A "delete=Delete"`
   - `--wait` flag to block until user acts
4. Read chosen action from stdout:
   - `"open"` → `xdg-open <filepath>`
   - `"delete"` → `rm <filepath>` and optionally notify "Screenshot deleted"
   - No action (timeout/dismissed) → do nothing, script exits

### Keybinding Updates

**`hypr/hyprland.conf`** — update screenshot bindings to call the wrapper:
- `Super+Shift+P` → `screenshot.sh region`
- `Super+Shift+F` → `screenshot.sh output`
- `Super+Shift+W` → `screenshot.sh window`

**`quickshell/NotificationCenter.qml`** — update `ssProc` command to call the wrapper:
- `["bash", "-c", "sleep 0.3 && ~/jimdots/hypr/screenshot.sh region"]`

## Files to Modify

- **`quickshell/NotificationPopup.qml`** — add action button row to toast delegate, make toast height dynamic when actions present
- **`quickshell/NotificationCenter.qml`** — add hover-reveal action button row to history items, update ssProc
- **`hypr/screenshot.sh`** — new file, screenshot wrapper with actionable notification
- **`hypr/hyprland.conf`** — update screenshot keybindings to use wrapper

## What Stays the Same

- Notifications without actions render identically to current behavior
- The icon/image support we just built works unchanged
- Toast auto-expire, dismiss animations, urgency indicators all unchanged
- `NotificationServer` configuration unchanged (`actionsSupported` is already `true`)
