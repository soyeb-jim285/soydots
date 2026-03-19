import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: 6

    Text { text: "Calendar Grid"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 4 }

    SliderSetting { label: "Panel Width"; section: "calendar"; key: "width"; value: Config.calendarWidth; from: 200; to: 400 }
    SliderSetting { label: "Cell Width"; section: "calendar"; key: "cellWidth"; value: Config.calendarCellWidth; from: 20; to: 50 }
    SliderSetting { label: "Cell Height"; section: "calendar"; key: "cellHeight"; value: Config.calendarCellHeight; from: 16; to: 40 }
    SliderSetting { label: "Cell Radius"; section: "calendar"; key: "cellRadius"; value: Config.calendarCellRadius; from: 0; to: 14 }

    Text { text: "Animation Picker Panel"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Width"; section: "animationPicker"; key: "width"; value: Config.animPickerWidth; from: 400; to: 900 }
    SliderSetting { label: "Height"; section: "animationPicker"; key: "height"; value: Config.animPickerHeight; from: 300; to: 700 }
    SliderSetting { label: "Radius"; section: "animationPicker"; key: "radius"; value: Config.animPickerRadius; from: 0; to: 36 }
    SliderSetting { label: "Grid Columns"; section: "animationPicker"; key: "columns"; value: Config.animPickerColumns; from: 2; to: 6 }
    SliderSetting { label: "Grid Spacing"; section: "animationPicker"; key: "spacing"; value: Config.animPickerSpacing; from: 4; to: 32 }

    Text { text: "Popup Panels"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Battery Popup Width"; section: "batteryPopup"; key: "width"; value: Config.batteryPopupWidth; from: 160; to: 360 }
    SliderSetting { label: "Battery Popup Radius"; section: "batteryPopup"; key: "radius"; value: Config.batteryPopupRadius; from: 0; to: 20 }
    SliderSetting { label: "Media Popup Width"; section: "mediaPopup"; key: "width"; value: Config.mediaPopupWidth; from: 200; to: 500 }
    SliderSetting { label: "Media Popup Radius"; section: "mediaPopup"; key: "radius"; value: Config.mediaPopupRadius; from: 0; to: 20 }
}
