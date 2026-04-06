# App Launcher Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve the Quickshell app launcher with fuzzy search, frecency sorting, pinned favorites, alphabetical ordering, close animation, and a backdrop opacity bug fix.

**Architecture:** All search/sort logic lives in `AppLauncher.qml` as pure JS helper functions. Config properties for pinned apps and frecency data are added to `Config.qml` alongside existing launcher properties. Frecency data is stored as a JSON string in the TOML config since the TOML writer doesn't support nested objects. A new `IconStar.qml` Lucide icon is added for the favorites indicator.

**Tech Stack:** QML (Qt 6), JavaScript, Quickshell framework

**Spec:** `docs/superpowers/specs/2026-04-07-launcher-improvements-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `quickshell/AppLauncher.qml` | Modify | All 6 features: fuzzy search, sorting, frecency, pinning, close animation, backdrop fix |
| `quickshell/Config.qml` | Modify | Add `launcherPinnedApps`, `launcherFrecencyData` properties + include in save/serialization |
| `quickshell/defaults.toml` | Modify | Add default values for `pinnedApps` and `frecencyData` |
| `quickshell/settings/LauncherPage.qml` | Modify | Add "Pinned Apps" management section |
| `quickshell/icons/IconStar.qml` | Create | Lucide star icon for pinned app indicator |
| `quickshell/qmldir` | Modify | Register IconStar component |

---

### Task 1: Backdrop Opacity Bug Fix

**Files:**
- Modify: `quickshell/AppLauncher.qml:101`

- [ ] **Step 1: Fix the hardcoded opacity value**

In `quickshell/AppLauncher.qml` line 101, replace the hardcoded `0.25` with the config value:

```qml
// Before (line 101):
color: Qt.rgba(0, 0, 0, fadeIn * 0.25)

// After:
color: Qt.rgba(0, 0, 0, fadeIn * Config.launcherBackdropOpacity)
```

- [ ] **Step 2: Verify visually**

Run quickshell, open the launcher (Meta+R), confirm the backdrop uses the configured opacity. Change the value in settings to confirm it updates.

- [ ] **Step 3: Commit**

```bash
git add quickshell/AppLauncher.qml
git commit -m "fix: use configured backdrop opacity in app launcher"
```

---

### Task 2: Alphabetical Sorting

**Files:**
- Modify: `quickshell/AppLauncher.qml:20-31`

- [ ] **Step 1: Add case-insensitive alphabetical sort to allApps**

In `quickshell/AppLauncher.qml`, modify the `allApps` property (lines 20-31) to sort after filtering:

```qml
property list<DesktopEntry> allApps: {
    let apps = Array.from(DesktopEntries.applications.values);
    let filtered = apps.filter(app => {
        let id = (app.id ?? "").toLowerCase();
        let name = (app.name ?? "").toLowerCase();
        for (let hidden of hiddenApps) {
            if (id.includes(hidden) || name.includes(hidden))
                return false;
        }
        return true;
    });
    filtered.sort((a, b) => {
        let nameA = (a.name ?? "").toLowerCase();
        let nameB = (b.name ?? "").toLowerCase();
        return nameA < nameB ? -1 : nameA > nameB ? 1 : 0;
    });
    return filtered;
}
```

- [ ] **Step 2: Verify visually**

Open the launcher. Apps should now appear in A-Z order.

- [ ] **Step 3: Commit**

```bash
git add quickshell/AppLauncher.qml
git commit -m "feat(launcher): sort apps alphabetically"
```

---

### Task 3: Config Properties for Pinned Apps and Frecency

**Files:**
- Modify: `quickshell/Config.qml:1131-1143` (launcher properties section)
- Modify: `quickshell/Config.qml:205-211` (launcher save object)
- Modify: `quickshell/defaults.toml:109-119` (launcher defaults)

- [ ] **Step 1: Add properties to Config.qml**

After line 1143 (`property string launcherTerminal`), add:

```qml
    property var launcherPinnedApps: _data?.launcher?.pinnedApps ?? []
    property string launcherFrecencyData: _data?.launcher?.frecencyData ?? "{}"
