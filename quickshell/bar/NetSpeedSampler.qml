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
}
