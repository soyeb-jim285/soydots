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
