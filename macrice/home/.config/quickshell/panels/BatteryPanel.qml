import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.common

Panel {
    id: root
    name: "battery"
    panelWidth: 280

    readonly property var bat: UPower.displayDevice
    readonly property int pct: Math.round((bat?.percentage ?? 0) * 100)
    readonly property bool held: !UPower.onBattery && ChargeLimit.threshold < 100
                                 && pct >= ChargeLimit.threshold - 5
                                 && bat.state !== UPowerDeviceState.Charging
    function duration(s) {
        if (!s || s <= 0) return ""
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60)
        return h > 0 ? h + " h " + m + " min" : m + " min"
    }
    onOpened: ChargeLimit.refresh()

    SectionTitle {
        text: "Battery"
        Label { text: root.pct + "%"; dim: true }
    }
    MenuSeparator {}
    MenuItem {
        enabled: false
        text: "Power Source: " + (UPower.onBattery ? "Battery" : "Power Adapter")
    }
    MenuItem {
        enabled: false
        visible: text !== ""
        text: {
            if (root.held) return "Charging on hold at " + ChargeLimit.threshold + "% limit"
            if (root.bat.state === UPowerDeviceState.FullyCharged) return "Fully charged"
            if (UPower.onBattery && root.bat.timeToEmpty > 0) return root.duration(root.bat.timeToEmpty) + " remaining"
            if (!UPower.onBattery && root.bat.timeToFull > 0) return root.duration(root.bat.timeToFull) + " until full"
            return ""
        }
    }
    MenuItem {
        enabled: false
        visible: Math.abs(root.bat.changeRate) > 0.1
        text: (UPower.onBattery ? "Using " : "Charging at ") + Math.abs(root.bat.changeRate).toFixed(1) + " W"
    }
    MenuItem {
        enabled: false
        visible: root.bat.healthSupported
        text: "Battery health: " + Math.round(root.bat.healthPercentage) + "%"
    }

    MenuSeparator {}

    // ── Power mode ──────────────────────────────────────────────────
    Item {
        width: parent.width
        height: 26
        Label { x: 4; anchors.verticalCenter: parent.verticalCenter; text: "Power Mode"; bold: true }
    }
    PowerModeControl {}
    Label {
        x: 4
        width: parent.width - 8
        visible: PowerProfiles.profile === PowerProfile.PowerSaver
        text: "Low Power slows the CPU a little to save battery."
        dim: true
        font.pixelSize: Theme.smallFontSize
        wrapMode: Text.Wrap
        elide: Text.ElideNone
    }

    MenuSeparator {}

    // ── Charge limit ────────────────────────────────────────────────
    Item {
        width: parent.width
        height: 26
        Label { x: 4; anchors.verticalCenter: parent.verticalCenter; text: "Charge Limit"; bold: true }
        Label {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: ChargeLimit.fullOnce ? "100% once" : ChargeLimit.threshold + "%"
            dim: true
        }
    }

    ChargeLimitControl { width: parent.width }
}
