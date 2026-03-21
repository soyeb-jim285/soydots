import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: 6

    function formatTime(seconds) {
        let m = Math.floor(seconds / 60);
        let s = seconds % 60;
        if (m > 0 && s > 0) return m + "m " + s + "s";
        if (m > 0) return m + "m";
        return s + "s";
    }

    // ===== SCREEN DIMMING =====
    Text { text: "Screen Dimming"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.bottomMargin: 4 }

    Text {
        text: "Dim screen brightness after inactivity."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enable Dimming"; section: "idle"; key: "dimEnabled"; value: Config.idleDimEnabled }
    SliderSetting { label: "Dim After"; section: "idle"; key: "dimTimeout"; value: Config.idleDimTimeout; from: 30; to: 600 }

    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Item { Layout.preferredWidth: 140; height: 1 }
        Text { text: formatTime(Config.idleDimTimeout); color: Config.overlay0; font.pixelSize: 10; font.family: Config.fontFamily }
    }

    // ===== AUTO LOCK =====
    Text { text: "Auto Lock"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "Lock the screen after inactivity."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enable Auto Lock"; section: "idle"; key: "lockEnabled"; value: Config.idleLockEnabled }
    SliderSetting { label: "Lock After"; section: "idle"; key: "lockTimeout"; value: Config.idleLockTimeout; from: 60; to: 1800 }

    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Item { Layout.preferredWidth: 140; height: 1 }
        Text { text: formatTime(Config.idleLockTimeout); color: Config.overlay0; font.pixelSize: 10; font.family: Config.fontFamily }
    }

    // ===== SCREEN OFF =====
    Text { text: "Screen Off (DPMS)"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "Turn off the display after inactivity."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enable Screen Off"; section: "idle"; key: "dpmsEnabled"; value: Config.idleDpmsEnabled }
    SliderSetting { label: "Screen Off After"; section: "idle"; key: "dpmsTimeout"; value: Config.idleDpmsTimeout; from: 60; to: 1800 }

    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Item { Layout.preferredWidth: 140; height: 1 }
        Text { text: formatTime(Config.idleDpmsTimeout); color: Config.overlay0; font.pixelSize: 10; font.family: Config.fontFamily }
    }

    // ===== AUTO SUSPEND =====
    Text { text: "Auto Suspend"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "Suspend the system after extended inactivity."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enable Auto Suspend"; section: "idle"; key: "suspendEnabled"; value: Config.idleSuspendEnabled }
    SliderSetting { label: "Suspend After"; section: "idle"; key: "suspendTimeout"; value: Config.idleSuspendTimeout; from: 300; to: 3600 }

    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Item { Layout.preferredWidth: 140; height: 1 }
        Text { text: formatTime(Config.idleSuspendTimeout); color: Config.overlay0; font.pixelSize: 10; font.family: Config.fontFamily }
    }

    // ===== HIBERNATE =====
    Text { text: "Hibernate"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 12; Layout.bottomMargin: 4 }

    Text {
        text: "Hibernate after being suspended. Uses suspend-then-hibernate when enabled, plain suspend when disabled."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }

    ToggleSetting { label: "Enable Hibernate"; section: "idle"; key: "hibernateEnabled"; value: Config.idleHibernateEnabled }
    SliderSetting { label: "Hibernate Delay"; section: "idle"; key: "hibernateDelay"; value: Config.idleHibernateDelay; from: 1800; to: 14400 }

    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Item { Layout.preferredWidth: 140; height: 1 }
        Text { text: formatTime(Config.idleHibernateDelay); color: Config.overlay0; font.pixelSize: 10; font.family: Config.fontFamily }
    }

    // ===== SYSTEM REQUIREMENTS =====
    Text { text: "System Setup (Hibernate)"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 16; Layout.bottomMargin: 4 }

    Text {
        text: "Hibernate requires system-level configuration. Run these commands once:\n\n" +
              "1. Add resume hook to initramfs:\n" +
              "   sudo sed -i 's/HOOKS=(\\(.*\\)filesystems/HOOKS=(\\1resume filesystems/' /etc/mkinitcpio.conf\n\n" +
              "2. Add kernel parameter (systemd-boot):\n" +
              "   Edit /boot/loader/entries/*.conf, add: resume=/dev/nvme0n1p2\n\n" +
              "3. Rebuild initramfs:\n" +
              "   sudo mkinitcpio -P\n\n" +
              "4. Configure hibernate delay:\n" +
              "   sudo mkdir -p /etc/systemd/sleep.conf.d\n" +
              "   echo '[Sleep]\\nHibernateDelaySec=2h' | sudo tee /etc/systemd/sleep.conf.d/hibernate.conf\n\n" +
              "5. Reboot for changes to take effect."
        color: Config.subtext0; font.pixelSize: 10; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
        lineHeight: 1.4
    }

    // ===== IDLE PIPELINE PREVIEW =====
    Text { text: "Current Pipeline"; color: Config.blue; font.pixelSize: 12; font.family: Config.fontFamily; font.bold: true; Layout.topMargin: 16; Layout.bottomMargin: 4 }

    Text {
        property string pipeline: {
            let steps = [];
            if (Config.idleDimEnabled) steps.push("Dim (" + formatTime(Config.idleDimTimeout) + ")");
            if (Config.idleLockEnabled) steps.push("Lock (" + formatTime(Config.idleLockTimeout) + ")");
            if (Config.idleDpmsEnabled) steps.push("Screen Off (" + formatTime(Config.idleDpmsTimeout) + ")");
            if (Config.idleSuspendEnabled) {
                if (Config.idleHibernateEnabled)
                    steps.push("Suspend (" + formatTime(Config.idleSuspendTimeout) + ") → Hibernate (" + formatTime(Config.idleHibernateDelay) + ")");
                else
                    steps.push("Suspend (" + formatTime(Config.idleSuspendTimeout) + ")");
            }
            return steps.length > 0 ? steps.join("  →  ") : "All idle actions disabled";
        }
        text: pipeline
        color: Config.text; font.pixelSize: 11; font.family: Config.fontFamily
        wrapMode: Text.Wrap; Layout.fillWidth: true
    }
}
