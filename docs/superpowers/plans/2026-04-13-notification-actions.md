# Notification Action Buttons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show action buttons on notifications and create a screenshot wrapper script with "Open" and "Delete" actions.

**Architecture:** Add action button rows to toast popups (always visible) and notification center history (hover reveal). Create a bash screenshot wrapper that sends actionable notifications via `notify-send -A`. Toast height becomes dynamic when actions are present.

**Tech Stack:** QML (Quickshell), Bash, D-Bus notification spec, `notify-send -A`

**Spec:** `docs/superpowers/specs/2026-04-13-notification-actions-design.md`

---

### Task 1: Add action buttons to toast popups

**Files:**
- Modify: `quickshell/NotificationPopup.qml:280-425` (toast delegate)

The toast delegate currently uses a fixed height (`root.itemHeight`) and a single `Row` for content. We need to:
1. Switch to a `Column` layout so buttons can sit below the content row
2. Make the toast height dynamic when actions exist
3. Update y-positioning since toasts may now have different heights

- [ ] **Step 1: Restructure toast content layout to support action buttons**

In `quickshell/NotificationPopup.qml`, the toast `Rectangle` delegate (starting at line 280) needs these changes:

**a) Change the toast height from fixed to dynamic when actions exist:**

Replace:
```qml
                    width: toastContainer.width
                    height: root.itemHeight
```

With:
```qml
                    width: toastContainer.width
                    height: toast.hasActions ? toastContent.implicitHeight + 16 : root.itemHeight
```

**b) Wrap existing `Row` and add action buttons below it. Replace the entire content block (lines 333-425, from `Row { id: toastRow` through the `Column` closing brace `}`) with a `Column` wrapper:**

Replace:
```qml
                    Row {
                        id: toastRow
                        anchors.left: parent.left
                        anchors.right: closeBtn.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 4
                        spacing: 8
```

With:
```qml
                    Column {
                        id: toastContent
                        anchors.left: parent.left
                        anchors.right: closeBtn.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 4
                        spacing: 6

                        Row {
                            id: toastRow
                            width: parent.width
                            spacing: 8
```

**c) Close the Row and add the action buttons row. After the text `Column` closing brace (the one at current line 425), add:**

```qml
                        }

                        // Action buttons
                        Row {
                            visible: toast.hasActions
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: {
                                    let notif = root.toastNotifs[toast.toastId];
                                    if (!notif || !notif.actions) return [];
                                    let acts = [];
                                    for (let i = 0; i < Math.min(notif.actions.length, 3); i++)
                                        acts.push({ text: notif.actions[i].text, idx: i });
                                    return acts;
                                }

                                Rectangle {
                                    required property var modelData
                                    width: (parent.width - (parent.children.length - 1) * 6) / parent.children.length
                                    height: 24
                                    radius: 6
                                    color: actionMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                    Behavior on color { ColorAnimation { duration: 80 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.text
                                        color: actionMouse.containsMouse ? Theme.text : Theme.subtext0
                                        font.pixelSize: 10; font.family: Theme.fontFamily
                                        Behavior on color { ColorAnimation { duration: 80 } }
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let notif = root.toastNotifs[toast.toastId];
                                            if (notif && notif.actions && notif.actions.length > modelData.idx)
                                                notif.actions[modelData.idx].invoke();
                                            root.removeToastById(toast.toastId);
                                        }
                                    }
                                }
                            }
                        }
```

**d) Close the outer Column wrapper** — make sure the closing `}` for `toastContent` Column is properly placed before the `IconX` close button.

**e) Update toast y-positioning.** The current y-positioning uses fixed height:
```qml
                    y: index * (root.itemHeight + root.itemSpacing)
```

This still works because toasts with actions will just overlap slightly or have gaps. For simplicity, keep the fixed positioning but use the toast's own height:

Replace:
```qml
                    y: index * (root.itemHeight + root.itemSpacing)
```

With:
```qml
                    y: {
                        let offset = 0;
                        for (let i = 0; i < index; i++) {
                            let item = toastModel.get(i);
                            let h = item && item.hasActions ? toastContent.implicitHeight + 16 : root.itemHeight;
                            offset += h + root.itemSpacing;
                        }
                        return offset;
                    }
```

Actually, this is problematic because each delegate can't easily read other delegates' heights. Keep it simple — use a slightly larger fixed offset for action toasts:

