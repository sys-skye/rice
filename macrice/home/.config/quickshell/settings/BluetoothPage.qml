import QtQuick
import Quickshell.Bluetooth
import qs.common

Column {
    width: parent ? parent.width : 500
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var paired: Bluetooth.devices.values.filter(d => d.paired || d.connected)

    Group {
        title: "Bluetooth"
        SettingRow {
            label: "Bluetooth"
            hint: adapter?.enabled ? "On" : "Off"
            last: !(adapter?.enabled ?? false)
            Toggle { checked: adapter?.enabled ?? false; onToggled: v => { if (adapter) adapter.enabled = v } }
        }
        Repeater {
            model: adapter?.enabled ? paired : []
            delegate: SettingRow {
                required property var modelData
                required property int index
                label: modelData.name
                hint: modelData.connected ? (modelData.batteryAvailable ? "Connected · " + Math.round(modelData.battery * 100) + "%" : "Connected") : "Not connected"
                last: index === paired.length - 1
                LinkButton {
                    text: modelData.connected ? "Disconnect" : "Connect"
                    onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                }
            }
        }
    }
    Group {
        title: "Devices"
        SettingRow {
            label: "Pair a new device"
            hint: "Opens the Bluetooth menu in the menu bar"
            LinkButton { text: "Pair…"; onClicked: Ui.openPanel = "bluetooth" }
        }
        SettingRow {
            label: "Advanced device settings"
            last: true
            LinkButton { text: "Bluetooth Manager…"; onClicked: Ui.launch("blueman-manager") }
        }
    }
}
