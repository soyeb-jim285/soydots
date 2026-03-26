import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property real size: 24
    property color color: "#ffffff"
    property color dimColor: Qt.rgba(color.r, color.g, color.b, 0.2)
    property real strokeWidth: Math.max(1, size / 12)
    // signal: 0-100, controls which arcs are lit
    // 0 = dot only, 1-33 = 1 arc, 34-66 = 2 arcs, 67-100 = 3 arcs
    property int signal: 100
    width: size; height: size
    clip: false
    layer.enabled: visible; layer.smooth: true

    // Dot (always shown)
    ShapePath {
        strokeColor: root.color; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M12 20h.01" }
    }
    // Inner arc (signal > 0)
    ShapePath {
        strokeColor: root.signal > 0 ? root.color : root.dimColor; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M8.5 16.429a5 5 0 0 1 7 0" }
    }
    // Middle arc (signal > 33)
    ShapePath {
        strokeColor: root.signal > 33 ? root.color : root.dimColor; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M5 12.859a10 10 0 0 1 14 0" }
    }
    // Outer arc (signal > 66)
    ShapePath {
        strokeColor: root.signal > 66 ? root.color : root.dimColor; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M2 8.82a15 15 0 0 1 20 0" }
    }
}
