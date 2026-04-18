import Quickshell
import QtQuick
import QtQuick.Layouts
import ".."
import "../icons"
import "../quill" as Quill

ColumnLayout {
    id: root
    spacing: 6

    property string pinSearchText: ""
    property list<DesktopEntry> launcherApps: {
        let apps = Array.from(DesktopEntries.applications.values);
        apps.sort((a, b) => {
            let nameA = (a.name ?? "").toLowerCase();
            let nameB = (b.name ?? "").toLowerCase();
            return nameA < nameB ? -1 : nameA > nameB ? 1 : 0;
        });
        return apps;
    }
    property var pinSearchResults: {
        let q = pinSearchText.trim().toLowerCase();
        let pinned = {};
        for (let id of Config.launcherPinnedApps)
            pinned[id] = true;
        let out = [];
        for (let app of launcherApps) {
            let id = app.id ?? "";
            if (!id || pinned[id]) continue;
            if (!q) {
                out.push(app);
            } else {
                let name = (app.name ?? "").toLowerCase();
                let generic = (app.genericName ?? "").toLowerCase();
                if (name.includes(q) || generic.includes(q) || id.toLowerCase().includes(q))
                    out.push(app);
            }
            if (out.length >= 6) break;
        }
        return out;
    }
    property var universalTokens: parseUniversalTokens(Config.launcherUniversalSearchOrder)

    function parseUniversalTokens(order) {
        let out = [];
        for (let tok of String(order || "").split(",")) {
            tok = tok.trim();
            if (tok) out.push(tok);
        }
        return out;
    }

    function saveUniversalTokens(tokens) {
        Config.set("launcher", "universalSearchOrder", tokens.join(","));
    }

    function moveUniversalToken(index, dir) {
        let tokens = universalTokens.slice();
        let next = index + dir;
        if (next < 0 || next >= tokens.length) return;
        let tmp = tokens[index];
        tokens[index] = tokens[next];
        tokens[next] = tmp;
        saveUniversalTokens(tokens);
    }

    function removeUniversalToken(index) {
        let tokens = universalTokens.slice();
        tokens.splice(index, 1);
        saveUniversalTokens(tokens);
    }

    function addUniversalToken(token) {
        token = String(token || "").trim();
        if (!token) return;
        let tokens = universalTokens.slice();
        tokens.push(token);
        saveUniversalTokens(tokens);
    }

    function tokenLabel(token) {
        if (token === "apps") return "Apps";
        if (token === "systemActions") return "System Actions";
        if (token.startsWith("apps:")) return "Apps (" + token.split(":")[1] + ")";
        if (token.startsWith("packages:")) return "Packages (" + token.split(":")[1] + ")";
        if (token.startsWith("pacman:")) return "Pacman (" + token.split(":")[1] + ")";
        if (token.startsWith("flatpak:")) return "Flatpak (" + token.split(":")[1] + ")";
        if (token.startsWith("web:")) return "Web: " + token.split(":")[1];
        return token;
    }

    function tokenDescription(token) {
        if (token === "apps") return "All launcher apps";
        if (token === "systemActions") return "Power and session actions";
        if (token.startsWith("apps:")) return "Top matching apps";
        if (token.startsWith("packages:")) return "Merged pacman + Flatpak results";
        if (token.startsWith("pacman:")) return "Repo and AUR packages";
        if (token.startsWith("flatpak:")) return "Flathub app results";
        if (token.startsWith("web:")) return "One search shortcut row";
        return "Custom provider token";
    }

    function tokenColor(token) {
        if (token.startsWith("web:")) return Config.blue;
        if (token.startsWith("flatpak:")) return Config.blue;
        if (token.startsWith("pacman:") || token.startsWith("packages:")) return Config.peach;
        if (token === "systemActions") return Config.yellow;
        return Config.green;
    }

    function addPinnedApp(id) {
        id = String(id || "").trim();
        if (!id) return;
        let apps = Config.launcherPinnedApps.slice();
        if (apps.indexOf(id) >= 0) return;
        apps.push(id);
        Config.set("launcher", "pinnedApps", apps);
        pinSearchText = "";
        if (pinSearchInput) pinSearchInput.text = "";
    }

    function launcherAppById(id) {
        for (let app of launcherApps) {
            if ((app.id ?? "") === id) return app;
        }
        return null;
    }

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

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 170
        radius: 12
        color: Config.surface0
        border.color: Config.surface1
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                text: "Live Preview"
                color: Config.text
                font.pixelSize: 12
                font.family: Config.fontFamily
                font.bold: true
            }

            Text {
                text: "The preview now follows the cleaner Alfred-style layout: stronger search bar, flatter rows, quieter metadata."
                color: Config.subtext0
                font.pixelSize: 10
                font.family: Config.fontFamily
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 24, Math.max(250, Config.launcherWidth * 0.45))
                    height: Math.min(parent.height - 6, Math.max(92, Config.launcherMaxHeight * 0.22))
                    radius: Config.launcherRadius
                    color: Qt.rgba(Config.mantle.r, Config.mantle.g, Config.mantle.b, 0.92)
                    border.color: Config.surface1
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(26, Config.launcherSearchHeight * 0.6)
                            radius: Math.max(4, Config.launcherSearchRadius * 0.7)
                            color: "transparent"
                            border.color: "transparent"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                IconSearch {
                                    size: 12
                                    color: Config.overlay1
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Search apps, packages, web, math, paths..."
                                    color: Config.overlay0
                                    font.pixelSize: 12
                                    font.family: Config.fontFamily
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: Config.surface1
                            }
                        }

                        Repeater {
                            model: [
                                { title: "Pinned", subtitle: "Browser" },
                                { title: "Recent", subtitle: "Terminal" },
                                { title: "Package", subtitle: "AUR · Installed" }
                            ]

                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.max(20, Config.launcherItemHeight * 0.5)
                                radius: 8
                                color: index === 1
                                    ? Qt.rgba(Config.surface1.r, Config.surface1.g, Config.surface1.b, 0.72)
                                    : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Rectangle {
                                        width: 20
                                        height: 20
                                        radius: 6
                                        color: Qt.rgba(Config.surface1.r, Config.surface1.g, Config.surface1.b, 0.5)
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            text: modelData.title
                                            color: Config.text
                                            font.pixelSize: 10
                                            font.family: Config.fontFamily
                                        }

                                        Text {
                                            text: modelData.subtitle
                                            color: Config.overlay0
                                            font.pixelSize: 9
                                            font.family: Config.fontFamily
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

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

    Text { text: "Clipboard"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "Type the prefix to search your cliphist history. Enter copies the entry back to the clipboard."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enabled"; section: "launcher"; key: "clipboardEnabled"; value: Config.launcherClipboardEnabled }
    TextSetting { label: "Prefix"; section: "launcher"; key: "clipboardPrefix"; value: Config.launcherClipboardPrefix }
    SliderSetting { label: "Max Results"; section: "launcher"; key: "clipboardMax"; value: Config.launcherClipboardMax; from: 5; to: 200 }

    Text { text: "Emoji"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "Type the prefix followed by a search term (e.g. ':fire') to pick an emoji. Enter copies the glyph — paste with Ctrl+V."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enabled"; section: "launcher"; key: "emojiEnabled"; value: Config.launcherEmojiEnabled }
    TextSetting { label: "Prefix"; section: "launcher"; key: "emojiPrefix"; value: Config.launcherEmojiPrefix }

    Text { text: "Flatpak"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "Install or remove apps from flathub directly from the launcher. Type the prefix (default \"i\") followed by a search term (e.g. 'i firefox'). Enter installs (or removes, if already installed); Ctrl+Enter opens the Flathub page. Runs in your terminal so you can watch progress. Icons come from flatpak's appstream cache."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enabled"; section: "launcher"; key: "flatpakEnabled"; value: Config.launcherFlatpakEnabled }
    TextSetting { label: "Prefix"; section: "launcher"; key: "flatpakPrefix"; value: Config.launcherFlatpakPrefix }
    DropdownSetting {
        label: "Install Scope"
        section: "launcher"
        key: "flatpakScope"
        value: Config.launcherFlatpakScope
        model: ["user", "system"]
    }
    SliderSetting { label: "Max Results"; section: "launcher"; key: "flatpakMaxResults"; value: Config.launcherFlatpakMaxResults; from: 5; to: 50 }

    Text { text: "Pacman + AUR"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "Install or remove native Arch / AUR packages from the launcher. Type the prefix (default \"p\") followed by a search term (e.g. 'p steam'). Enter installs (or removes, if already installed) via yay, running in your terminal so you can watch progress and enter your sudo password. Empty prefix lists explicitly-installed packages."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enabled"; section: "launcher"; key: "pacmanEnabled"; value: Config.launcherPacmanEnabled }
    TextSetting { label: "Prefix"; section: "launcher"; key: "pacmanPrefix"; value: Config.launcherPacmanPrefix }
    SliderSetting { label: "Max Results"; section: "launcher"; key: "pacmanMaxResults"; value: Config.launcherPacmanMaxResults; from: 5; to: 100 }

    Text { text: "Universal Search"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "When you type a plain query (no prefix), merge results from multiple providers in a configurable order. Apps always stay at the top, while the list below controls the order of the other provider groups."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enabled"; section: "launcher"; key: "universalSearchEnabled"; value: Config.launcherUniversalSearchEnabled }

    Rectangle {
        Layout.fillWidth: true
        radius: 12
        color: Config.surface0
        border.color: Config.surface1
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                text: "Provider Order"
                color: Config.text
                font.pixelSize: 12
                font.family: Config.fontFamily
                font.bold: true
            }

            Text {
                text: "Apps stay first. Use the arrows to reorder the remaining provider groups."
                color: Config.subtext0
                font.pixelSize: 10
                font.family: Config.fontFamily
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            Repeater {
                model: root.universalTokens

                RowLayout {
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 28
                        radius: 999
                        color: Qt.rgba(root.tokenColor(modelData).r, root.tokenColor(modelData).g, root.tokenColor(modelData).b, 0.14)
                        border.color: root.tokenColor(modelData)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: root.tokenLabel(modelData)
                            color: root.tokenColor(modelData)
                            font.pixelSize: 10
                            font.family: Config.fontFamily
                            font.bold: true
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: 6
                        color: Config.surface1

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            text: root.tokenDescription(modelData) + "  -  " + modelData
                            color: Config.text
                            font.pixelSize: 11
                            font.family: Config.fontFamily
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        width: 26; height: 26; radius: 6
                        color: orderUpMouse.containsMouse ? Config.blue : Config.surface1
                        Text {
                            anchors.centerIn: parent
                            text: "↑"
                            color: Config.text
                            font.pixelSize: 12
                            font.family: Config.fontFamily
                            font.bold: true
                        }
                        MouseArea {
                            id: orderUpMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.moveUniversalToken(index, -1)
                        }
                    }

                    Rectangle {
                        width: 26; height: 26; radius: 6
                        color: orderDownMouse.containsMouse ? Config.blue : Config.surface1
                        Text {
                            anchors.centerIn: parent
                            text: "↓"
                            color: Config.text
                            font.pixelSize: 12
                            font.family: Config.fontFamily
                            font.bold: true
                        }
                        MouseArea {
                            id: orderDownMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.moveUniversalToken(index, 1)
                        }
                    }

                    Rectangle {
                        width: 26; height: 26; radius: 6
                        color: orderRemoveMouse.containsMouse ? Config.red : Config.surface1
                        IconX { anchors.centerIn: parent; size: 10; color: Config.text }
                        MouseArea {
                            id: orderRemoveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.removeUniversalToken(index)
                        }
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: 6

                Repeater {
                    model: [
                        { label: "Apps", token: "apps:8" },
                        { label: "Packages", token: "packages:4" },
                        { label: "Google", token: "web:g" },
                        { label: "ChatGPT", token: "web:gpt" },
                        { label: "Perplexity", token: "web:per" },
                        { label: "System", token: "systemActions" }
                    ]

                    Quill.Button {
                        required property var modelData
                        text: "+ " + modelData.label
                        variant: "secondary"
                        size: "small"
                        onClicked: root.addUniversalToken(modelData.token)
                    }
                }
            }
        }
    }

    TextSetting { label: "Raw Order"; section: "launcher"; key: "universalSearchOrder"; value: Config.launcherUniversalSearchOrder }

    Text { text: "URL &amp; Path"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "Detect URLs (http, https, file, ftp, mailto) and filesystem paths (/, ~/, ./) in the query, and open them via xdg-open."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enabled"; section: "launcher"; key: "urlPathEnabled"; value: Config.launcherUrlPathEnabled }

    Text { text: "Shell Runner"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "Prefix the query with the shell prefix (default \">\") to run the rest as a shell command. Runs detached — for feedback, pipe to wl-copy, notify-send, or a file."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enabled"; section: "launcher"; key: "shellRunnerEnabled"; value: Config.launcherShellRunnerEnabled }
    TextSetting { label: "Prefix"; section: "launcher"; key: "shellRunnerPrefix"; value: Config.launcherShellRunnerPrefix }
    TextSetting { label: "Shell"; section: "launcher"; key: "shellRunnerShell"; value: Config.launcherShellRunnerShell }

    Text { text: "System Actions"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "Surface lock, logout, suspend, hibernate, reboot, and shutdown as launcher results when the query matches their name or keywords."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enabled"; section: "launcher"; key: "systemActionsEnabled"; value: Config.launcherSystemActionsEnabled }

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
                onAccepted: addEngineBtn.add()
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
                onAccepted: addEngineBtn.add()
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

    Rectangle {
        Layout.fillWidth: true
        radius: 10
        color: Config.surface0
        border.color: Config.surface1
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            Text {
                text: "Engine Preview"
                color: Config.text
                font.pixelSize: 11
                font.family: Config.fontFamily
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 54
                    Layout.preferredHeight: 24
                    radius: 999
                    color: Config.surface1

                    Text {
                        anchors.centerIn: parent
                        text: kwInput.text.trim() !== "" ? kwInput.text.trim() : "key"
                        color: Config.blue
                        font.pixelSize: 11
                        font.family: Config.fontFamily
                        font.bold: true
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: (nmInput.text.trim() !== "" ? nmInput.text.trim() : "Engine name")
                        + "  -  "
                        + (urlInput.text.trim() !== "" ? urlInput.text.trim() : "https://example.com/?q=%s")
                    color: Config.text
                    font.pixelSize: 11
                    font.family: Config.fontFamily
                    elide: Text.ElideRight
                }
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
                    text: modelData
                    color: Config.text; font.pixelSize: 11; font.family: Config.fontFamily
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
                    anchors.right: parent.right; anchors.rightMargin: 8
                    text: {
                        let app = root.launcherAppById(modelData);
                        return app ? ((app.name ?? modelData) + "  -  " + modelData) : modelData;
                    }
                    color: Config.text; font.pixelSize: 11; font.family: Config.fontFamily
                    elide: Text.ElideRight
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

    Rectangle {
        Layout.fillWidth: true
        radius: 12
        color: Config.surface0
        border.color: Config.surface1
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                text: "Add From Installed Apps"
                color: Config.text
                font.pixelSize: 12
                font.family: Config.fontFamily
                font.bold: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 6
                color: Config.surface1
                border.color: pinSearchInput.activeFocus ? Config.blue : Config.surface1
                border.width: 1

                TextInput {
                    id: pinSearchInput
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: Config.text
                    font.pixelSize: 11
                    font.family: Config.fontFamily
                    clip: true
                    onTextChanged: root.pinSearchText = text

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Search installed apps by name or ID..."
                        color: Config.overlay0
                        font: pinSearchInput.font
                        visible: !pinSearchInput.text
                    }
                }
            }

            Repeater {
                model: root.pinSearchResults

                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 6

                    Item {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22

                        Image {
                            anchors.fill: parent
                            property string _icon: modelData.icon ?? ""
                            property string _primary: Quickshell.iconPath(_icon, "application-x-executable")
                            property string _fallback: Quickshell.iconPath("application-x-executable", "")
                            source: _primary !== "" ? _primary : _fallback
                            sourceSize: Qt.size(22, 22)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        radius: 6
                        color: Config.surface1

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            spacing: 1

                            Text {
                                text: modelData.name ?? modelData.id ?? ""
                                color: Config.text
                                font.pixelSize: 11
                                font.family: Config.fontFamily
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: modelData.id ?? ""
                                color: Config.overlay0
                                font.pixelSize: 9
                                font.family: Config.fontFamily
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }

                    Rectangle {
                        width: 30; height: 30; radius: 6
                        color: pinAddSearchMouse.containsMouse ? Config.green : Config.surface1
                        IconPlus { anchors.centerIn: parent; size: 12; color: Config.text }
                        MouseArea {
                            id: pinAddSearchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.addPinnedApp(modelData.id ?? "")
                        }
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
                        root.addPinnedApp(text.trim());
                        text = "";
                    }
                }

                Text {
                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                    text: "Add app ID (advanced)..."; color: Config.overlay0
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
