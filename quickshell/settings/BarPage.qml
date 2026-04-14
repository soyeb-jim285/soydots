import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: 6

    Text { text: "Bar Dimensions"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 4 }

    SliderSetting { label: "Bar Height"; section: "bar"; key: "height"; value: Config.barHeight; from: 20; to: 60 }
    SliderSetting { label: "Bar Margin"; section: "bar"; key: "margin"; value: Config.barMargin; from: 0; to: 20 }
    SliderSetting { label: "Bar Radius"; section: "bar"; key: "radius"; value: Config.barRadius; from: 0; to: 24 }
    SliderSetting { label: "Transparency"; section: "transparency"; key: "bar"; value: Config._data?.transparency?.bar ?? -1; from: -1; to: 1.0; decimals: 2; stepSize: 0.05; visible: Config.transparencyEnabled }

    Text { text: "Widget Layout"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Widget Spacing"; section: "bar"; key: "widgetSpacing"; value: Config.widgetSpacing; from: 0; to: 20 }
    SliderSetting { label: "Widget Padding"; section: "bar"; key: "widgetPadding"; value: Config.widgetPadding; from: 0; to: 24 }
    SliderSetting { label: "Widget Radius"; section: "bar"; key: "widgetRadius"; value: Config.widgetRadius; from: 0; to: 16 }

    Text { text: "Workspaces"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Workspace Count"; section: "workspaces"; key: "count"; value: Config.workspaceCount; from: 1; to: 20 }
    SliderSetting { label: "Focused Width"; section: "workspaces"; key: "focusedWidth"; value: Config.workspaceFocusedWidth; from: 10; to: 60 }
    SliderSetting { label: "Unfocused Width"; section: "workspaces"; key: "unfocusedWidth"; value: Config.workspaceUnfocusedWidth; from: 4; to: 30 }
    SliderSetting { label: "Dot Height"; section: "workspaces"; key: "dotHeight"; value: Config.workspaceDotHeight; from: 4; to: 20 }
    SliderSetting { label: "Dot Radius"; section: "workspaces"; key: "dotRadius"; value: Config.workspaceDotRadius; from: 0; to: 10 }
    SliderSetting { label: "Dot Spacing"; section: "workspaces"; key: "spacing"; value: Config.workspaceSpacing; from: 1; to: 16 }

    Text { text: "Clock"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    TextSetting { label: "Time Format"; section: "clock"; key: "timeFormat"; value: Config.clockTimeFormat }
    TextSetting { label: "Date Format"; section: "clock"; key: "dateFormat"; value: Config.clockDateFormat }
    SliderSetting { label: "Clock Spacing"; section: "clock"; key: "spacing"; value: Config.clockSpacing; from: 0; to: 20 }

    Text { text: "System Tray"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Icon Size"; section: "systray"; key: "iconSize"; value: Config.sysTrayIconSize; from: 12; to: 32 }
    SliderSetting { label: "Icon Spacing"; section: "systray"; key: "spacing"; value: Config.sysTraySpacing; from: 0; to: 12 }
    SliderSetting { label: "Icon Opacity"; section: "systray"; key: "opacity"; value: Config.sysTrayOpacity; from: 0.1; to: 1.0; decimals: 2; stepSize: 0.05 }

    Text { text: "Media Player"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Max Text Width"; section: "media"; key: "maxWidth"; value: Config.mediaMaxWidth; from: 80; to: 400 }

    Text { text: "Volume"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Scroll Increment"; section: "volume"; key: "scrollIncrement"; value: Config.volumeScrollIncrement; from: 0.01; to: 0.15; decimals: 2; stepSize: 0.01 }
}
