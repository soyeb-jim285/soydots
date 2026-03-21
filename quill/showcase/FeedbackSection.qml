import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    spacing: Theme.spacingXl

    // ── Tooltip ──
    Text {
        text: "Tooltip"
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSizeLarge
        font.family: Theme.fontFamily
        font.bold: true
    }

    ColumnLayout {
        spacing: Theme.spacingMd

        Text {
            text: "Hover over the icon buttons to see tooltips"
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
        }
        RowLayout {
            spacing: Theme.spacing
            IconButton { icon: "\uf015"; tooltip: "Home"; variant: "ghost" }
            IconButton { icon: "\uf013"; tooltip: "Settings"; variant: "ghost" }
            IconButton { icon: "\uf007"; tooltip: "Profile"; variant: "ghost" }
            IconButton { icon: "\uf002"; tooltip: "Search"; variant: "ghost" }
        }
    }

    // ── Badge ──
    Text {
        text: "Badge"
        color: Theme.textPrimary
        font.pixelSize: Theme.fontSizeLarge
        font.family: Theme.fontFamily
        font.bold: true
    }

    ColumnLayout {
        spacing: Theme.spacingMd

        Text {
            text: "With text"
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
        }
        RowLayout {
            spacing: Theme.spacing
            Badge { text: "New"; variant: "primary" }
            Badge { text: "Done"; variant: "success" }
            Badge { text: "Warn"; variant: "warning" }
            Badge { text: "Error"; variant: "error" }
        }

        Text {
            text: "Dot badges"
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSize
            font.family: Theme.fontFamily
        }
        RowLayout {
            spacing: Theme.spacing
            Badge { variant: "primary" }
            Badge { variant: "success" }
            Badge { variant: "warning" }
            Badge { variant: "error" }
        }
    }
}
