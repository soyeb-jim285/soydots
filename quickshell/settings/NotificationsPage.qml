import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: 6

    Text { text: "Toast Popups"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 4 }

    SliderSetting { label: "Popup Width"; section: "notifications"; key: "popupWidth"; value: Config.notifPopupWidth; from: 200; to: 400 }
    SliderSetting { label: "Window Width"; section: "notifications"; key: "popupWindowWidth"; value: Config.notifPopupWindowWidth; from: 220; to: 420 }
    SliderSetting { label: "Popup Height"; section: "notifications"; key: "popupHeight"; value: Config.notifPopupHeight; from: 30; to: 80 }
    SliderSetting { label: "Popup Radius"; section: "notifications"; key: "popupRadius"; value: Config.notifPopupRadius; from: 0; to: 20 }
    SliderSetting { label: "Max Toasts"; section: "notifications"; key: "maxToasts"; value: Config.notifMaxToasts; from: 1; to: 10 }
    SliderSetting { label: "Default Timeout (ms)"; section: "notifications"; key: "defaultTimeout"; value: Config.notifDefaultTimeout; from: 1000; to: 15000; stepSize: 500 }
    SliderSetting { label: "Max History"; section: "notifications"; key: "maxHistory"; value: Config.notifMaxHistory; from: 10; to: 200 }
    SliderSetting { label: "Popup Spacing"; section: "notifications"; key: "popupSpacing"; value: Config.notifPopupSpacing; from: 0; to: 16 }

    TextSetting { label: "Background Color"; section: "notifications"; key: "popupBgColor"; value: Config.notifPopupBgColor }

    Text { text: "Notification Center"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Panel Width"; section: "notifications"; key: "centerWidth"; value: Config.notifCenterWidth; from: 200; to: 500 }
    SliderSetting { label: "Panel Radius"; section: "notifications"; key: "centerRadius"; value: Config.notifCenterRadius; from: 0; to: 24 }
    SliderSetting { label: "Overlay Opacity"; section: "notifications"; key: "centerOverlayOpacity"; value: Config.notifCenterOverlayOpacity; from: 0; to: 1.0; decimals: 2; stepSize: 0.05 }

    Text { text: "Quick Settings Grid"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Columns"; section: "notifications"; key: "qsColumns"; value: Config.notifQsColumns; from: 2; to: 5 }
    SliderSetting { label: "Spacing"; section: "notifications"; key: "qsSpacing"; value: Config.notifQsSpacing; from: 0; to: 16 }
    SliderSetting { label: "Button Height"; section: "notifications"; key: "qsButtonHeight"; value: Config.notifQsButtonHeight; from: 30; to: 80 }
    SliderSetting { label: "Button Radius"; section: "notifications"; key: "qsButtonRadius"; value: Config.notifQsButtonRadius; from: 0; to: 20 }
    SliderSetting { label: "Icon Size"; section: "notifications"; key: "qsIconSize"; value: Config.notifQsIconSize; from: 10; to: 24 }
    SliderSetting { label: "Label Size"; section: "notifications"; key: "qsLabelSize"; value: Config.notifQsLabelSize; from: 6; to: 14 }
}
