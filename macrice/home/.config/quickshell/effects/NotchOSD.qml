import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

// Volume / brightness / keyboard-light indicator that pops out of the notch:
// the notch grows a small black "chin" with an icon and a slim level bar, then
// tucks back in a moment after the last key press.
// Driven by: qs ipc call osd pop <kind> <0-100>   (scripts/osd)
//   kinds: volume, muted, brightness, keyboard, mic, micmuted
Scope {
    id: root

    readonly property var screen: Quickshell.screens.find(s => s.name === "eDP-1") ?? Quickshell.screens[0]
    readonly property real sw: screen?.width ?? 1512

    // Size of the notch, and of the chin when it's out
    readonly property real notchW: Theme.notchWidth * 0.8
    readonly property real notchH: Theme.barHeight
    readonly property real openW: notchW + 14  // just a little wider than the notch
    readonly property real openH: notchH + 26
    readonly property int holdMs: 700           // how long it stays after the last press

    property string kind: "volume"
    property real level: 0                       // 0..1
    property bool out: false

    function show(k, value) {
        kind = k
        level = Math.max(0, Math.min(1, value / 100))
        hideTimer.restart()
        if (out) return
        out = true
        retractAnim.stop()
        popAnim.restart()
    }

    readonly property string icon: {
        switch (kind) {
        case "muted": return Glyphs.volumeMuted
        case "volume": return Glyphs.volumeIcon(level, false)
        case "brightness": return level < 0.4 ? String.fromCodePoint(0xF00DE) : Glyphs.brightness
        case "keyboard": return Glyphs.keyboard
        case "mic": return String.fromCodePoint(0xF036C)
        case "micmuted": return String.fromCodePoint(0xF036D)
        }
        return Glyphs.volumeIcon(level, false)
    }
    readonly property bool showsBar: kind !== "mic" && kind !== "micmuted"

    Timer { id: hideTimer; interval: root.holdMs; onTriggered: { root.out = false; popAnim.stop(); retractAnim.restart() } }

    // Pop out: wider and taller with a little spring, then the contents fade in
    SequentialAnimation {
        id: popAnim
        ScriptAction { script: { chin.width = root.notchW; chin.height = root.notchH; content.opacity = 0; win.visible = true } }
        ParallelAnimation {
            NumberAnimation { target: chin; property: "width"; to: root.openW; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
            NumberAnimation { target: chin; property: "height"; to: root.openH; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
            SequentialAnimation {
                PauseAnimation { duration: 90 }
                NumberAnimation { target: content; property: "opacity"; to: 1; duration: 140 }
            }
        }
    }
    // Tuck back in: contents fade, then the chin shrinks into the notch
    SequentialAnimation {
        id: retractAnim
        NumberAnimation { target: content; property: "opacity"; to: 0; duration: 110; easing.type: Easing.OutQuad }
        ParallelAnimation {
            NumberAnimation { target: chin; property: "width"; to: root.notchW; duration: 320; easing.type: Easing.InOutQuart }
            NumberAnimation { target: chin; property: "height"; to: root.notchH; duration: 300; easing.type: Easing.InOutQuart }
        }
        ScriptAction { script: win.visible = false }
    }

    PanelWindow {
        id: win
        screen: root.screen
        visible: false
        color: "transparent"
        anchors { top: true }
        implicitWidth: root.openW + 60
        implicitHeight: root.openH + 20
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}                           // never takes clicks
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notchosd"

        Rectangle {
            id: chin
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: root.notchW
            height: root.notchH
            radius: 14
            color: "black"
            // flat top, so it reads as part of the notch
            Rectangle { width: parent.width; height: parent.radius; color: "black" }

            Row {
                id: content
                opacity: 0
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.notchH + (root.openH - root.notchH - height) / 2 - 2
                spacing: 9

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.icon
                    size: 13
                    color: root.kind === "muted" || root.kind === "micmuted" ? "#ff6961" : "white"
                }
                // slim level bar
                Rectangle {
                    visible: root.showsBar
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.openW - 52
                    height: 4
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.22)
                    Rectangle {
                        width: parent.width * (root.kind === "muted" ? 0 : root.level)
                        height: parent.height
                        radius: 2
                        color: "white"
                        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    }
                }
                Text {
                    visible: !root.showsBar
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.kind === "micmuted" ? "Microphone off" : "Microphone on"
                    color: "white"
                    font.family: Theme.font
                    font.pixelSize: 11
                }
            }
        }
    }
}
