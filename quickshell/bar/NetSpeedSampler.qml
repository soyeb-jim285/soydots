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
        "virbr", "tun", "tap", "wg", "bond", "dummy", "sit"
    ]

    function _shouldIncludeIface(name) {
        for (let p of root._excludePrefixes) {
            if (name === p || name.startsWith(p)) return false;
        }
        return true;
    }

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
        if (!text || text.trim().length === 0) {
            return;
        }
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

            let maxLen = Config.netSpeedHistoryLength;
            let newRx = root.rxHistory.slice();
            newRx.push(root.rxRate);
            if (newRx.length > maxLen) newRx = newRx.slice(newRx.length - maxLen);
            root.rxHistory = newRx;

            let newTx = root.txHistory.slice();
            newTx.push(root.txRate);
            if (newTx.length > maxLen) newTx = newTx.slice(newTx.length - maxLen);
            root.txHistory = newTx;
        }
        root._prevRx = parsed.rx;
        root._prevTx = parsed.tx;
        root._prevTime = now;
        root._havePrev = true;
    }

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
}