```

- [ ] **Step 2: Add to the save serialization object**

In the `_doSave()` function, modify the `launcher` object (around line 205-211) to include the new properties:

```qml
launcher: {
    width: launcherWidth, maxHeight: launcherMaxHeight, radius: launcherRadius,
    searchHeight: launcherSearchHeight, searchRadius: launcherSearchRadius,
    itemHeight: launcherItemHeight, itemRadius: launcherItemRadius,
    iconSize: launcherIconSize,
    backdropOpacity: launcherBackdropOpacity,
    hiddenApps: launcherHiddenApps, terminal: launcherTerminal,
    pinnedApps: launcherPinnedApps, frecencyData: launcherFrecencyData
},
```

- [ ] **Step 3: Add defaults to defaults.toml**

In `quickshell/defaults.toml`, add to the `[launcher]` section (after the `width = 600` line):

```toml
pinnedApps = []
frecencyData = "{}"
```

- [ ] **Step 4: Commit**

```bash
git add quickshell/Config.qml quickshell/defaults.toml
git commit -m "feat(launcher): add config properties for pinned apps and frecency"
```

---

### Task 4: Create IconStar Component

**Files:**
- Create: `quickshell/icons/IconStar.qml`
- Modify: `quickshell/qmldir`

- [ ] **Step 1: Create the Lucide star icon**

Create `quickshell/icons/IconStar.qml` following the same pattern as `IconPin.qml`. The Lucide "star" icon SVG path is:

```qml
import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property real size: 24
    property color color: "#ffffff"
    property real strokeWidth: Math.max(1, size / 12)
    width: size; height: size
    clip: false
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: root.color; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a.53.53 0 0 0 .4.29l5.16.753a.53.53 0 0 1 .294.904l-3.733 3.638a.53.53 0 0 0-.152.469l.882 5.14a.53.53 0 0 1-.77.56l-4.614-2.426a.53.53 0 0 0-.494 0L7.14 18.728a.53.53 0 0 1-.77-.56l.882-5.14a.53.53 0 0 0-.152-.47L3.367 8.92a.53.53 0 0 1 .294-.905l5.16-.752a.53.53 0 0 0 .4-.29z" }
    }
}
```

- [ ] **Step 2: Register in qmldir**

Add to `quickshell/qmldir` in alphabetical order among the icon entries:

```
IconStar 1.0 icons/IconStar.qml
```

- [ ] **Step 3: Commit**

```bash
git add quickshell/icons/IconStar.qml quickshell/qmldir
git commit -m "feat(icons): add Lucide star icon for launcher favorites"
```

---

### Task 5: Fuzzy Search (Sequential + Trigram)

**Files:**
- Modify: `quickshell/AppLauncher.qml:33-44` (replace `filteredApps`)

- [ ] **Step 1: Add fuzzy search helper functions**

In `quickshell/AppLauncher.qml`, add these functions inside the `Scope` block (after the `hiddenApps` property, before `allApps`):

```qml
// Sequential match score: chars in query appear in order in target
// Returns 0-1 score, 0 means no match
function sequentialScore(query, target) {
    if (query.length === 0) return 0;
    let qi = 0;
    let score = 0;
    let consecutive = 0;
    let firstMatch = -1;

    for (let ti = 0; ti < target.length && qi < query.length; ti++) {
        if (target[ti] === query[qi]) {
            if (firstMatch < 0) firstMatch = ti;
            consecutive++;
            // Bonus for consecutive chars
            score += consecutive;
            // Bonus for word boundary (start of string or after space/hyphen)
            if (ti === 0 || target[ti - 1] === ' ' || target[ti - 1] === '-')
                score += 3;
            qi++;
        } else {
            consecutive = 0;
        }
    }
    if (qi < query.length) return 0; // Not all query chars matched
    // Normalize: max possible score is roughly query.length * (query.length+1)/2 + 3*query.length
    let maxScore = query.length * (query.length + 1) / 2 + 3 * query.length;
    return score / maxScore;
}

