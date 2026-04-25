# Internet Speed Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a fused internet-speed + wifi widget to the status bar (sparkline + current rate + wifi icon), and a detailed speed section (graph, peak/avg, session totals) inside the existing wifi popup panel.

**Architecture:** Single polling singleton (`NetSpeedSampler`) reads `/proc/net/dev` every second via `FileView.reload()`, computes bytes/sec deltas across non-virtual interfaces, exposes reactive properties (`rxRate`, `txRate`, `rxHistory`, `txHistory`, peaks, session totals). Bar widget (`NetworkStatus.qml`) and popup speed section (`StatusBar.qml`) both bind reactively to the sampler — no duplicate polling.

**Tech Stack:** Quickshell (QML), QtQuick.Shapes for sparkline/graph, `Quickshell.Io.FileView` for `/proc/net/dev` reading. No test framework exists — verification is functional (curl traffic generation) + visual.

**Spec reference:** `docs/superpowers/specs/2026-04-25-internet-speed-widget-design.md`

**Testing note:** This is a QML dotfiles project with no automated test runner. Verification is done by reloading the shell (`pkill -USR1 quickshell` or restart) and observing behavior. Each task ends with an explicit "Verify" step describing what to look for.

---

## File Structure

**Create:**
- `quickshell/bar/NetSpeedSampler.qml` — singleton, polls `/proc/net/dev`, exposes reactive rates/history/peaks/session totals.

**Modify:**
- `quickshell/bar/NetworkStatus.qml` — add sparkline + rate text alongside existing wifi icon; widget becomes fused.
- `quickshell/StatusBar.qml` — insert speed section at top of `wifiContent` ColumnLayout (above existing "Wi-Fi" header row).
- `quickshell/Config.qml` — 3 new properties (`netSpeedPollInterval`, `netSpeedHistoryLength`, `speedWidgetWidth`) + their mapping in `_data.network`.
- `quickshell/defaults.toml` — 3 new keys under `[network]`.
- `quickshell/bar/qmldir` — register `NetSpeedSampler` as singleton.

---

## Task 1: Add config properties and defaults

**Files:**
- Modify: `quickshell/Config.qml:1274-1276`
- Modify: `quickshell/Config.qml:178` (network mapping)
- Modify: `quickshell/defaults.toml` (`[network]` section)

- [ ] **Step 1: Add new properties to Config.qml `===== NETWORK =====` section**

Edit `quickshell/Config.qml`, find the block:

```qml
    // ===== NETWORK =====

    property int networkPollInterval: _data?.network?.pollInterval ?? 10000
```

Replace with:

```qml
    // ===== NETWORK =====

    property int networkPollInterval: _data?.network?.pollInterval ?? 10000
    property int netSpeedPollInterval: _data?.network?.speedPollInterval ?? 1000
    property int netSpeedHistoryLength: _data?.network?.speedHistoryLength ?? 60
    property int speedWidgetWidth: _data?.network?.speedWidgetWidth ?? 100
```

- [ ] **Step 2: Extend network mapping in Config.qml `_data` block**

Find line ~178:

```qml
            network: { pollInterval: networkPollInterval },
```

Replace with:

```qml
            network: {
                pollInterval: networkPollInterval,
                speedPollInterval: netSpeedPollInterval,
                speedHistoryLength: netSpeedHistoryLength,
                speedWidgetWidth: speedWidgetWidth
            },
```

- [ ] **Step 3: Add keys to defaults.toml**

Edit `quickshell/defaults.toml`, find:

```toml
[network]
pollInterval = 10000
```

Replace with:

```toml
[network]
pollInterval = 10000
speedPollInterval = 1000
speedHistoryLength = 60
speedWidgetWidth = 100
```

- [ ] **Step 4: Verify shell still starts**

Run: `pkill -USR1 quickshell` (or restart quickshell if no reload signal configured).
Expected: bar still renders, no QML errors in `journalctl --user -b -u quickshell` (or stderr). Config change is passive — no visible change yet.

