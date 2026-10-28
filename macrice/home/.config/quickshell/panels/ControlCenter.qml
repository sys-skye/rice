import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.common

Panel {
    id: root
    name: "control"
    panelWidth: 320
    spacing: 10
    padding: 10

    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNet: wifiDev ? wifiDev.networks.values.find(n => n.connected) ?? null : null
    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    PwObjectTracker { objects: [root.sink] }
    onOpened: { Ui.refreshBrightness(); SleepTimer.tick() }

    // A rounded tile with a round icon button and two lines of text
    component Tile: Rectangle {
        id: tile
        property string icon
        property string title
        property string subtitle: ""
        property bool on: false
        property bool compact: false
        signal toggled()
        signal opened()
        height: compact ? 44 : 50
        radius: 12
        color: Theme.tileBg
        Rectangle {
            id: dot
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 30; height: 30; radius: 15
            color: tile.on ? Theme.accent : Theme.fg(0.14)
            Behavior on color { ColorAnimation { duration: 150 } }
            Icon { anchors.centerIn: parent; text: tile.icon; size: 15 }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tile.toggled() }
        }
        Column {
            anchors.left: dot.right
            anchors.leftMargin: 9
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            Label { width: parent.width; text: tile.title; bold: true; font.pixelSize: 12 }
            Label { width: parent.width; text: tile.subtitle; dim: true; font.pixelSize: 11; visible: text !== "" }
        }
        MouseArea { anchors.fill: parent; anchors.leftMargin: 42; z: -1; onClicked: tile.opened() }
    }

    component Block: Rectangle {
        default property alias content: inner.data
        property alias title: heading.text
        width: parent.width
        height: inner.implicitHeight + 34
        radius: 12
        color: Theme.tileBg
        Label { id: heading; x: 12; y: 8; bold: true; font.pixelSize: 12 }
        Column { id: inner; x: 10; y: 28; width: parent.width - 20 }
    }

    Row {
        width: parent.width
        spacing: 10
        // Connectivity: Wi-Fi and Bluetooth share one rounded box, like macOS
        Rectangle {
            width: (parent.width - 10) / 2
            height: toggles.height
            radius: 12
            color: Theme.tileBg
            Column {
                anchors.fill: parent
                anchors.margins: 3
                spacing: (height - 100) / 3
                topPadding: spacing
                Tile {
                    width: parent.width; color: "transparent"
                    icon: Networking.wifiEnabled ? Glyphs.wifi[4] : Glyphs.wifiOff
                    title: "Wi-Fi"
                    subtitle: !Networking.wifiEnabled ? "Off" : root.wifiNet ? root.wifiNet.name : "Not connected"
                    on: Networking.wifiEnabled
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                    onOpened: Ui.openPanel = "wifi"
                }
                Tile {
                    width: parent.width; color: "transparent"
                    icon: root.bt?.enabled ? Glyphs.bluetooth : Glyphs.bluetoothOff
                    title: "Bluetooth"
                    subtitle: !root.bt?.enabled ? "Off" : root.btConnected.length ? root.btConnected[0].name : "On"
                    on: root.bt?.enabled ?? false
                    onToggled: if (root.bt) root.bt.enabled = !root.bt.enabled
                    onOpened: Ui.openPanel = "bluetooth"
                }
            }
        }
        Column {
            id: toggles
            width: (parent.width - 10) / 2
            spacing: 10
            Tile {
                width: parent.width
                icon: Ui.dnd ? Glyphs.bellOff : Glyphs.bell
                title: "Do Not Disturb"
                subtitle: Ui.dnd ? "On" : "Off"
                on: Ui.dnd
                onToggled: Ui.setDnd(!Ui.dnd)
                onOpened: Ui.setDnd(!Ui.dnd)
            }
            Tile {
                width: parent.width
                icon: Glyphs.coffee
                title: "Keep Awake"
                subtitle: Ui.keepAwake ? "On" : "Off"
                on: Ui.keepAwake
                onToggled: Ui.keepAwake = !Ui.keepAwake
                onOpened: Ui.keepAwake = !Ui.keepAwake
            }
            Tile {
                width: parent.width
                icon: Theme.isDark ? Glyphs.night : Glyphs.brightness
                title: "Dark Mode"
                subtitle: Appearance.mode === "auto" ? (Theme.isDark ? "On · Auto" : "Off · Auto") : (Theme.isDark ? "On" : "Off")
                on: Theme.isDark
                onToggled: Appearance.toggle()
                onOpened: Ui.openSettings("appearance")
            }
        }
    }

    Block {
        title: "Display"
        Slider {
            icon: Glyphs.brightness
            value: Ui.brightness
            onMoved: v => Ui.setBrightness(v)
        }
        Item { width: 1; height: 8 }
        Item {
            width: parent.width; height: 26
            Icon { x: 2; anchors.verticalCenter: parent.verticalCenter; text: Glyphs.night; size: 15; color: Ui.nightLight ? Theme.orange : Theme.text }
            Label { x: 26; anchors.verticalCenter: parent.verticalCenter; text: "Night Shift" }
            Toggle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; checked: Ui.nightLight; onToggled: v => Ui.setNightLight(v) }
        }
    }

    Block {
        title: SleepTimer.active ? "Sleep Timer · sleeping in " + SleepTimer.minutesLeft + " min" : "Sleep Timer"
        Row {
            width: parent.width
            spacing: 4
            Repeater {
                model: [0].concat(SleepTimer.presets)
                delegate: Rectangle {
                    required property int modelData
                    readonly property bool selected: modelData === 0 ? !SleepTimer.active
                                                                     : SleepTimer.active && SleepTimer.chosen === modelData
                    width: (parent.width - 4 * 6) / 7
                    height: 26
                    radius: 7
                    color: selected ? (modelData === 0 ? Theme.fg(0.22) : Theme.accent)
                         : chip.containsMouse ? Theme.hover : Theme.fg(0.08)
                    Label {
                        anchors.centerIn: parent
                        text: modelData === 0 ? "Off" : modelData < 60 ? modelData + "m" : (modelData / 60) + "h"
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: chip
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: modelData === 0 ? SleepTimer.cancel() : SleepTimer.start(modelData)
                    }
                }
            }
        }
    }

    Block {
        title: "Sound"
        Slider {
            icon: Glyphs.volumeIcon(value, root.sink?.audio?.muted ?? false)
            value: root.sink?.audio?.volume ?? 0
            onMoved: v => { if (root.sink?.audio) { root.sink.audio.muted = false; root.sink.audio.volume = v } }
        }
    }

    Rectangle {
        visible: root.player !== null
        width: parent.width
        height: 84
        radius: 12
        color: Theme.tileBg
        MediaCard { player: root.player; x: 6; width: parent.width - 12; anchors.verticalCenter: parent.verticalCenter }
    }
}