Replace:
```qml
                    y: index * (root.itemHeight + root.itemSpacing)
```

With:
```qml
                    y: index * ((toast.hasActions ? height : root.itemHeight) + root.itemSpacing)
```

This isn't perfect for mixed toast types, but in practice there are rarely more than 2-3 toasts at once. Keep the simple approach.

- [ ] **Step 2: Verify toast action buttons display**

Run:
```bash
notify-send -A "open=Open" -A "delete=Delete" -a "Hyprshot" "Screenshot saved" "Test actions"
```

Expected: Toast appears with "Open" and "Delete" buttons below the text. The toast is taller than normal. Clicking a button should dismiss the toast.

Also test a notification without actions:
```bash
notify-send "No Actions" "Should look normal"
```

Expected: Normal toast, no buttons, same height as before.

- [ ] **Step 3: Commit**

```bash
git add quickshell/NotificationPopup.qml
git commit -m "feat(notif): add action buttons to toast popups"
```

---

### Task 2: Add hover-reveal action buttons to notification center history

**Files:**
- Modify: `quickshell/NotificationCenter.qml:680-835` (history item delegate)

- [ ] **Step 1: Restructure history item content to support action buttons**

In `quickshell/NotificationCenter.qml`, the history Row (`id: histRow`, line 754) currently contains the icon slot and text column. We need to wrap it in a Column and add action buttons below.

**a) Change `histRow` from a `Row` to a `Column` containing the row + actions. Replace:**

```qml
                                // Left side: icon + text content
                                Row {
                                    id: histRow
                                    anchors.left: parent.left
                                    anchors.right: histRight.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 4
                                    spacing: 8
```

With:
```qml
                                // Left side: icon + text content + action buttons
                                Column {
                                    id: histCol
                                    anchors.left: parent.left
                                    anchors.right: histRight.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 4
                                    spacing: 4

                                    Row {
                                        id: histRow
                                        width: parent.width
                                        spacing: 8
```

**b) After the text Column closing brace (line 833, the `}` that closes the Column containing the two Text elements), close the Row and add action buttons:**

```qml
                                    }

                                    // Action buttons (hover reveal)
                                    Row {
                                        visible: histMouse.containsMouse && histItem.modelData.actions && histItem.modelData.actions.length > 0
                                        width: parent.width
                                        spacing: 6
                                        opacity: visible ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                        Repeater {
                                            model: {
                                                let acts = histItem.modelData.actions;
                                                if (!acts) return [];
                                                let result = [];
                                                for (let i = 0; i < Math.min(acts.length, 3); i++)
                                                    result.push({ text: acts[i].text, idx: i });
                                                return result;
                                            }

                                            Rectangle {
                                                required property var modelData
                                                width: (parent.width - (parent.children.length - 1) * 6) / parent.children.length
                                                height: 22
                                                radius: 6
                                                color: histActionMouse.containsMouse ? Theme.surface1 : Theme.surface0
                                                Behavior on color { ColorAnimation { duration: 80 } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.text
                                                    color: histActionMouse.containsMouse ? Theme.text : Theme.subtext0
                                                    font.pixelSize: 10; font.family: Theme.fontFamily
                                                    Behavior on color { ColorAnimation { duration: 80 } }
                                                }

                                                MouseArea {
                                                    id: histActionMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        let acts = histItem.modelData.actions;
                                                        if (acts && acts.length > modelData.idx)
                                                            acts[modelData.idx].invoke();
                                                        histItem.dismiss();
                                                    }
                                                }
                                            }
                                        }
                                    }
```

**c) Close the outer Column** — ensure `histCol` is properly closed before the `MouseArea { id: histMouse }`.

**d) Update the histItem implicitHeight** to account for action buttons on hover. Change:

```qml
                                implicitHeight: histRow.implicitHeight + 16
```

To:
```qml
                                implicitHeight: histCol.implicitHeight + 16
```

And add a height animation:
```qml
                                Behavior on implicitHeight { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
```

- [ ] **Step 2: Verify history action buttons display**

Send a notification with actions, then open the notification center:
```bash
notify-send -A "open=Open" -A "delete=Delete" -a "Hyprshot" "Screenshot saved" "Test actions"
```

Open the notification center. Hover over the notification.

Expected: Action buttons slide in below the text on hover. Card height grows smoothly. Clicking a button invokes the action and dismisses the item.

Test a notification without actions — should look identical to before with no buttons on hover.

- [ ] **Step 3: Commit**