- [ ] **Step 5: Commit**

```bash
git add quickshell/Config.qml quickshell/defaults.toml
git commit -m "feat(network): add speed-widget config knobs"
```

---

## Task 2: Create NetSpeedSampler singleton (skeleton only, no polling yet)

**Files:**
- Create: `quickshell/bar/NetSpeedSampler.qml`
- Modify: `quickshell/bar/qmldir`

- [ ] **Step 1: Create the singleton skeleton**

Create `quickshell/bar/NetSpeedSampler.qml`:

```qml
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import ".."

QtObject {
    id: root

    // Reactive properties consumed by widget + popup
    property real rxRate: 0     // bytes/sec
    property real txRate: 0     // bytes/sec
    property var rxHistory: []  // last N samples, newest last
    property var txHistory: []  // last N samples, newest last
    property real peakRx: 0     // lifetime since shell start
    property real peakTx: 0
    property real sessionRx: 0  // cumulative bytes since shell start
    property real sessionTx: 0
    property bool hasData: false  // false until first delta computed

    // Internal previous sample
    property real _prevRx: 0
    property real _prevTx: 0
    property real _prevTime: 0
    property bool _havePrev: false

    // Interface exclude prefixes (virtual / loopback / container / vpn)
    readonly property var _excludePrefixes: [
        "lo", "br-", "br0", "bridge", "docker", "veth",
        "virbr", "tun", "tap", "wg"
    ]

    function _shouldIncludeIface(name) {
        for (let p of root._excludePrefixes) {
            if (name === p || name.startsWith(p)) return false;
        }
        return true;
    }
}
```

- [ ] **Step 2: Register singleton in bar/qmldir**

Edit `quickshell/bar/qmldir`, add line:

```
singleton NetSpeedSampler 1.0 NetSpeedSampler.qml
```

Final file should be:

```
Workspaces 1.0 Workspaces.qml
Clock 1.0 Clock.qml
Volume 1.0 Volume.qml
Battery 1.0 Battery.qml
MediaPlayer 1.0 MediaPlayer.qml
NetworkStatus 1.0 NetworkStatus.qml
Bluetooth 1.0 Bluetooth.qml
NotificationBell 1.0 NotificationBell.qml
SysTray 1.0 SysTray.qml
singleton NetSpeedSampler 1.0 NetSpeedSampler.qml
```

- [ ] **Step 3: Verify singleton loads**

Reload shell. Check stderr for QML errors. Singleton defines but isn't imported anywhere yet — it just needs to parse cleanly.

- [ ] **Step 4: Commit**

```bash
git add quickshell/bar/NetSpeedSampler.qml quickshell/bar/qmldir
git commit -m "feat(network): NetSpeedSampler singleton skeleton"
```

---

## Task 3: Wire `/proc/net/dev` reading + delta computation

**Files:**
- Modify: `quickshell/bar/NetSpeedSampler.qml`

- [ ] **Step 1: Add FileView + Timer + parsing**

Edit `quickshell/bar/NetSpeedSampler.qml`. Inside the `QtObject` body, add after the `_shouldIncludeIface` function:

```qml
    function _parseProcNetDev(text) {
        // /proc/net/dev has 2 header lines, then one line per iface.
        // Format: "  iface: rx_bytes rx_packets ... (8 rx cols) tx_bytes tx_packets ... (8 tx cols)"
        let lines = text.split("\n");
        let totalRx = 0;
        let totalTx = 0;
        for (let line of lines) {
            let colonIdx = line.indexOf(":");
            if (colonIdx < 0) continue;
            let name = line.substring(0, colonIdx).trim();
            if (!root._shouldIncludeIface(name)) continue;
            let rest = line.substring(colonIdx + 1).trim().split(/\s+/);
            if (rest.length < 16) continue;
            let rx = parseInt(rest[0]) || 0;
            let tx = parseInt(rest[8]) || 0;
            totalRx += rx;
            totalTx += tx;
        }
        return { rx: totalRx, tx: totalTx };
    }

    function _tick() {
        if (!_procFile) return;
        _procFile.reload();
    }

    function _onSample(text) {
        let parsed = root._parseProcNetDev(text);
        let now = Date.now();
        if (root._havePrev) {
            let elapsed = (now - root._prevTime) / 1000;
            if (elapsed <= 0) return;
            let dRx = parsed.rx - root._prevRx;
            let dTx = parsed.tx - root._prevTx;
            if (dRx < 0 || dTx < 0) {
                // counter wrap/reset — update baseline, skip rate
                root._prevRx = parsed.rx;
                root._prevTx = parsed.tx;
                root._prevTime = now;
                return;
            }
            root.rxRate = dRx / elapsed;
            root.txRate = dTx / elapsed;
            root.sessionRx += dRx;
            root.sessionTx += dTx;
            if (root.rxRate > root.peakRx) root.peakRx = root.rxRate;
            if (root.txRate > root.peakTx) root.peakTx = root.txRate;
            root.hasData = true;
        }
        root._prevRx = parsed.rx;
        root._prevTx = parsed.tx;
        root._prevTime = now;
        root._havePrev = true;
    }

    property var _procFile: FileView {
        path: "/proc/net/dev"
        onTextChanged: root._onSample(text())
    }

    property var _pollTimer: Timer {
        interval: Config.netSpeedPollInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._tick()
    }
```

- [ ] **Step 2: Verify polling works**

Reload shell. Sampler still isn't consumed by any visible widget, so no UI change expected. Confirm no QML errors.

To confirm data is flowing, temporarily add a debug `Component.onCompleted` at the end of `NetSpeedSampler.qml`:

```qml
    Component.onCompleted: {
        console.log("NetSpeedSampler loaded, polling /proc/net/dev @", Config.netSpeedPollInterval, "ms")
    }
```

Check stderr for the log line. Remove this debug after verifying.

- [ ] **Step 3: Add temporary rate logger to verify computation**

Temporarily add to `NetSpeedSampler.qml` after `onTextChanged: root._onSample(text())`:

```qml
    onRxRateChanged: console.log("rx:", rxRate.toFixed(0), "b/s   tx:", txRate.toFixed(0))
```

Run `curl -o /dev/null https://speed.cloudflare.com/__down?bytes=100000000` in another terminal. Expected: log lines should show rxRate climbing into MB/s range (values in millions of bytes/sec) while curl runs, then dropping to 0 when done.

Remove the debug log once verified.

- [ ] **Step 4: Commit**

```bash
git add quickshell/bar/NetSpeedSampler.qml
git commit -m "feat(network): NetSpeedSampler polls /proc/net/dev for rates"
```

---

## Task 4: Add history tracking

**Files:**
- Modify: `quickshell/bar/NetSpeedSampler.qml`

- [ ] **Step 1: Push rates into history arrays inside `_onSample`**

Edit `quickshell/bar/NetSpeedSampler.qml`. In `_onSample`, inside the `if (root._havePrev)` block, after `root.hasData = true;`, add:

```qml
            let maxLen = Config.netSpeedHistoryLength;
            let newRx = root.rxHistory.slice();
            newRx.push(root.rxRate);
            if (newRx.length > maxLen) newRx = newRx.slice(newRx.length - maxLen);
            root.rxHistory = newRx;

            let newTx = root.txHistory.slice();
            newTx.push(root.txRate);
            if (newTx.length > maxLen) newTx = newTx.slice(newTx.length - maxLen);
            root.txHistory = newTx;
```

(The slice-and-reassign pattern is needed because QML does not fire `propertyChanged` on in-place array mutation.)

- [ ] **Step 2: Verify history grows and caps**

Temporarily add to `NetSpeedSampler.qml`:

```qml
    onRxHistoryChanged: console.log("rxHistory len:", rxHistory.length, "newest:", rxHistory[rxHistory.length-1])
```

Reload shell. Watch the log for ~65 seconds. Expected: length grows 1, 2, 3 ... 60, then stays at 60 as new samples push out old.

Remove the debug log.

- [ ] **Step 3: Commit**

```bash
git add quickshell/bar/NetSpeedSampler.qml
git commit -m "feat(network): NetSpeedSampler tracks rate history"
```

---

## Task 5: Add rate formatters as reusable functions on the sampler

**Files:**
- Modify: `quickshell/bar/NetSpeedSampler.qml`

- [ ] **Step 1: Add `formatRate` and `formatBytes` helper functions**

Edit `quickshell/bar/NetSpeedSampler.qml`. Inside the `QtObject` body, add after `_onSample`:

```qml
    // Rate formatter: binary units, compact form for bar widget.
    // < 1 KiB/s  -> "—"
    // < 1 MiB/s  -> "234K"  (no decimal)
    // < 1 GiB/s  -> "2.4M"  (one decimal)
    // >=         -> "1.2G"
    function formatRate(bytesPerSec) {
        if (!root.hasData || bytesPerSec < 1024) return "—";
        const KB = 1024;
        const MB = 1024 * KB;
        const GB = 1024 * MB;
        if (bytesPerSec < MB) return Math.floor(bytesPerSec / KB) + "K";
        if (bytesPerSec < GB) return (Math.floor(bytesPerSec / MB * 10) / 10).toFixed(1) + "M";
        return (Math.floor(bytesPerSec / GB * 10) / 10).toFixed(1) + "G";
    }

    // Byte formatter for session / peak totals. Binary units, more precision.
    function formatBytes(bytes) {
        const KB = 1024;
        const MB = 1024 * KB;
        const GB = 1024 * MB;
        const TB = 1024 * GB;
        if (bytes < KB) return bytes + " B";
        if (bytes < MB) return (bytes / KB).toFixed(1) + " KB";
        if (bytes < GB) return (bytes / MB).toFixed(1) + " MB";
        if (bytes < TB) return (bytes / GB).toFixed(1) + " GB";
        return (bytes / TB).toFixed(1) + " TB";
    }

    // Rate formatter for popup (with units, longer form)
    function formatRateLong(bytesPerSec) {
        if (!root.hasData) return "—";
        const KB = 1024;
        const MB = 1024 * KB;
        const GB = 1024 * MB;
        if (bytesPerSec < KB) return "0 KB/s";
        if (bytesPerSec < MB) return (bytesPerSec / KB).toFixed(1) + " KB/s";
        if (bytesPerSec < GB) return (bytesPerSec / MB).toFixed(1) + " MB/s";
        return (bytesPerSec / GB).toFixed(1) + " GB/s";
    }
```

- [ ] **Step 2: Verify formatters compile**

Reload shell. No runtime change yet (functions unused by any UI). Confirm no QML parse errors.

- [ ] **Step 3: Commit**

```bash
git add quickshell/bar/NetSpeedSampler.qml
git commit -m "feat(network): add rate/bytes formatter helpers"
```

---

## Task 6: Add sparkline to NetworkStatus.qml (bar widget)

**Files:**
- Modify: `quickshell/bar/NetworkStatus.qml`

- [ ] **Step 1: Add sparkline Shape inside the widget**

Edit `quickshell/bar/NetworkStatus.qml`. Currently `netIcon` is the only visual child of the root Item. Replace the `Item { id: netIcon ... }` block with a RowLayout containing sparkline + existing icon + rate text.

First, update imports at the top of the file to include `QtQuick.Shapes` and `QtQuick.Layouts`. Current imports are:

```qml
import Quickshell
import Quickshell.Io
import QtQuick
import ".."
import "../icons"
```

Add:

```qml
import QtQuick.Shapes
import QtQuick.Layouts
```

- [ ] **Step 2: Widen the widget**

