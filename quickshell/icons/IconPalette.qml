import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property real size: 24
    property color color: "#ffffff"
    property real strokeWidth: Math.max(1, size / 12)
    width: size; height: size
    clip: false
    layer.enabled: visible; layer.smooth: true

    ShapePath {
        strokeColor: root.color; strokeWidth: root.strokeWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M12 22a1 1 0 0 1 0-20 10 9 0 0 1 10 9 5 5 0 0 1-5 5h-2.25a1.75 1.75 0 0 0-1.4 2.8l.3.4a1.75 1.75 0 0 1-1.4 2.8z" }
    }
    ShapePath {
        fillColor: root.color; strokeColor: "transparent"
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M13 6.5a.5.5 0 1 0 1 0a.5.5 0 1 0-1 0" }
    }
    ShapePath {
        fillColor: root.color; strokeColor: "transparent"
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M17 10.5a.5.5 0 1 0 1 0a.5.5 0 1 0-1 0" }
    }
    ShapePath {
        fillColor: root.color; strokeColor: "transparent"
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M6 12.5a.5.5 0 1 0 1 0a.5.5 0 1 0-1 0" }
    }
    ShapePath {
        fillColor: root.color; strokeColor: "transparent"
        scale: Qt.size(root.size / 24, root.size / 24)
        PathSvg { path: "M8 7.5a.5.5 0 1 0 1 0a.5.5 0 1 0-1 0" }
    }
}
