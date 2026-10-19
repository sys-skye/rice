import QtQuick
import Quickshell
import qs.common

// AirDrop: be visible to nearby Apple devices, and send files to them (omdrop).
Panel {
    id: root
    name: "airdrop"
    panelWidth: 300

    onVisibleChanged: {
        AirDrop.watchingPeers = visible
        if (visible) { AirDrop.refresh(); AirDrop.scanPeers(true) }
    }

    // Small pill buttons, like the Sleep Timer presets in Control Center
    component Chip: Rectangle {
        id: chip
        property string text
        property bool selected: false
        signal clicked()
        height: 24
        radius: 7
        color: selected ? Theme.accent : chipMouse.containsMouse ? Theme.hover : Theme.fg(0.08)
        Behavior on color { ColorAnimation { duration: 120 } }
        Label {
            anchors.centerIn: parent
            text: chip.text
            font.pixelSize: 11
            color: chip.selected ? "white" : Theme.text
        }
        MouseArea { id: chipMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.clicked() }
    }

    function signalWord(rssi) { return rssi > -60 ? "Very close" : rssi > -72 ? "Nearby" : "Far" }

    SectionTitle {
        text: "AirDrop"
        Row {
            spacing: 8
            RefreshButton {
                anchors.verticalCenter: parent.verticalCenter
                visible: AirDrop.receiving
                busy: AirDrop.scanning
                onClicked: AirDrop.scanPeers(true)
            }
            Toggle {
                anchors.verticalCenter: parent.verticalCenter
                checked: AirDrop.receiving
                opacity: AirDrop.busy ? 0.6 : 1
                onToggled: v => AirDrop.setOn(v)
            }
        }
    }
    Label {
        x: 4
        width: parent.width - 8
        dim: true
        font.pixelSize: Theme.smallFontSize
        wrapMode: Text.Wrap
        text: !AirDrop.available ? "omdrop isn't set up. Run: omdrop doctor"
            : AirDrop.receiving ? "Visible as “" + AirDrop.deviceName + "” · " + AirDrop.summary
            : "Off · nearby iPhones and Macs can't see this computer"
    }

    Item { width: 1; height: 4 }
    Label { x: 4; height: 20; text: "Receiving from"; dim: true; font.pixelSize: Theme.smallFontSize; font.weight: Font.DemiBold }
    Row {
        width: parent.width
        spacing: 4
        Repeater {
            model: [["everyone", "Everyone"], ["contacts", "Contacts Only"]]
            delegate: Chip {
                required property var modelData
                width: (parent.width - 4) / 2
                text: modelData[1]
                selected: AirDrop.visibility === modelData[0]
                onClicked: AirDrop.setVisibility(modelData[0])
            }
        }
    }
    Item { width: 1; height: 2 }
    Label { x: 4; height: 20; text: "Stay visible"; dim: true; font.pixelSize: Theme.smallFontSize; font.weight: Font.DemiBold }
    Row {
        width: parent.width
        spacing: 4
        Repeater {
            model: [["once", "1 file"], ["10m", "10 min"], ["1h", "1 hour"], ["forever", "Always"]]
            delegate: Chip {
                required property var modelData
                width: (parent.width - 12) / 4
                text: modelData[1]
                selected: AirDrop.receiving ? (AirDrop.mode === "once" ? modelData[0] === "once"
                                             : AirDrop.mode === "forever" ? modelData[0] === "forever"
                                             : modelData[0] === AirDrop.duration)
                                           : modelData[0] === AirDrop.duration
                onClicked: AirDrop.setDuration(modelData[0])
            }
        }
    }

    MenuSeparator {}
    Label {
        x: 8; height: 22
        dim: true; font.pixelSize: Theme.smallFontSize; font.weight: Font.DemiBold
        text: !AirDrop.receiving ? "Turn AirDrop on to see nearby devices"
            : AirDrop.peers.length ? "Nearby — click to send files" : "Looking for devices…"
    }
    Repeater {
        model: AirDrop.receiving ? AirDrop.peers.slice(0, 8) : []
        delegate: ListRow {
            required property var modelData
            readonly property bool target: AirDrop.sendingTo === modelData.mac
            readonly property string model: AirDrop.modelOf(modelData)
            icon: /Mac/.test(model) ? Glyphs.laptop : /iPhone|iPad/.test(model) ? Glyphs.phone : Glyphs.logo
            text: AirDrop.nameOf(modelData) || "Apple device"
            highlighted: target
            busy: target && AirDrop.sending
            subtitle: target && AirDrop.sendStatus ? AirDrop.sendStatus : root.signalWord(modelData.rssi)
            Icon {
                visible: target && AirDrop.sending
                text: Glyphs.close
                size: 13
                color: Theme.textDim
                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: AirDrop.cancelSend() }
            }
            onClicked: {
                if (AirDrop.sending) return
                // The file chooser is a normal window: close the dropdown so its
                // click-catching backdrop doesn't sit on top of it
                Ui.openPanel = ""
                AirDrop.sendTo(modelData.mac)
            }
        }
    }

    Label {
        x: 8
        width: parent.width - 16
        visible: AirDrop.receiving && AirDrop.peers.some(p => !AirDrop.nameOf(p))
        text: AirDrop.scanning ? "Asking nearby devices for their names…"
            : "Names appear once a device has sent you something, or while its AirDrop is set to Everyone."
        dim: true
        font.pixelSize: Theme.smallFontSize
        wrapMode: Text.Wrap
        topPadding: 2
    }

    MenuSeparator {}
    MenuItem {
        text: "Open Received Files"
        onClicked: { Ui.openPanel = ""; AirDrop.openDownloads() }
    }
}