// N-gram set for a string
function ngrams(str, n) {
    let set = new Set();
    for (let i = 0; i <= str.length - n; i++)
        set.add(str.substring(i, i + n));
    return set;
}

// Jaccard similarity between two n-gram sets
function ngramSimilarity(query, target) {
    let n = query.length <= 3 ? 2 : 3;
    if (query.length < n || target.length < n) return 0;
    let qSet = ngrams(query, n);
    let tSet = ngrams(target, n);
    let intersection = 0;
    qSet.forEach(g => { if (tSet.has(g)) intersection++; });
    let union = qSet.size + tSet.size - intersection;
    return union === 0 ? 0 : intersection / union;
}

// Combined fuzzy score for a query against a single string
function fuzzyScore(query, target) {
    let seq = sequentialScore(query, target);
    let ngram = ngramSimilarity(query, target);
    return seq * 0.7 + ngram * 0.3;
}

// Score an app against a search query (best across all searchable fields)
function scoreApp(app, query) {
    let name = (app.name ?? "").toLowerCase();
    let generic = (app.genericName ?? "").toLowerCase();
    let comment = (app.comment ?? "").toLowerCase();
    let keywords = (app.keywords ?? []).join(" ").toLowerCase();
    return Math.max(
        fuzzyScore(query, name),
        fuzzyScore(query, generic),
        fuzzyScore(query, comment),
        fuzzyScore(query, keywords)
    );
}
```

- [ ] **Step 2: Replace the filteredApps property**

Replace the existing `filteredApps` property (lines 33-44) with:

```qml
property var filteredApps: {
    let query = searchText.toLowerCase().trim();
    if (query === "") return allApps;
    let scored = allApps.map(app => ({ app: app, score: scoreApp(app, query) }));
    scored = scored.filter(item => item.score >= 0.1);
    scored.sort((a, b) => b.score - a.score);
    return scored.map(item => item.app);
}
```

- [ ] **Step 3: Verify visually**

Open the launcher and test:
- "fire" → Firefox should appear
- "ffox" → Firefox should appear (sequential match)
- "ferfox" → Firefox should appear (trigram match)
- "kit" → Kitty should appear
- "xyz123" → no results

- [ ] **Step 4: Commit**

```bash
git add quickshell/AppLauncher.qml
git commit -m "feat(launcher): add fuzzy search with sequential + trigram matching"
```

---

### Task 6: Frecency Tracking

**Files:**
- Modify: `quickshell/AppLauncher.qml` (launch function + sort logic)

- [ ] **Step 1: Add frecency helper functions**

Add these functions in `AppLauncher.qml` inside the `Scope` block, after the fuzzy search functions:

```qml
// Parse frecency data from the JSON string stored in config
function getFrecencyData() {
    try {
        return JSON.parse(Config.launcherFrecencyData);
    } catch (e) {
        return {};
    }
}

// Record a launch event for an app
function recordLaunch(appId) {
    let data = getFrecencyData();
    let now = Math.floor(Date.now() / 1000);
    let entry = data[appId] || { score: 0, lastLaunch: now };
    let daysSince = (now - entry.lastLaunch) / 86400;
    let decay = Math.pow(0.5, daysSince / 7);
    entry.score = entry.score * decay + 100;
    entry.lastLaunch = now;
    data[appId] = entry;
    Config.set("launcher", "frecencyData", JSON.stringify(data));
}

