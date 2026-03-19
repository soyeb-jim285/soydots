import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: 6

    Text { text: "Dimensions"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 4 }

    SliderSetting { label: "Width"; section: "clipboard"; key: "width"; value: Config.clipboardWidth; from: 300; to: 800 }
    SliderSetting { label: "Height"; section: "clipboard"; key: "height"; value: Config.clipboardHeight; from: 200; to: 700 }
    SliderSetting { label: "Radius"; section: "clipboard"; key: "radius"; value: Config.clipboardRadius; from: 0; to: 30 }
    SliderSetting { label: "Search Height"; section: "clipboard"; key: "searchHeight"; value: Config.clipboardSearchHeight; from: 24; to: 56 }
    SliderSetting { label: "Search Radius"; section: "clipboard"; key: "searchRadius"; value: Config.clipboardSearchRadius; from: 0; to: 20 }
    SliderSetting { label: "Item Height"; section: "clipboard"; key: "itemHeight"; value: Config.clipboardItemHeight; from: 24; to: 60 }
    SliderSetting { label: "Image Item Height"; section: "clipboard"; key: "imageItemHeight"; value: Config.clipboardImageItemHeight; from: 40; to: 120 }
    SliderSetting { label: "Backdrop Opacity"; section: "clipboard"; key: "backdropOpacity"; value: Config.clipboardBackdropOpacity; from: 0; to: 1.0; decimals: 2; stepSize: 0.05 }
}
