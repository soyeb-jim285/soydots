import QtQuick
import QtQuick.Layouts
import ".."
import "../icons"
import "../quill" as Quill

ColumnLayout {
    spacing: 6

    Text { text: "Dimensions"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 4 }

    SliderSetting { label: "Width"; section: "launcher"; key: "width"; value: Config.launcherWidth; from: 300; to: 900 }
    SliderSetting { label: "Max Height"; section: "launcher"; key: "maxHeight"; value: Config.launcherMaxHeight; from: 200; to: 800 }
    SliderSetting { label: "Radius"; section: "launcher"; key: "radius"; value: Config.launcherRadius; from: 0; to: 30 }
    SliderSetting { label: "Search Height"; section: "launcher"; key: "searchHeight"; value: Config.launcherSearchHeight; from: 28; to: 64 }
    SliderSetting { label: "Search Radius"; section: "launcher"; key: "searchRadius"; value: Config.launcherSearchRadius; from: 0; to: 24 }
    SliderSetting { label: "Item Height"; section: "launcher"; key: "itemHeight"; value: Config.launcherItemHeight; from: 28; to: 64 }
    SliderSetting { label: "Item Radius"; section: "launcher"; key: "itemRadius"; value: Config.launcherItemRadius; from: 0; to: 20 }
    SliderSetting { label: "Icon Size"; section: "launcher"; key: "iconSize"; value: Config.launcherIconSize; from: 16; to: 48 }
    SliderSetting { label: "Backdrop Opacity"; section: "launcher"; key: "backdropOpacity"; value: Config.launcherBackdropOpacity; from: 0; to: 0.25; decimals: 2; stepSize: 0.01 }
    SliderSetting { label: "Transparency"; section: "transparency"; key: "launcher"; value: Config._data?.transparency?.launcher ?? -1; from: -1; to: 1.0; decimals: 2; stepSize: 0.05; visible: Config.transparencyEnabled }

    Text { text: "Behavior"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    DropdownSetting {
        label: "Terminal"
        section: "launcher"
        key: "terminal"
        value: Config.launcherTerminal
        model: ["kitty", "alacritty", "foot", "wezterm", "ghostty", "konsole", "gnome-terminal", "xterm"]
    }

    Text { text: "Calculator"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "Inline math in the launcher. Supports +-*/%^, parens, functions (sin, sqrt, log, ln, ...), constants (pi, e, tau), factorial n!, and sum/prod loops. Prefix with / to force math mode."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enabled"; section: "launcher"; key: "calculatorEnabled"; value: Config.launcherCalculatorEnabled }
    ToggleSetting { label: "Copy Result on Enter"; section: "launcher"; key: "calculatorCopyOnEnter"; value: Config.launcherCalculatorCopyOnEnter }
    SliderSetting { label: "Decimal Places"; section: "launcher"; key: "calculatorDecimals"; value: Config.launcherCalculatorDecimals; from: 0; to: 15 }

    Text { text: "Web Search"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "Type a keyword followed by a space to search (e.g. 'g cats' for Google). When no apps match, engines appear as fallback suggestions. URLs use %s as the query placeholder."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enabled"; section: "launcher"; key: "webSearchEnabled"; value: Config.launcherWebSearchEnabled }
    TextSetting { label: "Browser WM Class"; section: "launcher"; key: "webSearchBrowserClass"; value: Config.launcherWebSearchBrowserClass }

    Text {
        text: "Optional: your browser's Hyprland window class (e.g. zen, firefox, chromium). When set, the launcher raises the browser window after opening a search. Find it via: hyprctl clients | grep class"
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    Repeater {
        model: Config.launcherWebSearchEngines

        RowLayout {
            id: engineRow
            required property string modelData
            required property int index
            Layout.fillWidth: true; spacing: 6
            property var parts: modelData.split("|")
            property string kw: parts[0] ?? ""
            property string nm: parts[1] ?? ""
            property string url: parts[2] ?? ""
            property string icn: parts[3] ?? ""

            Image {
                Layout.preferredWidth: 20; Layout.preferredHeight: 20
                visible: engineRow.icn !== "" && status === Image.Ready
                source: engineRow.icn !== "" ? Qt.resolvedUrl("../icons/engines/" + engineRow.icn + ".svg") : ""
                sourceSize: Qt.size(20, 20)
                smooth: true
            }

            Rectangle {
                Layout.preferredWidth: 48; height: 26; radius: 4
                color: Config.surface1
                Text {
                    anchors.centerIn: parent
                    text: engineRow.kw; color: Config.blue
                    font.pixelSize: 11; font.family: Config.fontFamily; font.bold: true
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 26; radius: 4
                color: Config.surface0
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 8
                    anchors.right: parent.right; anchors.rightMargin: 8
                    text: engineRow.nm + "  —  " + engineRow.url
                    color: Config.text; font.pixelSize: 11; font.family: Config.fontFamily
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                width: 26; height: 26; radius: 4
                color: engineRmMouse.containsMouse ? Config.red : Config.surface0
                Behavior on color { ColorAnimation { duration: 80 } }
                IconX { anchors.centerIn: parent; size: 10; color: Config.text }
                MouseArea {
                    id: engineRmMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let arr = Config.launcherWebSearchEngines.slice();
                        arr.splice(index, 1);
                        Config.set("launcher", "webSearchEngines", arr);
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true; spacing: 6

        Rectangle {
            Layout.preferredWidth: 60; height: 26; radius: 4
            color: Config.surface0; border.color: kwInput.activeFocus ? Config.blue : Config.surface1; border.width: 1
            TextInput {
                id: kwInput; anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6
                verticalAlignment: TextInput.AlignVCenter; color: Config.text
                font.pixelSize: 11; font.family: Config.fontFamily; clip: true
                Text {
                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                    text: "key"; color: Config.overlay0
                    font: kwInput.font; visible: !kwInput.text
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 100; height: 26; radius: 4
            color: Config.surface0; border.color: nmInput.activeFocus ? Config.blue : Config.surface1; border.width: 1
            TextInput {
                id: nmInput; anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6
                verticalAlignment: TextInput.AlignVCenter; color: Config.text
                font.pixelSize: 11; font.family: Config.fontFamily; clip: true
                Text {
                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                    text: "name"; color: Config.overlay0
                    font: nmInput.font; visible: !nmInput.text
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: 26; radius: 4
            color: Config.surface0; border.color: urlInput.activeFocus ? Config.blue : Config.surface1; border.width: 1
            TextInput {
                id: urlInput; anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6
                verticalAlignment: TextInput.AlignVCenter; color: Config.text
                font.pixelSize: 11; font.family: Config.fontFamily; clip: true
                onAccepted: addEngineBtn.add()
                Text {
                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                    text: "https://example.com/?q=%s"; color: Config.overlay0
                    font: urlInput.font; visible: !urlInput.text
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 80; height: 26; radius: 4
            color: Config.surface0; border.color: icnInput.activeFocus ? Config.blue : Config.surface1; border.width: 1
            TextInput {
                id: icnInput; anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6
                verticalAlignment: TextInput.AlignVCenter; color: Config.text
                font.pixelSize: 11; font.family: Config.fontFamily; clip: true
                onAccepted: addEngineBtn.add()
                Text {
                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                    text: "icon"; color: Config.overlay0
                    font: icnInput.font; visible: !icnInput.text
                }
            }
        }

        Rectangle {
            id: addEngineBtn
            width: 26; height: 26; radius: 4
            color: addEngineMouse.containsMouse ? Config.blue : Config.surface0
            Behavior on color { ColorAnimation { duration: 80 } }
            IconPlus { anchors.centerIn: parent; size: 10; color: Config.text }
            function add() {
                let k = kwInput.text.trim(), n = nmInput.text.trim(),
                    u = urlInput.text.trim(), ic = icnInput.text.trim();
                if (!k || !n || !u) return;
                if (k.indexOf("|") >= 0 || n.indexOf("|") >= 0
                    || u.indexOf("|") >= 0 || ic.indexOf("|") >= 0) return;
                let arr = Config.launcherWebSearchEngines.slice();
                arr.push(ic ? k + "|" + n + "|" + u + "|" + ic : k + "|" + n + "|" + u);
                Config.set("launcher", "webSearchEngines", arr);
                kwInput.text = ""; nmInput.text = ""; urlInput.text = ""; icnInput.text = "";
            }
            MouseArea {
                id: addEngineMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: addEngineBtn.add()
            }
        }
    }

    Text { text: "Hidden Apps"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "Apps matching these names will be hidden from the launcher."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    Repeater {
        model: Config.launcherHiddenApps

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
                color: rmMouse.containsMouse ? Config.red : Config.surface0
                Behavior on color { ColorAnimation { duration: 80 } }
                IconX { anchors.centerIn: parent; size: 10; color: Config.text }
                MouseArea {
                    id: rmMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let apps = Config.launcherHiddenApps.slice();
                        apps.splice(index, 1);
                        Config.set("launcher", "hiddenApps", apps);
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true; spacing: 6

        Rectangle {
            Layout.fillWidth: true; height: 26; radius: 4
            color: Config.surface0; border.color: addInput.activeFocus ? Config.blue : Config.surface1; border.width: 1
            TextInput {
                id: addInput; anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter; color: Config.text
                font.pixelSize: 11; font.family: Config.fontFamily; clip: true
                onAccepted: {
                    if (text.trim() !== "") {
                        let apps = Config.launcherHiddenApps.slice();
                        apps.push(text.trim());
                        Config.set("launcher", "hiddenApps", apps);
                        text = "";
                    }
                }

                Text {
                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                    text: "Add app name..."; color: Config.overlay0
                    font: addInput.font; visible: !addInput.text
                }
            }
        }

        Rectangle {
            width: 26; height: 26; radius: 4
            color: addBtnMouse.containsMouse ? Config.blue : Config.surface0
            Behavior on color { ColorAnimation { duration: 80 } }
            IconPlus { anchors.centerIn: parent; size: 10; color: Config.text }
            MouseArea {
                id: addBtnMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: addInput.accepted()
            }
        }
    }

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
}
