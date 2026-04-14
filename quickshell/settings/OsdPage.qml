import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: 6

    Text { text: "Position & Size"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 4 }

    SliderSetting { label: "Bottom Margin"; section: "osd"; key: "bottomMargin"; value: Config.osdBottomMargin; from: 10; to: 200 }
    SliderSetting { label: "Height"; section: "osd"; key: "height"; value: Config.osdHeight; from: 20; to: 60 }
    SliderSetting { label: "Radius"; section: "osd"; key: "radius"; value: Config.osdRadius; from: 0; to: 30 }

    Text { text: "Progress Bar"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Progress Width"; section: "osd"; key: "progressWidth"; value: Config.osdProgressWidth; from: 40; to: 200 }
    SliderSetting { label: "Progress Height"; section: "osd"; key: "progressHeight"; value: Config.osdProgressHeight; from: 2; to: 10 }

    Text { text: "Timing"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Hide Timeout (ms)"; section: "osd"; key: "hideTimeout"; value: Config.osdHideTimeout; from: 500; to: 5000; stepSize: 100 }
    SliderSetting { label: "Ready Delay (ms)"; section: "osd"; key: "readyDelay"; value: Config.osdReadyDelay; from: 500; to: 5000; stepSize: 100 }

    Text { text: "Appearance"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    TextSetting { label: "Background Color"; section: "osd"; key: "bgColor"; value: Config.osdBgColor }
    SliderSetting { label: "Transparency"; section: "transparency"; key: "osd"; value: Config._data?.transparency?.osd ?? -1; from: -1; to: 1.0; decimals: 2; stepSize: 0.05; visible: Config.transparencyEnabled }
}
