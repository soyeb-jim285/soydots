# App Launcher Improvements — Design Spec

## Overview

Six improvements to the Quickshell app launcher (`quickshell/AppLauncher.qml`): a bug fix, sorting, fuzzy search, pinned favorites, frecency tracking, and a close animation.

## 1. Backdrop Opacity Bug Fix

**Problem:** Line 101 of `AppLauncher.qml` hardcodes `0.25` for backdrop opacity instead of using `Config.launcherBackdropOpacity`.

**Fix:** Replace `fadeIn * 0.25` with `fadeIn * Config.launcherBackdropOpacity`.

## 2. Alphabetical Sorting

Sort `allApps` by `name` (case-insensitive) as the base ordering. All other sort logic (frecency, pinning) layers on top of this.

## 3. Fuzzy Search (Sequential + Trigram)

Replace the current `string.includes()` filtering with a two-signal fuzzy matcher.

### Sequential Matching (primary signal)

Characters in the query must appear in order in the target string. Scoring bonuses:
- **Consecutive characters:** bonus for runs of matching characters
- **Word boundary:** bonus when a match starts at the beginning of a word (after space, hyphen, or at index 0)
- **Start of string:** bonus when the match begins at the start of the name

### Trigram Similarity (secondary signal)

Jaccard similarity (`|intersection| / |union|`) of n-gram sets between query and target:
- Use **bigrams** for queries of 3 characters or fewer
- Use **trigrams** for queries of 4+ characters

Both query and target are lowercased before n-gram extraction.

### Combined Scoring

```
finalScore = (sequentialScore * 0.7) + (trigramSimilarity * 0.3)
```

- Minimum threshold: discard results with `finalScore < 0.1` to avoid garbage
- Search runs against: app name, generic name, comment, keywords (best score wins)

### Search Fields

Match against (in priority order, use best score):
1. `app.name`
2. `app.genericName`
3. `app.comment`
4. `app.keywords` (joined as single string)

## 4. Pinned/Favorite Apps

### Storage

`settings.toml` under `launcher.pinnedApps` — array of app ID strings. Managed through `Config.set("launcher", "pinnedApps", [...])`.

New Config property: `launcherPinnedApps` (list of strings, default `[]`).

### Behavior

- **Empty search field:** Pinned apps display at the top of the list with a star icon (Lucide `IconStar` or similar) on the right side of each row. Remaining apps follow below.
- **With search text:** Normal fuzzy-filtered results, no pinning treatment. Star icon still visible on pinned apps for recognition.

### Interaction

- **Right-click** an app row: toggles pin/unpin
- **Ctrl+Enter** on highlighted app: toggles pin/unpin (keyboard equivalent)
- Pin state persists immediately via `Config.set`

### Settings Page

Add a "Pinned Apps" section to `LauncherPage.qml`, identical in style to the existing "Hidden Apps" section: list of pinned app names with remove (X) buttons and an add input.

## 5. Frecency Tracking

### Storage

`settings.toml` under `launcher.frecencyData` — object mapping app ID to `{score: number, lastLaunch: number}` (lastLaunch is Unix timestamp in seconds).

New Config property: `launcherFrecencyData` (object/map, default `{}`).

### Algorithm

On each app launch:
```
daysSinceLastLaunch = (now - lastLaunch) / 86400
decay = 0.5 ^ (daysSinceLastLaunch / 7)
newScore = (existingScore * decay) + 100
```

Score halves every 7 days of inactivity. A fresh launch always adds 100 points.

### Sort Integration

**Empty search field:**
1. Pinned apps (sorted alphabetically among themselves)
2. Non-pinned apps (sorted by frecency score descending, alphabetical as tiebreaker)

**With search text:**
1. Fuzzy match score descending
2. Frecency score as tiebreaker for equal fuzzy scores

## 6. Close Animation

### Current State

Opening has scale (0.85 → 1.0) + fade (0 → 1.0) animations. Closing is instant — `root.visible = false` immediately unloads the LazyLoader.

### Design

Reverse of open:
- Container: scale 1.0 → 0.85, opacity 1.0 → 0
- Backdrop: fade alpha to 0
- Duration: match open animation (~200ms fade, ~250ms scale)
- After animations complete, set `root.visible = false`

### Implementation Approach

Instead of directly setting `root.visible = false`, introduce a `closing` state that triggers exit animations. On animation completion, set `root.visible = false` which triggers the LazyLoader to unload.

The `toggle()` function becomes:
- If not visible: set `visible = true` (triggers open animations via LazyLoader)
- If visible: set `closing = true` (triggers close animations, which set `visible = false` on completion)

## File Changes

| File | Change |
|------|--------|
| `AppLauncher.qml` | All 6 features — sorting, fuzzy search, frecency, pinning, close animation, backdrop fix |
| `Config.qml` | Add `launcherPinnedApps` and `launcherFrecencyData` properties |
| `defaults.toml` | Add default values for `pinnedApps` and `frecencyData` |
| `settings/LauncherPage.qml` | Add "Pinned Apps" management section |
| `icons/` | Add `IconStar.qml` if not already present (for pin indicator) |

## Out of Scope

- Categories/sections
- Right-click context menus for app actions (New Window, etc.)
- Calculator/math evaluation
- Web/file search passthrough
- Multi-monitor targeting