Find:

```qml
    width: Theme.fontSizeIcon + Theme.widgetPadding
```

Replace with:

```qml
    width: Config.speedWidgetWidth
```

- [ ] **Step 3: Replace `Item { id: netIcon ... }` with a RowLayout**

Find the block starting with `Item { id: netIcon` (lines ~87-114) and replace the entire `Item { id: netIcon ... }` with:

```qml
    RowLayout {
        id: netRow
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 6

        // Sparkline — download history
        Shape {
            id: sparkline
            Layout.preferredWidth: 40
            Layout.preferredHeight: Theme.fontSizeIcon
            Layout.alignment: Qt.AlignVCenter
            preferredRendererType: Shape.CurveRenderer

            property var history: NetSpeedSampler.rxHistory
            property real localMax: {
                let m = 1;
                for (let v of history) if (v > m) m = v;
                return m;
            }

            ShapePath {
                strokeColor: Theme.blue
                strokeWidth: 1.5
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathPolyline {
                    path: {
                        let pts = [];
                        let n = sparkline.history.length;
                        if (n < 2) return [Qt.point(0, sparkline.height), Qt.point(sparkline.width, sparkline.height)];
                        for (let i = 0; i < n; i++) {
                            let x = (i / (n - 1)) * sparkline.width;
                            let y = sparkline.height - (sparkline.history[i] / sparkline.localMax) * sparkline.height;
                            pts.push(Qt.point(x, y));
                        }
                        return pts;
                    }
                }
            }
        }

        // Existing wifi state icon
        Item {
            id: netIcon
            Layout.preferredWidth: Theme.fontSizeIcon
            Layout.preferredHeight: Theme.fontSizeIcon
            Layout.alignment: Qt.AlignVCenter

            IconWifiSector {
                visible: root.status === "wifi"
                size: Theme.fontSizeIcon
                signal: root.signalStrength
                color: root.iconColor
                anchors.centerIn: parent
                Behavior on color { ColorAnimation { duration: Theme.animDuration } }
            }
            IconEthernet {
                visible: root.status === "ethernet"
                size: Theme.fontSizeIcon
                color: root.iconColor
                anchors.centerIn: parent
                Behavior on color { ColorAnimation { duration: Theme.animDuration } }
            }
            IconWifiOff {
                visible: root.status === "disconnected"
                size: Theme.fontSizeIcon
                color: root.iconColor
                anchors.centerIn: parent
                Behavior on color { ColorAnimation { duration: Theme.animDuration } }
            }
        }

        // Rate text — dominant direction
        Text {
            id: rateText
            Layout.alignment: Qt.AlignVCenter
            property bool rxDominant: NetSpeedSampler.rxRate >= NetSpeedSampler.txRate
            text: NetSpeedSampler.formatRate(rxDominant ? NetSpeedSampler.rxRate : NetSpeedSampler.txRate)
            color: {
                if (!NetSpeedSampler.hasData || (NetSpeedSampler.rxRate < 1024 && NetSpeedSampler.txRate < 1024)) return Theme.overlay0;
                return rxDominant ? Theme.blue : Theme.green;
            }
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
            font.bold: true
            Behavior on color { ColorAnimation { duration: Theme.animDuration } }
        }
    }
```

- [ ] **Step 4: Reload and verify visual**

Reload shell. Expected:
- Bar widget wider (~100 px instead of ~icon-sized)
- Sparkline on left — flat line at first, begins drawing after ~2 samples
- Wifi sector / ethernet / off icon in middle (unchanged logic)
- Rate text on right — shows `"—"` initially, dim color

Generate traffic: `curl -o /dev/null https://speed.cloudflare.com/__down?bytes=500000000`
Expected:
- Sparkline animates with rx history (peaks visible)
- Rate text shows `"2.4M"`-style number, blue color
- After curl ends, rate returns to `"—"` dim

- [ ] **Step 5: Verify disconnected state**