// Get the current frecency score for an app (with decay applied)
function getFrecencyScore(appId) {
    let data = getFrecencyData();
    let entry = data[appId];
    if (!entry) return 0;
    let now = Math.floor(Date.now() / 1000);
    let daysSince = (now - entry.lastLaunch) / 86400;
    let decay = Math.pow(0.5, daysSince / 7);
    return entry.score * decay;
}
```

- [ ] **Step 2: Update the launch function to record frecency**

Modify the existing `launch` function (around line 53-60) to call `recordLaunch`:

```qml
function launch(app) {
    recordLaunch(app.id ?? app.name ?? "");
    if (app.runInTerminal) {
        Quickshell.execDetached([Config.launcherTerminal].concat(app.command));
    } else {
        app.execute();
    }
    root.visible = false;
}
```

- [ ] **Step 3: Update allApps sort to use frecency**

Modify the `allApps` property sort to use frecency as primary sort (after pinned apps, which come in Task 7), with alphabetical as tiebreaker:

```qml
filtered.sort((a, b) => {
    let scoreA = getFrecencyScore(a.id ?? a.name ?? "");
    let scoreB = getFrecencyScore(b.id ?? b.name ?? "");
    if (scoreA !== scoreB) return scoreB - scoreA;
    let nameA = (a.name ?? "").toLowerCase();
    let nameB = (b.name ?? "").toLowerCase();
    return nameA < nameB ? -1 : nameA > nameB ? 1 : 0;
});
```

- [ ] **Step 4: Update filteredApps to use frecency as tiebreaker**

Update the `filteredApps` sort to use frecency as a tiebreaker for equal fuzzy scores:

```qml
property var filteredApps: {
    let query = searchText.toLowerCase().trim();
    if (query === "") return allApps;
    let scored = allApps.map(app => ({ app: app, score: scoreApp(app, query) }));
    scored = scored.filter(item => item.score >= 0.1);
    scored.sort((a, b) => {
        if (Math.abs(a.score - b.score) > 0.01) return b.score - a.score;
        let freqA = getFrecencyScore(a.app.id ?? a.app.name ?? "");
        let freqB = getFrecencyScore(b.app.id ?? b.app.name ?? "");
        return freqB - freqA;
    });
    return scored.map(item => item.app);
}
```

- [ ] **Step 5: Verify visually**

Open launcher, launch an app (e.g. Kitty). Close and reopen the launcher — Kitty should now appear near the top of the list (when search is empty).

- [ ] **Step 6: Commit**

```bash
git add quickshell/AppLauncher.qml
git commit -m "feat(launcher): add frecency tracking for app launch history"
```

---

### Task 7: Pinned/Favorite Apps

**Files:**
- Modify: `quickshell/AppLauncher.qml` (pinning logic, star icon, right-click, Ctrl+Enter)
- Modify: `quickshell/settings/LauncherPage.qml` (pinned apps management section)

- [ ] **Step 1: Add pin helper functions**

Add in `AppLauncher.qml` inside the `Scope` block:

```qml
function isPinned(appId) {
    return Config.launcherPinnedApps.indexOf(appId) >= 0;
}

