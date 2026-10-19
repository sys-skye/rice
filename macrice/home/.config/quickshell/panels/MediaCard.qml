import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.common

// Album art + title + controls. Used in the Now Playing dropdown and Control Center.
Item {
    id: root
    property var player: null
    height: 72
    visible: player !== null

    ClippingRectangle {
        id: art
        width: 60; height: 60
        anchors.verticalCenter: parent.verticalCenter
        x: 4
        radius: 10
        color: Theme.fg(0.1)
        Icon { anchors.centerIn: parent; text: Glyphs.music; size: 24; color: Theme.textDim }
        Image {
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }
    Column {
        anchors.left: art.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Label { width: parent.width; text: root.player?.trackTitle || root.player?.identity || ""; bold: true }
        Label { width: parent.width; text: root.player?.trackArtist ?? ""; dim: true; visible: text !== "" }
        Row {
            spacing: 4
            Repeater {
                model: [
                    { icon: Glyphs.previous, act: "previous", ok: root.player?.canGoPrevious },
                    { icon: root.player?.isPlaying ? Glyphs.pause : Glyphs.play, act: "togglePlaying", ok: root.player?.canTogglePlaying },
                    { icon: Glyphs.next, act: "next", ok: root.player?.canGoNext },
                ]
                delegate: BarButton {
                    required property var modelData
                    implicitHeight: 30
                    padding: 6
                    vInset: 0
                    opacity: modelData.ok ? 1 : 0.35
                    Icon { anchors.verticalCenter: parent.verticalCenter; text: modelData.icon; size: 18 }
                    onClicked: if (modelData.ok) root.player[modelData.act]()
                }
            }
        }
    }
}
