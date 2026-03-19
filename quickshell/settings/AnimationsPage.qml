import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: 6

    Text { text: "Global"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 4 }

    SliderSetting { label: "Duration"; section: "animations"; key: "duration"; value: Config.animDuration; from: 50; to: 500 }
    SliderSetting { label: "Fast Duration"; section: "animations"; key: "durationFast"; value: Config.animDurationFast; from: 25; to: 300 }

    Text { text: "Status Bar Panels"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Panel Open"; section: "animations"; key: "panelDuration"; value: Config.animPanelDuration; from: 100; to: 800 }
    SliderSetting { label: "Panel Close"; section: "animations"; key: "panelCloseDuration"; value: Config.animPanelCloseDuration; from: 50; to: 500 }

    Text { text: "Notifications"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Slide Duration"; section: "animations"; key: "popupSlideDuration"; value: Config.animPopupSlideDuration; from: 50; to: 500 }
    SliderSetting { label: "Fade Duration"; section: "animations"; key: "popupFadeDuration"; value: Config.animPopupFadeDuration; from: 50; to: 500 }

    Text { text: "App Launcher"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Scale From"; section: "animations"; key: "launcherScaleFrom"; value: Config.animLauncherScaleFrom; from: 0.5; to: 1.0; decimals: 2; stepSize: 0.05 }
    SliderSetting { label: "Scale Duration"; section: "animations"; key: "launcherScaleDuration"; value: Config.animLauncherScaleDuration; from: 50; to: 500 }
    SliderSetting { label: "Overshoot"; section: "animations"; key: "launcherOvershoot"; value: Config.animLauncherOvershoot; from: 0; to: 3.0; decimals: 1; stepSize: 0.1 }
    SliderSetting { label: "Fade Duration"; section: "animations"; key: "launcherFadeDuration"; value: Config.animLauncherFadeDuration; from: 50; to: 500 }

    Text { text: "Clipboard"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Scale From"; section: "animations"; key: "clipboardScaleFrom"; value: Config.animClipboardScaleFrom; from: 0.5; to: 1.0; decimals: 2; stepSize: 0.05 }
    SliderSetting { label: "Scale Duration"; section: "animations"; key: "clipboardScaleDuration"; value: Config.animClipboardScaleDuration; from: 50; to: 500 }
    SliderSetting { label: "Overshoot"; section: "animations"; key: "clipboardOvershoot"; value: Config.animClipboardOvershoot; from: 0; to: 3.0; decimals: 1; stepSize: 0.1 }
    SliderSetting { label: "Fade Duration"; section: "animations"; key: "clipboardFadeDuration"; value: Config.animClipboardFadeDuration; from: 50; to: 500 }

    Text { text: "OSD"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Scale From"; section: "animations"; key: "osdScaleFrom"; value: Config.animOsdScaleFrom; from: 0.5; to: 1.0; decimals: 2; stepSize: 0.05 }
    SliderSetting { label: "Scale Duration"; section: "animations"; key: "osdScaleDuration"; value: Config.animOsdScaleDuration; from: 50; to: 500 }
    SliderSetting { label: "Fade Duration"; section: "animations"; key: "osdFadeDuration"; value: Config.animOsdFadeDuration; from: 50; to: 500 }

    Text { text: "Animation Picker"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Scale From"; section: "animations"; key: "pickerScaleFrom"; value: Config.animPickerScaleFrom; from: 0.5; to: 1.0; decimals: 2; stepSize: 0.05 }
    SliderSetting { label: "Scale Duration"; section: "animations"; key: "pickerScaleDuration"; value: Config.animPickerScaleDuration; from: 50; to: 500 }
    SliderSetting { label: "Fade Duration"; section: "animations"; key: "pickerFadeDuration"; value: Config.animPickerFadeDuration; from: 50; to: 500 }
    SliderSetting { label: "Backdrop Opacity"; section: "animations"; key: "pickerBackdropOpacity"; value: Config.animPickerBackdropOpacity; from: 0; to: 1.0; decimals: 2; stepSize: 0.05 }
}