function togglePin(appId) {
    let apps = Config.launcherPinnedApps.slice();
    let idx = apps.indexOf(appId);
    if (idx >= 0)
        apps.splice(idx, 1);
    else
        apps.push(appId);
    Config.set("launcher", "pinnedApps", apps);
}
```

- [ ] **Step 2: Update allApps sort to put pinned apps first**

Modify the `allApps` sort (updated in Task 6) to put pinned apps first, then frecency:

```qml
filtered.sort((a, b) => {
    let pinA = isPinned(a.id ?? "") ? 1 : 0;
    let pinB = isPinned(b.id ?? "") ? 1 : 0;
    if (pinA !== pinB) return pinB - pinA;
    // Among pinned: alphabetical. Among unpinned: frecency then alphabetical.
    if (pinA && pinB) {
        let nameA = (a.name ?? "").toLowerCase();
        let nameB = (b.name ?? "").toLowerCase();
        return nameA < nameB ? -1 : nameA > nameB ? 1 : 0;
    }
    let scoreA = getFrecencyScore(a.id ?? a.name ?? "");
    let scoreB = getFrecencyScore(b.id ?? b.name ?? "");
    if (scoreA !== scoreB) return scoreB - scoreA;
    let nameA = (a.name ?? "").toLowerCase();
    let nameB = (b.name ?? "").toLowerCase();
    return nameA < nameB ? -1 : nameA > nameB ? 1 : 0;
});
```

- [ ] **Step 3: Add star icon to the delegate**

In the delegate's `RowLayout` (inside the `appItem` Rectangle, around line 221-261), add a star icon after the genericName text. The star is only visible for pinned apps (always visible when search is empty, also visible when searching for recognition):

```qml
// Add after the genericName Text element and before the RowLayout closing brace:
IconStar {
    visible: root.isPinned(appItem.modelData.id ?? "")
    size: 14
    color: Config.yellow
    Layout.preferredWidth: visible ? 14 : 0
    Layout.preferredHeight: 14
}
```

- [ ] **Step 4: Add right-click to toggle pin**

Modify the `MouseArea` inside the delegate (the `appMouse` MouseArea, around line 263-282). Add `acceptedButtons: Qt.LeftButton | Qt.RightButton` and handle right-click:

```qml
MouseArea {
    id: appMouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton)
            root.togglePin(appItem.modelData.id ?? "");
        else
            root.launch(appItem.modelData);
    }
    onPositionChanged: (mouse) => {
        let screenX = appItem.mapToItem(null, mouse.x, mouse.y).x;
        let screenY = appItem.mapToItem(null, mouse.x, mouse.y).y;
        if (Math.abs(screenX - resultsView.lastMouseX) > 1 || Math.abs(screenY - resultsView.lastMouseY) > 1) {
            resultsView.lastMouseX = screenX;
            resultsView.lastMouseY = screenY;
            resultsView.keyboardNav = false;
            resultsView.currentIndex = appItem.index;
        }
    }
    onContainsMouseChanged: {
        if (containsMouse && !resultsView.keyboardNav)
            resultsView.currentIndex = appItem.index;
    }
}
```

- [ ] **Step 5: Add Ctrl+Enter keyboard shortcut to toggle pin**

In the `Keys.onReturnPressed` handler on the ListView (around line 285-288), add Ctrl+Enter handling:

```qml
Keys.onReturnPressed: (event) => {
    if (currentIndex >= 0 && currentIndex < root.filteredApps.length) {
        if (event.modifiers & Qt.ControlModifier)
            root.togglePin(root.filteredApps[currentIndex].id ?? "");
        else
            root.launch(root.filteredApps[currentIndex]);
    }
}
```

Also update the search box Enter handler (inside `Component.onCompleted`, around line 172-174) to pass through Ctrl+Enter:

```qml
inputItem.Keys.returnPressed.connect((event) => {
    if (root.filteredApps.length > 0) {
        if (event.modifiers & Qt.ControlModifier)
            root.togglePin(root.filteredApps[0].id ?? "");
        else
            root.launch(root.filteredApps[0]);
    }
});
```

Note: Check if the `Keys.returnPressed` signal in the searchBox's `Component.onCompleted` passes the event object. If it doesn't (the current code uses `connect` with no args), you may need to handle Ctrl+Enter only on the ListView and keep the searchBox handler simple. Verify during implementation.

- [ ] **Step 6: Add Pinned Apps section to LauncherPage.qml**

In `quickshell/settings/LauncherPage.qml`, add a "Pinned Apps" section after the "Hidden Apps" section (before the closing `}`). Follow the exact same pattern as the Hidden Apps section:

```qml
    Text { text: "Pinned Apps"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "These apps will appear at the top of the launcher with a star icon."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    Repeater {
        model: Config.launcherPinnedApps

        RowLayout {
            required property string modelData
            required property int index
            Layout.fillWidth: true; spacing: 6

            Rectangle {
                Layout.fillWidth: true; height: 26; radius: 4
                color: Config.surface0
                Text {
                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 8
                    text: modelData; color: Config.text; font.pixelSize: 11; font.family: Config.fontFamily
                }
            }

            Rectangle {
                width: 26; height: 26; radius: 4
                color: pinRmMouse.containsMouse ? Config.red : Config.surface0
                Behavior on color { ColorAnimation { duration: 80 } }
                IconX { anchors.centerIn: parent; size: 10; color: Config.text }
                MouseArea {
                    id: pinRmMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let apps = Config.launcherPinnedApps.slice();
                        apps.splice(index, 1);
                        Config.set("launcher", "pinnedApps", apps);
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true; spacing: 6

        Rectangle {
            Layout.fillWidth: true; height: 26; radius: 4
            color: Config.surface0; border.color: pinAddInput.activeFocus ? Config.blue : Config.surface1; border.width: 1
            TextInput {
                id: pinAddInput; anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter; color: Config.text
                font.pixelSize: 11; font.family: Config.fontFamily; clip: true
                onAccepted: {
                    if (text.trim() !== "") {
                        let apps = Config.launcherPinnedApps.slice();
                        apps.push(text.trim());
                        Config.set("launcher", "pinnedApps", apps);
                        text = "";
                    }
                }

                Text {
                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                    text: "Add app ID..."; color: Config.overlay0
                    font: pinAddInput.font; visible: !pinAddInput.text
                }
            }
        }

        Rectangle {
            width: 26; height: 26; radius: 4
            color: pinAddBtnMouse.containsMouse ? Config.blue : Config.surface0
            Behavior on color { ColorAnimation { duration: 80 } }
            IconPlus { anchors.centerIn: parent; size: 10; color: Config.text }
            MouseArea {
                id: pinAddBtnMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: pinAddInput.accepted()
            }
        }
    }
```

- [ ] **Step 7: Verify visually**

Open launcher:
- Right-click an app → it should appear with a star, sorted to top on next open
- Right-click again → unpin, star disappears
- Use keyboard: navigate to app, Ctrl+Enter → toggles pin
- Open Settings > Launcher → Pinned Apps section should show pinned app IDs

- [ ] **Step 8: Commit**

```bash
git add quickshell/AppLauncher.qml quickshell/settings/LauncherPage.qml
git commit -m "feat(launcher): add pinned/favorite apps with star icon and right-click toggle"
```

---

### Task 8: Close Animation

**Files:**
- Modify: `quickshell/AppLauncher.qml` (toggle function, animation states)

- [ ] **Step 1: Add closing state and modify toggle**

In `AppLauncher.qml`, add a `closing` property and modify the `toggle` function:

```qml
property bool visible: false
property bool closing: false
property string searchText: ""
```

Replace the `toggle` function:

```qml
function toggle() {
    if (root.visible) {
        root.closing = true;
    } else {
        root.closing = false;
        root.visible = true;
        root.searchText = "";
    }
}
```

- [ ] **Step 2: Change LazyLoader active condition**

The LazyLoader (line 76) should stay active during close animation. Change:

```qml
// Before:
active: root.visible

// After:
active: root.visible || root.closing
```

Wait — `root.visible` is set to true when opening, and `root.closing` is set to true when we want to close. The LazyLoader should stay active while closing. But we also need `root.visible` to remain true during close so the panel stays rendered. Let me restructure:

Actually, keep `active: root.visible` but don't set `visible = false` until the close animation finishes. The flow is:

1. Open: `visible = true`, `closing = false` → LazyLoader loads, open animations play
2. Close: `closing = true` → close animations play → on completion → `visible = false`, `closing = false` → LazyLoader unloads

So `toggle` becomes:

```qml
function toggle() {
    if (root.visible && !root.closing) {
        root.closing = true;
    } else if (!root.visible) {
        root.closing = false;
        root.visible = true;
        root.searchText = "";
    }
}
```

And `launch` becomes:

```qml
function launch(app) {
    recordLaunch(app.id ?? app.name ?? "");
    if (app.runInTerminal) {
        Quickshell.execDetached([Config.launcherTerminal].concat(app.command));
    } else {
        app.execute();
    }
    root.closing = true;
}
```

- [ ] **Step 3: Add close animations to the container and backdrop**

Replace the current entry animations on the container and backdrop with state-driven animations. In the `backdrop` Rectangle (around lines 97-114), replace the static `NumberAnimation on fadeIn` with:

```qml
Rectangle {
    id: backdrop
    anchors.fill: parent
    property real fadeIn: root.closing ? 0 : 1
    color: Qt.rgba(0, 0, 0, fadeIn * Config.launcherBackdropOpacity)

    Behavior on fadeIn {
        NumberAnimation {
            duration: Config.animLauncherFadeDuration
            easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.toggle()
    }
}
```

For the container (around lines 117-148), replace the entry animations with state-driven ones:

```qml
Rectangle {
    id: container
    anchors.centerIn: parent
    width: Config.launcherWidth
    height: Math.min(Config.launcherMaxHeight, searchBox.height + resultsView.contentHeight + 40)
    color: Theme.launcherBg
    radius: Config.launcherRadius
    border.color: Config.surface1
    border.width: 1

    scale: root.closing ? Config.animLauncherScaleFrom : 1.0
    opacity: root.closing ? 0 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: Config.animLauncherScaleDuration
            easing.type: root.closing ? Easing.InBack : Easing.OutBack
            easing.overshoot: Config.animLauncherOvershoot
        }
    }
    Behavior on opacity {
        NumberAnimation {
            id: containerFadeAnim
            duration: Config.animLauncherFadeDuration
            easing.type: Easing.OutCubic
        }
    }

    // When close animation finishes, hide the launcher
    onOpacityChanged: {
        if (root.closing && opacity === 0) {
            root.visible = false;
            root.closing = false;
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    // ... rest of container content unchanged
```

- [ ] **Step 4: Handle initial state on load**

The Behavior animations will try to animate from the initial property values when the LazyLoader first creates the component. We need the container to start at `scale: Config.animLauncherScaleFrom` and `opacity: 0` and animate to full when first loaded. The current approach with `Behavior` handles this: when the component loads, `root.closing` is `false`, so `scale` targets `1.0` and `opacity` targets `1.0`. Since the Behavior is active, it will animate from wherever Qt initializes (which will be the target values — no animation on first frame).

To fix this, explicitly set initial values and use a Component.onCompleted trigger:

```qml
scale: Config.animLauncherScaleFrom
opacity: 0

Component.onCompleted: {
    // Trigger entry animation after a frame
    Qt.callLater(() => {
        container.scale = Qt.binding(() => root.closing ? Config.animLauncherScaleFrom : 1.0);
        container.opacity = Qt.binding(() => root.closing ? 0 : 1.0);
    });
}
```

Similarly for the backdrop:

```qml
property real fadeIn: 0

Component.onCompleted: {
    Qt.callLater(() => {
        backdrop.fadeIn = Qt.binding(() => root.closing ? 0 : 1);
    });
}
```

- [ ] **Step 5: Verify visually**

Open the launcher:
- Should animate in (scale up + fade in) — same as before
- Press Escape or click backdrop → should animate out (scale down + fade out)
- Launch an app → should animate out before closing
- Reopen → should animate in cleanly again

- [ ] **Step 6: Commit**

```bash
git add quickshell/AppLauncher.qml
git commit -m "feat(launcher): add close animation (reverse of open)"
```

---

### Task 9: Final Integration Verification

- [ ] **Step 1: Full test pass**

Open the launcher and verify all features work together:

1. **Backdrop opacity**: Visible, matches config value
2. **Alphabetical sort**: Apps in A-Z order (when no frecency data)
3. **Fuzzy search**: "fire" → Firefox, "ffox" → Firefox, "ferfox" → Firefox
4. **Frecency**: Launch an app, reopen launcher, it appears higher in the list
5. **Pinned apps**: Right-click to pin, star appears, app moves to top, persists across reopens
6. **Close animation**: Smooth scale-down + fade-out on Escape, backdrop click, and app launch
7. **Pin + search interaction**: Pinned apps show star during search, but sort is by relevance
8. **Ctrl+Enter**: Pin/unpin via keyboard

- [ ] **Step 2: Commit any fixes**

If any integration issues are found, fix and commit.
