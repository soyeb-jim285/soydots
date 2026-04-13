# Notification Icon/Image Support

## Goal

Show app icons and notification images in both toast popups and the notification center history, so users can visually identify which app sent each notification at a glance.

## Icon Priority Chain

Each notification's icon slot resolves in this order:

1. **`notification.image`** — inline image provided by the app (chat avatar, screenshot preview, etc.)
2. **`notification.appIcon`** — freedesktop icon name or file path. File paths (starting with `/` or `file://`) are used directly; icon names are resolved via `Quickshell.iconPath(iconName, true)`.
3. **`notification.appName`** — if appIcon is empty, the app name is tried as an icon theme name (most apps name their icon after themselves).
4. **Fallback** — the existing urgency indicator (colored dot in history, urgency icon in toasts)

## Icon Slot Layout

### Toast Popups (NotificationPopup.qml)

- **Size**: 32x32px
- **Shape**: Rounded square, `border-radius: 8px`
- **Container**: Subtle border (`Theme.surface1`) on dark background (`Theme.mantle`/`Theme.crust`)
- **Position**: Replaces the current urgency icon Loader on the left side of the toast
- **Fallback**: When no image or icon is available, show the existing urgency icon (bell/alert/info) as today

### Notification Center History (NotificationCenter.qml)

- **Size**: 28x28px
- **Shape**: Rounded square, `border-radius: 6px`
- **Container**: Same subtle border style as toasts
- **Position**: Replaces the current 6x6 colored urgency dot
- **Fallback**: When no image or icon is available, show the colored urgency dot as today

## Icon Source Resolution

```qml
// Pseudocode for the Image source binding
source: {
    if (image !== "")
        return image;
    if (appIcon !== "")
        return Quickshell.iconPath(appIcon, true);
    return "";
}
```

When source resolves to `""`, the Image is hidden and the fallback urgency indicator is shown instead via `visible` bindings.

## Data Flow

The notification data model already captures `appIcon` and `image` in `NotificationPopup.qml` (lines 63-64) and stores them in the history array. Currently these fields are unused.

### Toast Model Changes

The `toastModel` ListModel currently does not include `appIcon` or `image`. These need to be added to the `insert()` call in `addToast()` so toast delegates can access them.

### History Model

No changes needed — `appIcon` and `image` are already stored in the history objects.

## Files to Modify

- **`quickshell/NotificationPopup.qml`**:
  - Add `appIcon` and `image` fields to `toastModel.insert()` in `addToast()`
  - Add `required property` declarations for `appIcon` and `image` on the toast delegate
  - Replace the urgency icon `Loader` with an `Image` + fallback pattern

- **`quickshell/NotificationCenter.qml`**:
  - Replace the 6x6 urgency dot `Rectangle` with an `Image` + fallback pattern
  - Access `histItem.modelData.appIcon` and `histItem.modelData.image` (already available)

## What Stays the Same

- Urgency is still communicated via progress bar color on toasts and border color on critical notifications
- No new configuration options — this uses data already captured by the notification server
- No new dependencies — `Quickshell.iconPath()` is a built-in Quickshell function
- No new icon files or assets needed
- Toast and history layout structure remains the same, only the left-side indicator changes
