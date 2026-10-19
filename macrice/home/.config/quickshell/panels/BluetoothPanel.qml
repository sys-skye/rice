import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.common

Panel {
    id: root
    name: "bluetooth"
    panelWidth: 290

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter ? adapter.enabled : false
    readonly property var devices: Bluetooth.devices.values
    readonly property var myDevices: devices.filter(d => d.paired || d.connected)
        .sort((a, b) => b.connected - a.connected)
    readonly property var nearby: devices.filter(d => !d.paired && !d.connected && d.name && d.name !== d.address
                                                  && d.name.replace(/-/g, ":") !== d.address)

    onVisibleChanged: if (adapter && adapter.enabled) adapter.discovering = visible

    // Restart discovery (BlueZ sometimes stops reporting new devices after a while)
    function refresh() {
        if (!on) return
        adapter.discovering = false
        restartDiscovery.restart()
        settle.restart()
    }
    Timer {
        id: restartDiscovery
        interval: 400
        onTriggered: if (root.on && root.visible) root.adapter.discovering = true
    }
    Timer { id: settle; interval: 3000 }
    // Turning Bluetooth on with the dropdown open should start looking for devices straight away
    onOnChanged: if (on && visible) adapter.discovering = true

    SectionTitle {
        text: "Bluetooth"
        Row {
            spacing: 8
            RefreshButton {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.on
                busy: restartDiscovery.running || settle.running
                onClicked: root.refresh()
            }
            Toggle {
                anchors.verticalCenter: parent.verticalCenter
                checked: root.on
                onToggled: v => { if (root.adapter) root.adapter.enabled = v }
            }
        }
    }

    MenuSeparator { visible: root.on }
    Label { x: 8; height: 22; visible: root.on && root.myDevices.length > 0; text: "Devices"; dim: true; font.pixelSize: Theme.smallFontSize; font.weight: Font.DemiBold }

    Repeater {
        model: root.on ? root.myDevices : []
        delegate: ListRow {
            required property var modelData
            icon: Glyphs.deviceIcon(modelData.icon)
            text: modelData.name
            highlighted: modelData.connected
            busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
            subtitle: modelData.connected
                ? (modelData.batteryAvailable ? "Connected · " + Math.round(modelData.battery * 100) + "%" : "Connected")
                : "Not connected"
            onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
        }
    }

    Label { x: 8; height: 22; visible: root.on; text: root.nearby.length ? "Nearby" : "Looking for devices…"; dim: true; font.pixelSize: Theme.smallFontSize; font.weight: Font.DemiBold }

    Repeater {
        model: root.on ? root.nearby.slice(0, 8) : []
        delegate: ListRow {
            required property var modelData
            icon: Glyphs.deviceIcon(modelData.icon)
            text: modelData.name
            busy: modelData.pairing
            subtitle: modelData.pairing ? "Pairing…" : ""
            onClicked: { modelData.trusted = true; modelData.pair() }
        }
    }

    MenuSeparator {}
    MenuItem {
        text: "Bluetooth Settings…"
        onClicked: { Ui.openPanel = ""; Ui.launch("blueman-manager") }
    }
}