`nmcli radio wifi off` (and unplug ethernet if present). Expected:
- Wifi icon goes to red IconWifiOff
- Rate text `"—"` dim
- Sparkline drops to flat line within 60 seconds (as zeros push out old samples)

Restore: `nmcli radio wifi on`.

- [ ] **Step 6: Commit**

```bash
git add quickshell/bar/NetworkStatus.qml
git commit -m "feat(network): fused bar widget — sparkline + icon + rate"
```

---

## Task 7: Add connection status line at top of popup

**Files:**
- Modify: `quickshell/StatusBar.qml`

- [ ] **Step 1: Insert connection status line in wifiContent**

Edit `quickshell/StatusBar.qml`. Find the `ColumnLayout { id: wifiContent` block (around line 521). The first child is currently `RowLayout { ... Text { text: "Wi-Fi" ... } ... }`.

Before that RowLayout, insert a new connection status row. Find:

```qml
                ColumnLayout {
                    id: wifiContent
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 24
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Wi-Fi"
```

Replace the portion starting with `RowLayout { Layout.fillWidth: true` and its first `Text { text: "Wi-Fi" ...` up to (but not including) the closing brace of that first RowLayout. Specifically, prepend a new RowLayout and replace the "Wi-Fi" Text's label content. New insertion goes between `spacing: 6` and `RowLayout { Layout.fillWidth: true`:

```qml
                    // Connection status line
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Network"
                            color: Theme.text
                            font.pixelSize: 14; font.family: Theme.fontFamily; font.bold: true
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: networkWidget.status === "disconnected" ? Theme.red : Theme.green
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: {
                                if (networkWidget.status === "disconnected") return "Offline";
                                let typeLabel = networkWidget.status === "ethernet" ? "Ethernet" : "Wi-Fi";
                                return typeLabel + (networkWidget.connectionName ? " • " + networkWidget.connectionName : "");
                            }
                            color: Theme.subtext0
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    Quill.Separator { Layout.fillWidth: true }
```

This goes before the existing `RowLayout` with the "Wi-Fi" Text.

Then change the old "Wi-Fi" title to avoid duplication. Find the existing:

```qml
                        Text {
                            text: "Wi-Fi"
                            color: Theme.text
                            font.pixelSize: 14; font.family: Theme.fontFamily; font.bold: true
                            Layout.fillWidth: true
                        }
```

Replace with:

```qml
                        Text {
                            text: "Wi-Fi Networks"
                            color: Theme.subtext0
                            font.pixelSize: 11; font.family: Theme.fontFamily; font.bold: true
                            Layout.fillWidth: true
                        }
```

- [ ] **Step 2: Verify popup header**

Reload shell. Hover the network widget in bar. Expected:
- Top line: "Network" (bold, 14px) and "● Wi-Fi • MyHouse" on the right, green dot
- Separator line
- Below: "Wi-Fi Networks" (subtext color, smaller) next to rescan button
- Existing network list unchanged below

Disconnect wifi. Expected: red dot, "Offline" label.

- [ ] **Step 3: Commit**

```bash
git add quickshell/StatusBar.qml
git commit -m "feat(network): add connection status line to popup header"
```

---

## Task 8: Add speed section (big numbers) in popup

**Files:**
- Modify: `quickshell/StatusBar.qml`

- [ ] **Step 1: Insert speed section after the separator from Task 7**

Edit `quickshell/StatusBar.qml`. Find the `Quill.Separator { Layout.fillWidth: true }` added in Task 7 (the first one after the new "Network" RowLayout). After it, insert:

```qml
                    // Speed section — big numbers
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: "↓ Download"
                                color: Theme.blue
                                font.pixelSize: 10
                                font.family: Theme.fontFamily
                                font.bold: true
                            }
                            Text {
                                text: NetSpeedSampler.formatRateLong(NetSpeedSampler.rxRate)
                                color: Theme.text
                                font.pixelSize: 18
                                font.family: Theme.fontFamily
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: "↑ Upload"
                                color: Theme.green
                                font.pixelSize: 10
                                font.family: Theme.fontFamily
                                font.bold: true
                                horizontalAlignment: Text.AlignRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: NetSpeedSampler.formatRateLong(NetSpeedSampler.txRate)
                                color: Theme.text
                                font.pixelSize: 18
                                font.family: Theme.fontFamily
                                font.bold: true
                                horizontalAlignment: Text.AlignRight
                                Layout.fillWidth: true
                            }
                        }
                    }
```

Also add the `bar` import at the top of `StatusBar.qml` so `NetSpeedSampler` singleton resolves. Check the imports near line 11:

```qml
import "bar"
```

This already exists — `bar/qmldir` now exports the singleton, so no change needed.

- [ ] **Step 2: Verify layout renders**

Reload shell. Hover widget. Expected:
- "Network" header
- Separator
- Download (blue label) + big number on left, Upload (green label) + big number on right
- "Wi-Fi Networks" header + list below

Rates show `"—"` until traffic starts, then climb during curl test.

- [ ] **Step 3: Commit**

```bash
git add quickshell/StatusBar.qml
git commit -m "feat(network): popup shows big up/down rate numbers"
```

---

## Task 9: Add graph to popup speed section

**Files:**
- Modify: `quickshell/StatusBar.qml`

- [ ] **Step 1: Insert graph Shape below the big-numbers RowLayout**

Edit `quickshell/StatusBar.qml`. After the speed-section RowLayout added in Task 8 (still inside `wifiContent` ColumnLayout), insert:

```qml
                    // Speed graph — overlaid rx filled + tx stroke
                    Shape {
                        id: speedGraph
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        Layout.topMargin: 4
                        preferredRendererType: Shape.CurveRenderer

                        property var rxHist: NetSpeedSampler.rxHistory
                        property var txHist: NetSpeedSampler.txHistory
                        property real localMax: {
                            let m = 1;
                            for (let v of rxHist) if (v > m) m = v;
                            for (let v of txHist) if (v > m) m = v;
                            return m;
                        }

                        function buildPath(hist, closed) {
                            let pts = [];
                            let n = hist.length;
                            if (n < 2) {
                                pts.push(Qt.point(0, speedGraph.height));
                                pts.push(Qt.point(speedGraph.width, speedGraph.height));
                                return pts;
                            }
                            for (let i = 0; i < n; i++) {
                                let x = (i / (n - 1)) * speedGraph.width;
                                let y = speedGraph.height - (hist[i] / speedGraph.localMax) * speedGraph.height;
                                pts.push(Qt.point(x, y));
                            }
                            if (closed) {
                                pts.push(Qt.point(speedGraph.width, speedGraph.height));
                                pts.push(Qt.point(0, speedGraph.height));
                            }
                            return pts;
                        }

                        // RX fill (light blue tint)
                        ShapePath {
                            strokeColor: "transparent"
                            strokeWidth: 0
                            fillColor: Qt.rgba(Theme.blue.r, Theme.blue.g, Theme.blue.b, 0.25)
                            PathPolyline { path: speedGraph.buildPath(speedGraph.rxHist, true) }
                        }

                        // RX line (solid blue)
                        ShapePath {
                            strokeColor: Theme.blue
                            strokeWidth: 1.5
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            PathPolyline { path: speedGraph.buildPath(speedGraph.rxHist, false) }
                        }

                        // TX line (solid green, thinner)
                        ShapePath {
                            strokeColor: Theme.green
                            strokeWidth: 1
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            PathPolyline { path: speedGraph.buildPath(speedGraph.txHist, false) }
                        }
                    }
```

- [ ] **Step 2: Verify graph renders and animates**

Reload shell. Hover network widget. Expected: 60px-tall graph below the big numbers. Initially empty (flat).