```bash
git add quickshell/NotificationCenter.qml
git commit -m "feat(notif): add hover-reveal action buttons to notification center history"
```

---

### Task 3: Create screenshot wrapper script

**Files:**
- Create: `hypr/screenshot.sh`

- [ ] **Step 1: Create the screenshot wrapper script**

Create `hypr/screenshot.sh`:

```bash
#!/usr/bin/env bash
# Screenshot wrapper — runs hyprshot, sends actionable notification

set -euo pipefail

MODE="${1:-region}"
OUTPUT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$OUTPUT_DIR"

# Get timestamp before screenshot for file detection
BEFORE=$(date +%s%N)

# Run hyprshot silently (we'll send our own notification)
hyprshot -m "$MODE" --freeze -s -o "$OUTPUT_DIR" || exit 0

# Find the newest file created after our timestamp
SCREENSHOT=""
for f in "$OUTPUT_DIR"/*; do
    if [[ -f "$f" ]] && [[ $(stat -c %Y "$f") -ge $((BEFORE / 1000000000)) ]]; then
        SCREENSHOT="$f"
    fi
done

[[ -z "$SCREENSHOT" ]] && exit 0

FILENAME=$(basename "$SCREENSHOT")

# Send actionable notification
ACTION=$(notify-send "Screenshot saved" "$FILENAME" \
    -a "Hyprshot" \
    -i "$SCREENSHOT" \
    -A "open=Open" \
    -A "delete=Delete" \
    --wait 2>/dev/null || true)

case "$ACTION" in
    open)
        xdg-open "$SCREENSHOT" &
        ;;
    delete)
        rm -f "$SCREENSHOT"
        notify-send "Screenshot deleted" "$FILENAME" -a "Hyprshot" -t 2000
        ;;
esac
```

- [ ] **Step 2: Make the script executable**

```bash
chmod +x hypr/screenshot.sh
```

- [ ] **Step 3: Test the script manually**

```bash
~/jimdots/hypr/screenshot.sh region
```

Expected: Hyprshot opens region selector. After taking screenshot, a notification appears with "Open" and "Delete" buttons. Clicking "Open" opens the image. Clicking "Delete" removes the file and shows a confirmation notification.

- [ ] **Step 4: Commit**

```bash
git add hypr/screenshot.sh
git commit -m "feat(hypr): add screenshot wrapper script with actionable notifications"
```

---

### Task 4: Update keybindings and quickshell to use screenshot wrapper

**Files:**
- Modify: `hypr/hyprland.conf:275-278` (screenshot keybindings)
- Modify: `quickshell/NotificationCenter.qml:153` (ssProc command)

- [ ] **Step 1: Update hyprland keybindings**

In `hypr/hyprland.conf`, replace:
```
# Screenshots
bind = $mainMod SHIFT, P, exec, hyprshot -m region --freeze -o ~/Pictures/Screenshots
bind = $mainMod SHIFT, F, exec, hyprshot -m output --freeze -o ~/Pictures/Screenshots
bind = $mainMod SHIFT, W, exec, hyprshot -m window --freeze -o ~/Pictures/Screenshots
```

With:
```
# Screenshots
bind = $mainMod SHIFT, P, exec, ~/jimdots/hypr/screenshot.sh region
bind = $mainMod SHIFT, F, exec, ~/jimdots/hypr/screenshot.sh output
bind = $mainMod SHIFT, W, exec, ~/jimdots/hypr/screenshot.sh window
```

- [ ] **Step 2: Update quickshell screenshot Process**

In `quickshell/NotificationCenter.qml`, replace:
```qml
    Process { id: ssProc; command: ["bash", "-c", "sleep 0.3 && hyprshot -m region --freeze -o ~/Pictures/Screenshots"] }
```

With:
```qml
    Process { id: ssProc; command: ["bash", "-c", "sleep 0.3 && ~/jimdots/hypr/screenshot.sh region"] }
```

- [ ] **Step 3: Verify end-to-end**

Reload hyprland and quickshell. Take a screenshot with `Super+Shift+P`.

Expected: Region selector opens. After capture, notification appears with screenshot preview icon, "Open" and "Delete" buttons. Both buttons work.

- [ ] **Step 4: Commit**

```bash
git add hypr/hyprland.conf quickshell/NotificationCenter.qml
git commit -m "feat(hypr): use screenshot wrapper in keybindings and quickshell"
```
