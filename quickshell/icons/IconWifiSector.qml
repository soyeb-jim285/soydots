import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property real size: 24
    property color color: "#ffffff"
    property color dimColor: Qt.rgba(color.r, color.g, color.b, 0.2)
    // signal: 0-100, controls which sectors are filled
    // 0 = all dim, 1-33 = inner, 34-66 = +middle, 67-100 = +outer
    property int signal: 100
    width: size; height: size
    clip: false
    layer.enabled: visible; layer.smooth: true

    // Outer sector (signal > 66)
    ShapePath {
        strokeColor: "transparent"; strokeWidth: 0
        fillColor: root.signal > 66 ? root.color : root.dimColor
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M12 22 L0 10 A17 17 0 0 1 24 10 Z" }
    }
    // Middle sector (signal > 33)
    ShapePath {
        strokeColor: "transparent"; strokeWidth: 0
        fillColor: root.signal > 33 ? root.color : root.dimColor
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M12 22 L4.2 14.2 A11 11 0 0 1 19.8 14.2 Z" }
    }
    // Inner sector (signal > 0)
    ShapePath {
        strokeColor: "transparent"; strokeWidth: 0
        fillColor: root.signal > 0 ? root.color : root.dimColor
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M12 22 L8.1 18.1 A5.5 5.5 0 0 1 15.9 18.1 Z" }
    }
}
