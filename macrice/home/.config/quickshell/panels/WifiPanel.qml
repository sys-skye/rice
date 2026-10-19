import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.common

Panel {
    id: root
    name: "wifi"
    panelWidth: 290

    readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var networks: device
        ? device.networks.values.slice().sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))
        : []
    property string askPasswordFor: ""
    property string error: ""

    function strength(n) { return n.signalStrength > 1 ? n.signalStrength / 100 : n.signalStrength }

    onVisibleChanged: {
        if (device) device.scannerEnabled = visible
        if (!visible) { askPasswordFor = ""; error = "" }
    }

    SectionTitle {
        text: "Wi-Fi"
        Toggle {
            checked: Networking.wifiEnabled
            onToggled: v => Networking.wifiEnabled = v
        }
    }

    MenuSeparator { visible: Networking.wifiEnabled }

    Label {
        x: 8
        visible: Networking.wifiEnabled && root.networks.length === 0
        text: "Searching for networks…"
        dim: true
        height: 28
    }

    Repeater {
        model: Networking.wifiEnabled ? root.networks.slice(0, 12) : []
        delegate: Column {
            required property var modelData
            width: parent.width

            ListRow {
                icon: Glyphs.wifiIcon(root.strength(modelData))
                text: modelData.name
                highlighted: modelData.connected
                busy: modelData.stateChanging
                subtitle: modelData.connected ? "Connected" : ""
                Icon {
                    visible: modelData.security !== WifiSecurityType.Open
                    text: Glyphs.lock
                    size: 12
                    color: Theme.textDim
                }
                onClicked: {
                    root.error = ""
                    if (modelData.connected) return
                    if (modelData.known || modelData.security === WifiSecurityType.Open) modelData.connect()
                    else root.askPasswordFor = root.askPasswordFor === modelData.name ? "" : modelData.name
                }
            }

            // Password field for new secured networks
            Rectangle {
                visible: root.askPasswordFor === modelData.name
                onVisibleChanged: if (visible) password.forceActiveFocus()
                width: parent.width
                height: 34
                radius: 8
                color: Theme.fg(0.08)
                border.color: password.activeFocus ? Theme.accent : Theme.panelBorder

                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !password.text
                        text: "Password — press Enter to join"
                        dim: true
                    }
                    Keys.onEscapePressed: root.askPasswordFor = ""
                    onAccepted: {
                        join.command = ["nmcli", "device", "wifi", "connect", modelData.name, "password", text]
                        join.running = true
                        text = ""
                    }
                }
            }
        }
    }

    Label {
        x: 8
        width: parent.width - 16
        visible: root.error !== ""
        text: root.error
        color: Theme.red
        wrapMode: Text.Wrap
    }

    MenuSeparator {}
    MenuItem {
        text: "Network Settings…"
        onClicked: { Ui.openPanel = ""; Ui.launch("nm-connection-editor") }
    }

    Process {
        id: join
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.error = text.trim().replace(/^Error: /, "") }
        onExited: code => { if (code === 0) root.askPasswordFor = "" }
    }
}
