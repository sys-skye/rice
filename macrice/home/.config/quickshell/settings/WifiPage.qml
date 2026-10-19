import QtQuick
import Quickshell.Networking
import qs.common

Column {
    width: parent ? parent.width : 500
    readonly property var dev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var net: dev ? dev.networks.values.find(n => n.connected) ?? null : null

    Group {
        title: "Wi-Fi"
        SettingRow {
            label: "Wi-Fi"
            hint: !Networking.wifiEnabled ? "Off" : net ? "Connected to " + net.name : "Not connected"
            Toggle { checked: Networking.wifiEnabled; onToggled: v => Networking.wifiEnabled = v }
        }
        SettingRow {
            label: "Other networks"
            hint: "Opens the Wi-Fi menu in the menu bar"
            last: true
            LinkButton { text: "Choose…"; onClicked: Ui.openPanel = "wifi" }
        }
    }
    Group {
        title: "Advanced"
        SettingRow {
            label: "Saved networks, VPN, IP settings"
            last: true
            LinkButton { text: "Network Connections…"; onClicked: Ui.launch("nm-connection-editor") }
        }
    }
}
