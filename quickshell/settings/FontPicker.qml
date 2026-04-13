import QtQuick
import QtQuick.Layouts
import ".."
import "../quill" as Quill

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 4

    property string label: ""
    property string section: ""
    property string key: ""
    property string value: ""
    property bool previewFonts: true
    property bool expanded: false

    property string filter: ""
    property var allFonts: Config.systemFonts
    property var filteredModel: {
        let lf = filter.toLowerCase();
        if (lf === "") return allFonts;
        return allFonts.filter(f => f.toLowerCase().indexOf(lf) >= 0);
    }

    // Label + current value + expand toggle
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Text {
            visible: root.label !== ""
            text: root.label
            color: Config.text
            font.pixelSize: 12
            font.family: Config.fontFamily
            Layout.preferredWidth: 140
        }

        Rectangle {
            Layout.fillWidth: true
            height: 34; radius: 6
            color: Config.surface0
            border.color: root.expanded ? Config.blue : Config.surface1
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 100 } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 8; anchors.rightMargin: 8

                Text {
                    text: root.value || "(System Default)"
                    color: root.value ? Config.text : Config.subtext0
                    font.pixelSize: 12
                    font.family: root.value || Config.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - chevron.width
                    elide: Text.ElideRight
                }
                Text {
                    id: chevron
                    text: root.expanded ? "\uf077" : "\uf078"
                    color: Config.overlay0
                    font.family: Config.iconFont
                    font.pixelSize: 10
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.expanded = !root.expanded;
                    if (root.expanded) searchInput.forceActiveFocus();
                }
            }
        }
    }

    // Expandable font list
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: root.expanded ? 240 : 0
        radius: 8
        color: Config.mantle
        border.color: Config.surface1
        border.width: root.expanded ? 1 : 0
        clip: true

        Behavior on Layout.preferredHeight { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 2

            // Search
            Rectangle {
                Layout.fillWidth: true
                height: 30; radius: 6
                color: Config.surface0
                border.color: searchInput.activeFocus ? Config.blue : Config.surface1
                border.width: 1

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 8; anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: Config.text
                    font.pixelSize: 12; font.family: Config.fontFamily
                    clip: true
                    onTextChanged: root.filter = text

                    Text {
                        visible: !searchInput.text
                        text: "Search fonts..."
                        color: Config.overlay0
                        font.pixelSize: 12; font.family: Config.fontFamily
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // System default
            Rectangle {
                Layout.fillWidth: true
                height: 28; radius: 4
                visible: root.filter === "" || "system default".indexOf(root.filter.toLowerCase()) >= 0
                color: root.value === ""
                    ? Qt.rgba(Qt.color(Config.blue).r, Qt.color(Config.blue).g, Qt.color(Config.blue).b, 0.15)
                    : defaultMouse.containsMouse ? Config.surface1 : "transparent"

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 8
                    text: "(System Default)"
                    color: root.value === "" ? Config.blue : Config.subtext0
                    font.pixelSize: 11; font.italic: true
                    font.family: Config.fontFamily
                }

                MouseArea {
                    id: defaultMouse
                    anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Config.set(root.section, root.key, "");
                        root.expanded = false;
                        root.filter = ""; searchInput.text = "";
                    }
                }
            }

            // Font list
            ListView {
                id: fontList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.filteredModel
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    width: fontList.width
                    height: 28; radius: 4
                    color: modelData === root.value
                        ? Qt.rgba(Qt.color(Config.blue).r, Qt.color(Config.blue).g, Qt.color(Config.blue).b, 0.15)
                        : itemMouse.containsMouse ? Config.surface1 : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.right: parent.right; anchors.rightMargin: 8
                        text: modelData
                        color: modelData === root.value ? Config.blue : Config.text
                        font.pixelSize: 11
                        font.family: root.previewFonts ? modelData : Config.fontFamily
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Config.set(root.section, root.key, modelData);
                            root.expanded = false;
                            root.filter = ""; searchInput.text = "";
                        }
                    }
                }
            }
        }
    }

    onExpandedChanged: {
        if (expanded) {
            let idx = filteredModel.indexOf(value);
            if (idx >= 0) fontList.positionViewAtIndex(idx, ListView.Center);
        }
    }
}
