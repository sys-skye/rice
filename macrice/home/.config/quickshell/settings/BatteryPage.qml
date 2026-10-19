import QtQuick
import Quickshell.Services.UPower
import qs.common

Column {
    id: page
    width: parent ? parent.width : 500
    readonly property var sleepOptions: PowerSettings.sleepPresets.map(m => ({ label: m ? m + " min" : "Never", value: m }))
    readonly property var bat: UPower.displayDevice

    Group {
        title: "Battery"
        SettingRow {
            label: "Level"
            hint: UPower.onBattery ? "On battery" : "On power adapter"
            Label { text: Math.round((bat?.percentage ?? 0) * 100) + "%"; bold: true; font.pixelSize: 15 }
        }
        SettingRow {
            label: "Battery health"
            visible: bat?.healthSupported ?? false
            last: true
            Label { text: Math.round(bat?.healthPercentage ?? 0) + "%"; dim: true }
        }
    }

    Group {
        title: "Power Mode"
        footer: "On Apple Silicon under Linux the power modes change very little; most of the idle drain is the chip itself. "
              + "Sleeping when idle (below) saves far more."
        Item {
            width: parent.width
            height: 54
            PowerModeControl { x: 14; y: 12; width: parent.width - 28 }
        }
    }

    Group {
        title: "Energy Saver"
        footer: "The screen still dims, locks and turns off on its own; this puts the Mac to sleep afterwards. "
              + "Playing video keeps it awake. The cursor trail polls the cursor all the time, so it's paused on battery unless you allow it."
        SettingRow {
            label: "Sleep when idle"
            hint: "On battery"
            Segmented { options: page.sleepOptions; value: PowerSettings.sleepOnBattery; onPicked: v => PowerSettings.set("sleepOnBattery", v) }
        }
        SettingRow {
            label: "Sleep when idle"
            hint: "On power adapter"
            Segmented { options: page.sleepOptions; value: PowerSettings.sleepOnPower; onPicked: v => PowerSettings.set("sleepOnPower", v) }
        }
        SettingRow {
            label: "Cursor trail on battery"
            hint: InputSettings.trailEnabled ? "" : "The trail is off (Trackpad & Mouse)"
            last: true
            Toggle { checked: PowerSettings.trailOnBattery; onToggled: v => PowerSettings.set("trailOnBattery", v) }
        }
    }

    Group {
        title: "Charge Limit"
        footer: "Keeping the battery below 100% when you're mostly plugged in slows down battery wear. "
              + "Charging resumes 5% below the limit. “Charge to Full Now” goes to 100% once and then switches back."
        Item {
            width: parent.width
            height: limit.implicitHeight + 24
            ChargeLimitControl { id: limit; x: 14; y: 12; width: parent.width - 28 }
        }
    }
}
