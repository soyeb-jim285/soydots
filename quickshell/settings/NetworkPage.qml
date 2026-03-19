import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: 6

    Text { text: "Network Monitoring"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 4 }

    SliderSetting { label: "Poll Interval (ms)"; section: "network"; key: "pollInterval"; value: Config.networkPollInterval; from: 2000; to: 60000; stepSize: 1000 }

    Text { text: "Wi-Fi Panel"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Panel Width"; section: "wifi"; key: "panelWidth"; value: Config.wifiPanelWidth; from: 200; to: 500 }
    SliderSetting { label: "Item Height"; section: "wifi"; key: "itemHeight"; value: Config.wifiItemHeight; from: 28; to: 64 }
    SliderSetting { label: "Item Radius"; section: "wifi"; key: "itemRadius"; value: Config.wifiItemRadius; from: 0; to: 20 }
    SliderSetting { label: "Max List Height"; section: "wifi"; key: "maxListHeight"; value: Config.wifiMaxListHeight; from: 100; to: 500 }
    SliderSetting { label: "Rescan Delay (ms)"; section: "wifi"; key: "rescanDelay"; value: Config.wifiRescanDelay; from: 1000; to: 10000; stepSize: 500 }

    Text { text: "Bluetooth Panel"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    SliderSetting { label: "Panel Width"; section: "bluetooth"; key: "panelWidth"; value: Config.btPanelWidth; from: 200; to: 500 }
    SliderSetting { label: "Device Height"; section: "bluetooth"; key: "deviceHeight"; value: Config.btDeviceHeight; from: 28; to: 72 }
    SliderSetting { label: "Device Icon Size"; section: "bluetooth"; key: "deviceIconSize"; value: Config.btDeviceIconSize; from: 16; to: 48 }
    SliderSetting { label: "Device Radius"; section: "bluetooth"; key: "deviceRadius"; value: Config.btDeviceRadius; from: 0; to: 20 }
    SliderSetting { label: "Max List Height"; section: "bluetooth"; key: "maxListHeight"; value: Config.btMaxListHeight; from: 100; to: 500 }
    SliderSetting { label: "Scan Timeout (ms)"; section: "bluetooth"; key: "scanTimeout"; value: Config.btScanTimeout; from: 10000; to: 120000; stepSize: 5000 }
}
