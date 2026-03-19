pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

QtObject {
    id: config

    // ===== TOML Parser/Writer =====

    function parseTOML(text) {
        let result = {};
        let currentSection = "";
        let lines = (text || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim();
            if (line === "" || line.startsWith("#")) continue;

            // Section header
            if (line.startsWith("[") && line.endsWith("]")) {
                currentSection = line.slice(1, -1).trim();
                if (!result[currentSection]) result[currentSection] = {};
                continue;
            }

            // Key = value
            let eqIdx = line.indexOf("=");
            if (eqIdx < 0) continue;
            let key = line.substring(0, eqIdx).trim();
            let val = line.substring(eqIdx + 1).trim();

            // Parse value
            let parsed;
            if (val.startsWith('"') && val.endsWith('"')) {
                parsed = val.slice(1, -1);
            } else if (val === "true") {
                parsed = true;
            } else if (val === "false") {
                parsed = false;
            } else if (val.startsWith("[")) {
                // Array - parse simple string/number arrays
                let inner = val.slice(1, -1).trim();
                if (inner === "") {
                    parsed = [];
                } else {
                    parsed = [];
                    let items = [];
                    let current = "";
                    let inStr = false;
                    for (let c = 0; c < inner.length; c++) {
                        let ch = inner[c];
                        if (ch === '"') {
                            inStr = !inStr;
                            current += ch;
                        } else if (ch === ',' && !inStr) {
                            items.push(current.trim());
                            current = "";
                        } else {
                            current += ch;
                        }
                    }
                    if (current.trim() !== "") items.push(current.trim());
                    for (let item of items) {
                        if (item.startsWith('"') && item.endsWith('"'))
                            parsed.push(item.slice(1, -1));
                        else if (item === "true") parsed.push(true);
                        else if (item === "false") parsed.push(false);
                        else parsed.push(Number(item));
                    }
                }
            } else if (val.includes(".")) {
                parsed = parseFloat(val);
            } else {
                parsed = parseInt(val);
            }

            if (currentSection !== "") {
                if (!result[currentSection]) result[currentSection] = {};
                result[currentSection][key] = parsed;
            }
        }
        return result;
    }

    function writeTOML(data) {
        let lines = [];
        let sections = Object.keys(data).sort();
        for (let i = 0; i < sections.length; i++) {
            let section = sections[i];
            if (i > 0) lines.push("");
            lines.push("[" + section + "]");
            let keys = Object.keys(data[section]).sort();
            for (let key of keys) {
                let val = data[section][key];
                if (typeof val === "string")
                    lines.push(key + ' = "' + val + '"');
                else if (typeof val === "boolean")
                    lines.push(key + " = " + (val ? "true" : "false"));
                else if (Array.isArray(val)) {
                    let items = val.map(v => typeof v === "string" ? '"' + v + '"' : String(v));
                    lines.push(key + " = [" + items.join(", ") + "]");
                } else
                    lines.push(key + " = " + val);
            }
        }
        lines.push("");
        return lines.join("\n");
    }

    // ===== File Persistence =====

    property var _fileView: FileView {
        path: Qt.resolvedUrl(".") + "settings.toml"
        watchChanges: true
        blockLoading: false
        preload: true
        onTextChanged: config._reload()
    }

    property var _data: ({})

    function _reload() {
        let text = _fileView.text();
        _data = parseTOML(text);
    }

    // Debounced save
    property var _saveTimer: Timer {
        interval: 300
        onTriggered: config._doSave()
    }

    function _doSave() {
        // Build data from current property values
        let d = {
            appearance: {
                base: base, mantle: mantle, crust: crust,
                surface0: surface0, surface1: surface1, surface2: surface2,
                overlay0: overlay0, overlay1: overlay1,
                text: text, subtext0: subtext0, subtext1: subtext1,
                red: red, green: green, yellow: yellow, blue: blue,
                mauve: mauve, pink: pink, teal: teal, peach: peach, lavender: lavender,
                fontFamily: fontFamily, iconFont: iconFont,
                fontSizeSmall: fontSizeSmall, fontSize: fontSize, fontSizeIcon: fontSizeIcon,
                transparencyEnabled: transparencyEnabled, transparencyLevel: transparencyLevel
            },
            transparency: {
                bar: _data?.transparency?.bar ?? -1,
                launcher: _data?.transparency?.launcher ?? -1,
                clipboard: _data?.transparency?.clipboard ?? -1,
                notifCenter: _data?.transparency?.notifCenter ?? -1,
                notifPopup: _data?.transparency?.notifPopup ?? -1,
                osd: _data?.transparency?.osd ?? -1,
                settings: _data?.transparency?.settings ?? -1,
                animPicker: _data?.transparency?.animPicker ?? -1
            },
            bar: {
                height: barHeight, margin: barMargin, radius: barRadius,
                widgetSpacing: widgetSpacing, widgetPadding: widgetPadding, widgetRadius: widgetRadius
            },
            workspaces: {
                count: workspaceCount, focusedWidth: workspaceFocusedWidth,
                unfocusedWidth: workspaceUnfocusedWidth, dotHeight: workspaceDotHeight,
                spacing: workspaceSpacing, dotRadius: workspaceDotRadius, overshoot: workspaceOvershoot
            },
            clock: {
                timeFormat: clockTimeFormat, dateFormat: clockDateFormat, spacing: clockSpacing,
                separatorHeight: clockSeparatorHeight
            },
            volume: { scrollIncrement: volumeScrollIncrement },
            battery: { greenThreshold: batteryGreenThreshold, yellowThreshold: batteryYellowThreshold },
            media: { maxWidth: mediaMaxWidth },
            systray: { iconSize: sysTrayIconSize, spacing: sysTraySpacing, opacity: sysTrayOpacity },
            network: { pollInterval: networkPollInterval },
            wifi: {
                panelWidth: wifiPanelWidth, itemHeight: wifiItemHeight, itemRadius: wifiItemRadius,
                maxListHeight: wifiMaxListHeight, rescanDelay: wifiRescanDelay
            },
            bluetooth: {
                panelWidth: btPanelWidth, deviceHeight: btDeviceHeight,
                deviceIconSize: btDeviceIconSize, deviceRadius: btDeviceRadius,
                scanTimeout: btScanTimeout, maxListHeight: btMaxListHeight
            },
            calendar: {
                width: calendarWidth, cellWidth: calendarCellWidth,
                cellHeight: calendarCellHeight, cellRadius: calendarCellRadius
            },
            notifications: {
                popupWidth: notifPopupWidth, popupWindowWidth: notifPopupWindowWidth,
                popupHeight: notifPopupHeight, popupRadius: notifPopupRadius,
                popupBgColor: notifPopupBgColor, maxToasts: notifMaxToasts,
                defaultTimeout: notifDefaultTimeout, maxHistory: notifMaxHistory,
                popupSpacing: notifPopupSpacing,
                centerWidth: notifCenterWidth, centerRadius: notifCenterRadius,
                centerSlideFrom: notifCenterSlideFrom, centerSlideTo: notifCenterSlideTo,
                centerOverlayOpacity: notifCenterOverlayOpacity,
                qsColumns: notifQsColumns, qsSpacing: notifQsSpacing,
                qsButtonHeight: notifQsButtonHeight, qsButtonRadius: notifQsButtonRadius,
                qsIconSize: notifQsIconSize, qsLabelSize: notifQsLabelSize
            },
            launcher: {
                width: launcherWidth, maxHeight: launcherMaxHeight, radius: launcherRadius,
                searchHeight: launcherSearchHeight, searchRadius: launcherSearchRadius,
                itemHeight: launcherItemHeight, itemRadius: launcherItemRadius,
                iconSize: launcherIconSize,
                backdropOpacity: launcherBackdropOpacity,
                hiddenApps: launcherHiddenApps, terminal: launcherTerminal
            },
            clipboard: {
                width: clipboardWidth, height: clipboardHeight, radius: clipboardRadius,
                searchHeight: clipboardSearchHeight, searchRadius: clipboardSearchRadius,
                itemHeight: clipboardItemHeight, imageItemHeight: clipboardImageItemHeight,
                backdropOpacity: clipboardBackdropOpacity
            },
            osd: {
                bottomMargin: osdBottomMargin, height: osdHeight, radius: osdRadius,
                bgColor: osdBgColor, progressWidth: osdProgressWidth, progressHeight: osdProgressHeight,
                hideTimeout: osdHideTimeout, readyDelay: osdReadyDelay
            },
            animations: {
                duration: animDuration, durationFast: animDurationFast,
                panelDuration: animPanelDuration, panelCloseDuration: animPanelCloseDuration,
                popupSlideDuration: animPopupSlideDuration, popupFadeDuration: animPopupFadeDuration,
                launcherScaleFrom: animLauncherScaleFrom, launcherScaleDuration: animLauncherScaleDuration,
                launcherOvershoot: animLauncherOvershoot, launcherFadeDuration: animLauncherFadeDuration,
                clipboardScaleFrom: animClipboardScaleFrom, clipboardScaleDuration: animClipboardScaleDuration,
                clipboardOvershoot: animClipboardOvershoot, clipboardFadeDuration: animClipboardFadeDuration,
                osdScaleFrom: animOsdScaleFrom, osdScaleDuration: animOsdScaleDuration,
                osdFadeDuration: animOsdFadeDuration,
                pickerScaleFrom: animPickerScaleFrom, pickerScaleDuration: animPickerScaleDuration,
                pickerFadeDuration: animPickerFadeDuration, pickerBackdropOpacity: animPickerBackdropOpacity
            },
            nightlight: { temperature: nightLightTemp },
            animationPicker: {
                width: animPickerWidth, height: animPickerHeight, radius: animPickerRadius,
                columns: animPickerColumns, spacing: animPickerSpacing,
                selectedPreset: animPickerSelectedPreset
            },
            batteryPopup: { width: batteryPopupWidth, radius: batteryPopupRadius },
            mediaPopup: { width: mediaPopupWidth, radius: mediaPopupRadius },
            hyprland: {
                gapsIn: hyprGapsIn, gapsOut: hyprGapsOut,
                borderSize: hyprBorderSize, rounding: hyprRounding,
                syncColors: hyprSyncColors,
                blurEnabled: hyprBlurEnabled, blurSize: hyprBlurSize,
                blurPasses: hyprBlurPasses, blurVibrancy: hyprBlurVibrancy,
                blurXray: hyprBlurXray
            },
            kitty: {
                syncColors: kittySyncColors, opacity: kittyOpacity
            }
        };
        _fileView.setText(writeTOML(d));
    }

    function save() { _saveTimer.restart(); }

    function set(section, key, value) {
        if (!_data[section]) _data[section] = {};
        _data[section][key] = value;
        // Force sync for integrations
        if (section === "hyprland") _syncHyprland();
        if (section === "kitty") _syncKitty();
        let copy = {};
        let keys = Object.keys(_data);
        for (let k of keys) copy[k] = _data[k];
        _data = copy;
        save();
    }

    function resetSection(section) {
        let defs = parseTOML(_defaultsTOML);
        if (defs[section]) {
            _data[section] = defs[section];
            let copy = {};
            let keys = Object.keys(_data);
            for (let k of keys) copy[k] = _data[k];
            _data = copy;
            save();
        }
    }

    function resetAll() {
        _data = parseTOML(_defaultsTOML);
        save();
    }

    // ===== Hyprland Sync =====

    property int hyprGapsIn: _data?.hyprland?.gapsIn ?? 3
    property int hyprGapsOut: _data?.hyprland?.gapsOut ?? 8
    property int hyprBorderSize: _data?.hyprland?.borderSize ?? 2
    property int hyprRounding: _data?.hyprland?.rounding ?? 10
    property bool hyprSyncColors: _data?.hyprland?.syncColors ?? true
    property bool hyprBlurEnabled: _data?.hyprland?.blurEnabled ?? true
    property int hyprBlurSize: _data?.hyprland?.blurSize ?? 8
    property int hyprBlurPasses: _data?.hyprland?.blurPasses ?? 3
    property real hyprBlurVibrancy: _data?.hyprland?.blurVibrancy ?? 0.17
    property bool hyprBlurXray: _data?.hyprland?.blurXray ?? false

    // Live-sync to Hyprland when properties change
    onHyprGapsInChanged: _syncHyprland()
    onHyprGapsOutChanged: _syncHyprland()
    onHyprBorderSizeChanged: _syncHyprland()
    onHyprRoundingChanged: _syncHyprland()
    onHyprSyncColorsChanged: _syncHyprland()
    onHyprBlurEnabledChanged: _syncHyprland()
    onHyprBlurSizeChanged: _syncHyprland()
    onHyprBlurPassesChanged: _syncHyprland()
    onHyprBlurVibrancyChanged: _syncHyprland()
    onHyprBlurXrayChanged: _syncHyprland()
    onBaseChanged: { _syncHyprland(); _syncKitty(); }
    onBlueChanged: { _syncHyprland(); _syncKitty(); }
    onLavenderChanged: { _syncHyprland(); _syncKitty(); }
    onTextChanged: _syncKitty()
    onRedChanged: _syncKitty()
    onGreenChanged: _syncKitty()
    onYellowChanged: _syncKitty()
    onMauveChanged: _syncKitty()
    onPinkChanged: _syncKitty()
    onTealChanged: _syncKitty()
    onPeachChanged: _syncKitty()
    onSurface2Changed: _syncHyprland()

    property var _hyprSyncTimer: Timer {
        interval: 200
        onTriggered: config._doSyncHyprland()
    }

    function _syncHyprland() { _hyprSyncTimer.restart(); }

    property string _homeDir: Quickshell.env("HOME")
    property string _kittyThemePath: _homeDir + "/jimdots/kitty/current-theme.conf"
    property string _hyprThemePath: _homeDir + "/jimdots/hypr/quickshell-theme.conf"

    function _buildHyprTheme() {
        let b = blue.replace("#", "");
        let l = lavender.replace("#", "");
        let s = surface2.replace("#", "");
        return "# Auto-generated by quickshell Config — do not edit manually\n\n" +
            "general {\n" +
            "    gaps_in = " + hyprGapsIn + "\n" +
            "    gaps_out = " + hyprGapsOut + "\n" +
            "    border_size = " + hyprBorderSize + "\n" +
            "    col.active_border = rgba(" + b + "ee) rgba(" + l + "ee) 45deg\n" +
            "    col.inactive_border = rgba(" + s + "aa)\n" +
            "}\n\n" +
            "decoration {\n" +
            "    rounding = " + hyprRounding + "\n\n" +
            "    blur {\n" +
            "        enabled = " + (hyprBlurEnabled ? "true" : "false") + "\n" +
            "        size = " + hyprBlurSize + "\n" +
            "        passes = " + hyprBlurPasses + "\n" +
            "        vibrancy = " + hyprBlurVibrancy + "\n" +
            "        xray = " + (hyprBlurXray ? "true" : "false") + "\n" +
            "    }\n" +
            "}\n";
    }

    function _doSyncHyprland() {
        if (!hyprSyncColors) return;
        // Write persistent config file (survives reboot)
        let hyprConf = _buildHyprTheme();
        _hyprWriteProc.command = ["bash", "-c",
            "cat > " + _hyprThemePath + " << 'HYPREOF'\n" + hyprConf + "HYPREOF"];
        _hyprWriteProc.running = true;

        // Also apply live via hyprctl keyword
        let b = blue.replace("#", "");
        let l = lavender.replace("#", "");
        let s = surface2.replace("#", "");
        let script = "hyprctl keyword general:gaps_in " + hyprGapsIn +
            " && hyprctl keyword general:gaps_out " + hyprGapsOut +
            " && hyprctl keyword general:border_size " + hyprBorderSize +
            " && hyprctl keyword decoration:rounding " + hyprRounding +
            " && hyprctl keyword general:col.active_border 'rgba(" + b + "ee) rgba(" + l + "ee) 45deg'" +
            " && hyprctl keyword general:col.inactive_border 'rgba(" + s + "aa)'" +
            " && hyprctl keyword decoration:blur:enabled " + (hyprBlurEnabled ? "true" : "false") +
            " && hyprctl keyword decoration:blur:size " + hyprBlurSize +
            " && hyprctl keyword decoration:blur:passes " + hyprBlurPasses +
            " && hyprctl keyword decoration:blur:vibrancy " + hyprBlurVibrancy +
            " && hyprctl keyword decoration:blur:xray " + (hyprBlurXray ? "true" : "false");
        _hyprProc.command = ["bash", "-c", script];
        _hyprProc.running = true;
    }

    property var _hyprWriteProc: Process { command: ["true"] }
    property var _hyprProc: Process { command: ["true"] }

    // ===== Kitty Sync =====

    property bool kittySyncColors: _data?.kitty?.syncColors ?? true
    property real kittyOpacity: _data?.kitty?.opacity ?? 0.6

    onKittySyncColorsChanged: _syncKitty()
    onKittyOpacityChanged: _syncKitty()

    property var _kittySyncTimer: Timer {
        interval: 300
        onTriggered: config._doSyncKitty()
    }

    function _syncKitty() { _kittySyncTimer.restart(); }

    function _doSyncKitty() {
        if (!kittySyncColors) return;
        // Write theme file
        let themeContent = _buildKittyTheme();
        _kittyWriteProc.command = ["bash", "-c",
            "cat > " + _kittyThemePath + " << 'KITTYEOF'\n" + themeContent + "KITTYEOF"];
        _kittyWriteProc.running = true;
    }

    property var _kittyWriteProc: Process {
        command: ["true"]
        onExited: {
            // After writing theme, reload all kitty instances
            config._kittyApplyProc.command = ["bash", "-c",
                "for sock in $(ss -lx 2>/dev/null | grep -oP '@kitty-\\d+'); do " +
                "kitty @ --to unix:$sock set-colors --all --configured " + config._kittyThemePath + " 2>/dev/null; " +
                "kitty @ --to unix:$sock set-background-opacity " + config.kittyOpacity + " 2>/dev/null; " +
                "done"];
            config._kittyApplyProc.running = true;
        }
    }

    property var _kittyApplyProc: Process {
        command: ["true"]
    }

    function _buildKittyTheme() {
        return "# Auto-generated by quickshell Config\n" +
            "# Theme synced from quickshell settings\n\n" +
            "# Basic colors\n" +
            "foreground              " + text + "\n" +
            "background              " + base + "\n" +
            "selection_foreground    " + base + "\n" +
            "selection_background    " + lavender + "\n\n" +
            "# Cursor\n" +
            "cursor                  " + lavender + "\n" +
            "cursor_text_color       " + base + "\n\n" +
            "# URL\n" +
            "url_color               " + lavender + "\n\n" +
            "# Borders\n" +
            "active_border_color     " + lavender + "\n" +
            "inactive_border_color   " + overlay0 + "\n" +
            "bell_border_color       " + yellow + "\n\n" +
            "# Titlebar\n" +
            "wayland_titlebar_color  system\n" +
            "macos_titlebar_color    system\n\n" +
            "# Tabs\n" +
            "active_tab_foreground   " + crust + "\n" +
            "active_tab_background   " + mauve + "\n" +
            "inactive_tab_foreground " + text + "\n" +
            "inactive_tab_background " + mantle + "\n" +
            "tab_bar_background      " + crust + "\n\n" +
            "# Marks\n" +
            "mark1_foreground " + base + "\n" +
            "mark1_background " + lavender + "\n" +
            "mark2_foreground " + base + "\n" +
            "mark2_background " + mauve + "\n" +
            "mark3_foreground " + base + "\n" +
            "mark3_background " + teal + "\n\n" +
            "# Terminal colors\n" +
            "color0  " + surface1 + "\n" +
            "color8  " + surface2 + "\n" +
            "color1  " + red + "\n" +
            "color9  " + red + "\n" +
            "color2  " + green + "\n" +
            "color10 " + green + "\n" +
            "color3  " + yellow + "\n" +
            "color11 " + yellow + "\n" +
            "color4  " + blue + "\n" +
            "color12 " + blue + "\n" +
            "color5  " + pink + "\n" +
            "color13 " + pink + "\n" +
            "color6  " + teal + "\n" +
            "color14 " + teal + "\n" +
            "color7  " + subtext1 + "\n" +
            "color15 " + subtext0 + "\n";
    }

    // ===== Defaults (embedded for fallback) =====

    property string _defaultsTOML: '[animations]
clipboardFadeDuration = 200
clipboardOvershoot = 1.2
clipboardScaleDuration = 250
clipboardScaleFrom = 0.85
duration = 200
durationFast = 100
launcherFadeDuration = 200
launcherOvershoot = 1.2
launcherScaleDuration = 250
launcherScaleFrom = 0.85
osdFadeDuration = 120
osdScaleDuration = 150
osdScaleFrom = 0.85
panelCloseDuration = 200
panelDuration = 350
pickerBackdropOpacity = 0.58
pickerFadeDuration = 180
pickerScaleDuration = 180
pickerScaleFrom = 0.97
popupFadeDuration = 200
popupSlideDuration = 250

[animationPicker]
columns = 3
height = 440
radius = 24
selectedPreset = 3
spacing = 18
width = 620

[appearance]
base = "#1e1e2e"
blue = "#89b4fa"
crust = "#11111b"
fontFamily = "Maple Mono"
fontSize = 13
fontSizeIcon = 16
fontSizeSmall = 11
green = "#a6e3a1"
iconFont = "Maple Mono NF"
lavender = "#b4befe"
mantle = "#181825"
mauve = "#cba6f7"
overlay0 = "#6c7086"
overlay1 = "#7f849c"
peach = "#fab387"
pink = "#f5c2e7"
red = "#f38ba8"
subtext0 = "#a6adc8"
subtext1 = "#bac2de"
surface0 = "#313244"
surface1 = "#45475a"
surface2 = "#585b70"
teal = "#94e2d5"
text = "#cdd6f4"
yellow = "#f9e2af"

[bar]
height = 38
margin = 6
radius = 10
widgetPadding = 10
widgetRadius = 8
widgetSpacing = 6

[battery]
greenThreshold = 60
yellowThreshold = 20

[batteryPopup]
radius = 12
width = 240

[bluetooth]
deviceHeight = 48
deviceIconSize = 32
deviceRadius = 10
maxListHeight = 250
panelWidth = 280
scanTimeout = 60000

[calendar]
cellHeight = 28
cellRadius = 6
cellWidth = 34
width = 280

[clipboard]
backdropOpacity = 0.4
height = 450
imageItemHeight = 80
itemHeight = 38
radius = 16
searchHeight = 42
searchRadius = 12
width = 500

[clock]
dateFormat = "ddd, MMM d"
separatorHeight = 14
spacing = 8
timeFormat = "h:mm AP"

[launcher]
backdropOpacity = 0.4
hiddenApps = ["avahi-discover", "bssh", "bvnc", "lstopo", "qv4l2", "qvidcap", "electron", "cmake-gui"]
iconSize = 28
itemHeight = 44
itemRadius = 10
maxHeight = 500
radius = 16
searchHeight = 48
searchRadius = 12
terminal = "kitty"
width = 600

[media]
maxWidth = 200

[mediaPopup]
radius = 12
width = 300

[network]
pollInterval = 10000

[nightlight]
temperature = 4000

[notifications]
centerOverlayOpacity = 0.4
centerRadius = 14
centerSlideFrom = -320
centerSlideTo = 8
centerWidth = 300
defaultTimeout = 5000
maxHistory = 50
maxToasts = 3
popupBgColor = "#cc181825"
popupHeight = 48
popupRadius = 10
popupSpacing = 6
popupWidth = 280
popupWindowWidth = 300
qsButtonHeight = 56
qsButtonRadius = 10
qsColumns = 3
qsIconSize = 16
qsLabelSize = 9
qsSpacing = 6

[osd]
bgColor = "#6611111b"
bottomMargin = 80
height = 36
hideTimeout = 2000
progressHeight = 4
progressWidth = 90
radius = 18
readyDelay = 2000

[systray]
iconSize = 20
opacity = 0.7
spacing = 4

[volume]
scrollIncrement = 0.05

[wifi]
itemHeight = 44
itemRadius = 10
maxListHeight = 250
panelWidth = 300
rescanDelay = 3000

[workspaces]
count = 10
dotHeight = 10
dotRadius = 5
focusedWidth = 28
overshoot = 1.5
spacing = 6
unfocusedWidth = 10'

    // ===== APPEARANCE =====

    property string base: _data?.appearance?.base ?? "#1e1e2e"
    property string mantle: _data?.appearance?.mantle ?? "#181825"
    property string crust: _data?.appearance?.crust ?? "#11111b"
    property string surface0: _data?.appearance?.surface0 ?? "#313244"
    property string surface1: _data?.appearance?.surface1 ?? "#45475a"
    property string surface2: _data?.appearance?.surface2 ?? "#585b70"
    property string overlay0: _data?.appearance?.overlay0 ?? "#6c7086"
    property string overlay1: _data?.appearance?.overlay1 ?? "#7f849c"
    property string text: _data?.appearance?.text ?? "#cdd6f4"
    property string subtext0: _data?.appearance?.subtext0 ?? "#a6adc8"
    property string subtext1: _data?.appearance?.subtext1 ?? "#bac2de"
    property string red: _data?.appearance?.red ?? "#f38ba8"
    property string green: _data?.appearance?.green ?? "#a6e3a1"
    property string yellow: _data?.appearance?.yellow ?? "#f9e2af"
    property string blue: _data?.appearance?.blue ?? "#89b4fa"
    property string mauve: _data?.appearance?.mauve ?? "#cba6f7"
    property string pink: _data?.appearance?.pink ?? "#f5c2e7"
    property string teal: _data?.appearance?.teal ?? "#94e2d5"
    property string peach: _data?.appearance?.peach ?? "#fab387"
    property string lavender: _data?.appearance?.lavender ?? "#b4befe"

    property string fontFamily: _data?.appearance?.fontFamily ?? "Maple Mono"
    property string iconFont: _data?.appearance?.iconFont ?? "Maple Mono NF"
    property int fontSizeSmall: _data?.appearance?.fontSizeSmall ?? 11
    property int fontSize: _data?.appearance?.fontSize ?? 13
    property int fontSizeIcon: _data?.appearance?.fontSizeIcon ?? 16

    property bool transparencyEnabled: _data?.appearance?.transparencyEnabled ?? false
    property real transparencyLevel: _data?.appearance?.transparencyLevel ?? 0.85

    // Per-component opacity (-1 means use global transparencyLevel)
    property real transparencyBar: { let v = _data?.transparency?.bar ?? -1; return v < 0 ? transparencyLevel : v; }
    property real transparencyLauncher: { let v = _data?.transparency?.launcher ?? -1; return v < 0 ? transparencyLevel : v; }
    property real transparencyClipboard: { let v = _data?.transparency?.clipboard ?? -1; return v < 0 ? transparencyLevel : v; }
    property real transparencyNotifCenter: { let v = _data?.transparency?.notifCenter ?? -1; return v < 0 ? transparencyLevel : v; }
    property real transparencyNotifPopup: { let v = _data?.transparency?.notifPopup ?? -1; return v < 0 ? transparencyLevel : v; }
    property real transparencyOsd: { let v = _data?.transparency?.osd ?? -1; return v < 0 ? transparencyLevel : v; }
    property real transparencySettings: { let v = _data?.transparency?.settings ?? -1; return v < 0 ? transparencyLevel : v; }
    property real transparencyAnimPicker: { let v = _data?.transparency?.animPicker ?? -1; return v < 0 ? transparencyLevel : v; }

    // ===== BAR =====

    property int barHeight: _data?.bar?.height ?? 38
    property int barMargin: _data?.bar?.margin ?? 6
    property int barRadius: _data?.bar?.radius ?? 10
    property int widgetSpacing: _data?.bar?.widgetSpacing ?? 6
    property int widgetPadding: _data?.bar?.widgetPadding ?? 10
    property int widgetRadius: _data?.bar?.widgetRadius ?? 8

    // ===== WORKSPACES =====

    property int workspaceCount: _data?.workspaces?.count ?? 10
    property int workspaceFocusedWidth: _data?.workspaces?.focusedWidth ?? 28
    property int workspaceUnfocusedWidth: _data?.workspaces?.unfocusedWidth ?? 10
    property int workspaceDotHeight: _data?.workspaces?.dotHeight ?? 10
    property int workspaceSpacing: _data?.workspaces?.spacing ?? 6
    property int workspaceDotRadius: _data?.workspaces?.dotRadius ?? 5
    property real workspaceOvershoot: _data?.workspaces?.overshoot ?? 1.5

    // ===== CLOCK =====

    property string clockTimeFormat: _data?.clock?.timeFormat ?? "h:mm AP"
    property string clockDateFormat: _data?.clock?.dateFormat ?? "ddd, MMM d"
    property int clockSpacing: _data?.clock?.spacing ?? 8
    property int clockSeparatorHeight: _data?.clock?.separatorHeight ?? 14

    // ===== VOLUME =====

    property real volumeScrollIncrement: _data?.volume?.scrollIncrement ?? 0.05

    // ===== BATTERY =====

    property int batteryGreenThreshold: _data?.battery?.greenThreshold ?? 60
    property int batteryYellowThreshold: _data?.battery?.yellowThreshold ?? 20

    // ===== MEDIA =====

    property int mediaMaxWidth: _data?.media?.maxWidth ?? 200

    // ===== SYSTRAY =====

    property int sysTrayIconSize: _data?.systray?.iconSize ?? 20
    property int sysTraySpacing: _data?.systray?.spacing ?? 4
    property real sysTrayOpacity: _data?.systray?.opacity ?? 0.7

    // ===== NETWORK =====

    property int networkPollInterval: _data?.network?.pollInterval ?? 10000

    // ===== WIFI PANEL =====

    property int wifiPanelWidth: _data?.wifi?.panelWidth ?? 300
    property int wifiItemHeight: _data?.wifi?.itemHeight ?? 44
    property int wifiItemRadius: _data?.wifi?.itemRadius ?? 10
    property int wifiMaxListHeight: _data?.wifi?.maxListHeight ?? 250
    property int wifiRescanDelay: _data?.wifi?.rescanDelay ?? 3000

    // ===== BLUETOOTH =====

    property int btPanelWidth: _data?.bluetooth?.panelWidth ?? 280
    property int btDeviceHeight: _data?.bluetooth?.deviceHeight ?? 48
    property int btDeviceIconSize: _data?.bluetooth?.deviceIconSize ?? 32
    property int btDeviceRadius: _data?.bluetooth?.deviceRadius ?? 10
    property int btScanTimeout: _data?.bluetooth?.scanTimeout ?? 60000
    property int btMaxListHeight: _data?.bluetooth?.maxListHeight ?? 250

    // ===== CALENDAR =====

    property int calendarWidth: _data?.calendar?.width ?? 280
    property int calendarCellWidth: _data?.calendar?.cellWidth ?? 34
    property int calendarCellHeight: _data?.calendar?.cellHeight ?? 28
    property int calendarCellRadius: _data?.calendar?.cellRadius ?? 6

    // ===== NOTIFICATIONS =====

    property int notifPopupWidth: _data?.notifications?.popupWidth ?? 280
    property int notifPopupWindowWidth: _data?.notifications?.popupWindowWidth ?? 300
    property int notifPopupHeight: _data?.notifications?.popupHeight ?? 48
    property int notifPopupRadius: _data?.notifications?.popupRadius ?? 10
    property string notifPopupBgColor: _data?.notifications?.popupBgColor ?? "#cc181825"
    property int notifMaxToasts: _data?.notifications?.maxToasts ?? 3
    property int notifDefaultTimeout: _data?.notifications?.defaultTimeout ?? 5000
    property int notifMaxHistory: _data?.notifications?.maxHistory ?? 50
    property int notifPopupSpacing: _data?.notifications?.popupSpacing ?? 6

    property int notifCenterWidth: _data?.notifications?.centerWidth ?? 300
    property int notifCenterRadius: _data?.notifications?.centerRadius ?? 14
    property int notifCenterSlideFrom: _data?.notifications?.centerSlideFrom ?? -320
    property int notifCenterSlideTo: _data?.notifications?.centerSlideTo ?? 8
    property real notifCenterOverlayOpacity: _data?.notifications?.centerOverlayOpacity ?? 0.4

    property int notifQsColumns: _data?.notifications?.qsColumns ?? 3
    property int notifQsSpacing: _data?.notifications?.qsSpacing ?? 6
    property int notifQsButtonHeight: _data?.notifications?.qsButtonHeight ?? 56
    property int notifQsButtonRadius: _data?.notifications?.qsButtonRadius ?? 10
    property int notifQsIconSize: _data?.notifications?.qsIconSize ?? 16
    property int notifQsLabelSize: _data?.notifications?.qsLabelSize ?? 9

    // ===== LAUNCHER =====

    property int launcherWidth: _data?.launcher?.width ?? 600
    property int launcherMaxHeight: _data?.launcher?.maxHeight ?? 500
    property int launcherRadius: _data?.launcher?.radius ?? 16
    property int launcherSearchHeight: _data?.launcher?.searchHeight ?? 48
    property int launcherSearchRadius: _data?.launcher?.searchRadius ?? 12
    property int launcherItemHeight: _data?.launcher?.itemHeight ?? 44
    property int launcherItemRadius: _data?.launcher?.itemRadius ?? 10
    property int launcherIconSize: _data?.launcher?.iconSize ?? 28
    property real launcherBackdropOpacity: _data?.launcher?.backdropOpacity ?? 0.4
    property var launcherHiddenApps: _data?.launcher?.hiddenApps ?? ["avahi-discover", "bssh", "bvnc", "lstopo", "qv4l2", "qvidcap", "electron", "cmake-gui"]
    property string launcherTerminal: _data?.launcher?.terminal ?? "kitty"

    // ===== CLIPBOARD =====

    property int clipboardWidth: _data?.clipboard?.width ?? 500
    property int clipboardHeight: _data?.clipboard?.height ?? 450
    property int clipboardRadius: _data?.clipboard?.radius ?? 16
    property int clipboardSearchHeight: _data?.clipboard?.searchHeight ?? 42
    property int clipboardSearchRadius: _data?.clipboard?.searchRadius ?? 12
    property int clipboardItemHeight: _data?.clipboard?.itemHeight ?? 38
    property int clipboardImageItemHeight: _data?.clipboard?.imageItemHeight ?? 80
    property real clipboardBackdropOpacity: _data?.clipboard?.backdropOpacity ?? 0.4

    // ===== OSD =====

    property int osdBottomMargin: _data?.osd?.bottomMargin ?? 80
    property int osdHeight: _data?.osd?.height ?? 36
    property int osdRadius: _data?.osd?.radius ?? 18
    property string osdBgColor: _data?.osd?.bgColor ?? "#6611111b"
    property int osdProgressWidth: _data?.osd?.progressWidth ?? 90
    property int osdProgressHeight: _data?.osd?.progressHeight ?? 4
    property int osdHideTimeout: _data?.osd?.hideTimeout ?? 2000
    property int osdReadyDelay: _data?.osd?.readyDelay ?? 2000

    // ===== ANIMATIONS =====

    property int animDuration: _data?.animations?.duration ?? 200
    property int animDurationFast: _data?.animations?.durationFast ?? 100
    property int animPanelDuration: _data?.animations?.panelDuration ?? 350
    property int animPanelCloseDuration: _data?.animations?.panelCloseDuration ?? 200
    property int animPopupSlideDuration: _data?.animations?.popupSlideDuration ?? 250
    property int animPopupFadeDuration: _data?.animations?.popupFadeDuration ?? 200

    property real animLauncherScaleFrom: _data?.animations?.launcherScaleFrom ?? 0.85
    property int animLauncherScaleDuration: _data?.animations?.launcherScaleDuration ?? 250
    property real animLauncherOvershoot: _data?.animations?.launcherOvershoot ?? 1.2
    property int animLauncherFadeDuration: _data?.animations?.launcherFadeDuration ?? 200

    property real animClipboardScaleFrom: _data?.animations?.clipboardScaleFrom ?? 0.85
    property int animClipboardScaleDuration: _data?.animations?.clipboardScaleDuration ?? 250
    property real animClipboardOvershoot: _data?.animations?.clipboardOvershoot ?? 1.2
    property int animClipboardFadeDuration: _data?.animations?.clipboardFadeDuration ?? 200

    property real animOsdScaleFrom: _data?.animations?.osdScaleFrom ?? 0.85
    property int animOsdScaleDuration: _data?.animations?.osdScaleDuration ?? 150
    property int animOsdFadeDuration: _data?.animations?.osdFadeDuration ?? 120

    property real animPickerScaleFrom: _data?.animations?.pickerScaleFrom ?? 0.97
    property int animPickerScaleDuration: _data?.animations?.pickerScaleDuration ?? 180
    property int animPickerFadeDuration: _data?.animations?.pickerFadeDuration ?? 180
    property real animPickerBackdropOpacity: _data?.animations?.pickerBackdropOpacity ?? 0.58

    // ===== NIGHT LIGHT =====

    property int nightLightTemp: _data?.nightlight?.temperature ?? 4000

    // ===== ANIMATION PICKER =====

    property int animPickerWidth: _data?.animationPicker?.width ?? 620
    property int animPickerHeight: _data?.animationPicker?.height ?? 440
    property int animPickerRadius: _data?.animationPicker?.radius ?? 24
    property int animPickerColumns: _data?.animationPicker?.columns ?? 3
    property int animPickerSpacing: _data?.animationPicker?.spacing ?? 18
    property int animPickerSelectedPreset: _data?.animationPicker?.selectedPreset ?? 3

    // ===== BATTERY POPUP =====

    property int batteryPopupWidth: _data?.batteryPopup?.width ?? 240
    property int batteryPopupRadius: _data?.batteryPopup?.radius ?? 12

    // ===== MEDIA POPUP =====

    property int mediaPopupWidth: _data?.mediaPopup?.width ?? 300
    property int mediaPopupRadius: _data?.mediaPopup?.radius ?? 12

    // ===== Convenience: all section names =====

    property var sectionNames: ["appearance", "bar", "workspaces", "clock", "volume", "battery",
        "media", "systray", "network", "wifi", "bluetooth", "calendar", "notifications",
        "launcher", "clipboard", "osd", "animations", "nightlight", "animationPicker",
        "batteryPopup", "mediaPopup"]
}