Run `curl -o /dev/null https://speed.cloudflare.com/__down?bytes=500000000` while popup open. Expected: blue filled area climbs, animates as history rolls, auto-scales y to latest peak.

Run an upload test: `dd if=/dev/zero bs=1M count=100 | curl -X POST --data-binary @- https://speed.cloudflare.com/__up` (may need different endpoint — any upload works). Expected: green line rises on top of the blue area.

- [ ] **Step 3: Commit**

```bash
git add quickshell/StatusBar.qml
git commit -m "feat(network): add speed history graph to popup"
```

---

## Task 10: Add stats row (peak + session totals)

**Files:**
- Modify: `quickshell/StatusBar.qml`

- [ ] **Step 1: Insert stats row below graph**

Edit `quickshell/StatusBar.qml`. After the `Shape { id: speedGraph ... }` block, insert:

```qml
                    // Stats row — peak + session totals
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 10

                        Text {
                            text: "peak ↓ " + NetSpeedSampler.formatRateLong(NetSpeedSampler.peakRx)
                            color: Theme.overlay0
                            font.pixelSize: 10
                            font.family: Theme.fontFamily
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: "↑ " + NetSpeedSampler.formatRateLong(NetSpeedSampler.peakTx)
                            color: Theme.overlay0
                            font.pixelSize: 10
                            font.family: Theme.fontFamily
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "session ↓ " + NetSpeedSampler.formatBytes(NetSpeedSampler.sessionRx)
                            color: Theme.overlay0
                            font.pixelSize: 10
                            font.family: Theme.fontFamily
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: "↑ " + NetSpeedSampler.formatBytes(NetSpeedSampler.sessionTx)
                            color: Theme.overlay0
                            font.pixelSize: 10
                            font.family: Theme.fontFamily
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    Quill.Separator { Layout.fillWidth: true; Layout.topMargin: 6 }
```

- [ ] **Step 2: Verify stats row renders and updates**

Reload shell. Hover widget. Expected: dim single-line row below graph showing `peak ↓ ...   ↑ ...   session ↓ ...   ↑ ...`.

Run traffic test. Expected:
- Peak values climb as rates hit new highs, never decrease
- Session values grow monotonically

- [ ] **Step 3: Commit**

```bash
git add quickshell/StatusBar.qml
git commit -m "feat(network): add peak + session totals to popup"
```

---

## Task 11: Final verification — edge cases

**Files:** none modified

- [ ] **Step 1: Suspend/resume test**

Let shell run for 10 minutes with some traffic to accumulate peak/session. Then:

```bash
systemctl suspend
```

Resume. Open popup. Expected:
- Peak + session values preserved (not reset)
- No giant fake rate spike (wrap guard kicks in)
- Sparkline + graph resume normal behavior within 2 seconds

- [ ] **Step 2: Interface swap test**

With wifi connected, plug in ethernet. Expected:
- Rates briefly dip (wrap guard skips one sample when iface set grows)
- Resume aggregating both interfaces' combined traffic
- No NaN, no double-counting

Unplug ethernet. Expected: same graceful handling.

- [ ] **Step 3: Theme switch test**

Open Settings, change accent/theme. Expected: sparkline blue stroke + rate text colors transition smoothly via existing `ColorAnimation` on Theme colors — no hard pops.

- [ ] **Step 4: Other-widget alignment check**

Compare positions of Volume, Battery, Bluetooth, NotificationBell in the bar against pre-change screenshots or memory. Expected: widgets still aligned correctly, no overlap, no squashing. If the network widget is too wide, tune `Config.speedWidgetWidth` in defaults.toml.

- [ ] **Step 5: No-commit step — final observation**

If everything checks out, no commit needed. If any edge case reveals a bug, create a follow-up fix commit.

---

## Out of scope (from spec, for reference)

- Per-interface breakdown in popup
- Disk-persisted daily totals
- Rate-limit / QoS controls
- Active speedtest probe
- Scrollable historical graph beyond 60s window

These are deferred. Do not add them in this plan.
