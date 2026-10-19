import QtQuick
import qs.common

// macOS-style slider: thin track, round knob, optional end labels and ticks
Item {
    id: root
    property real from: 0
    property real to: 1
    property real value: 0.5
    property real stepSize: 0          // 0 = continuous
    property int ticks: 0              // number of tick marks under the track
    property string minLabel: ""
    property string maxLabel: ""
    signal moved(real value)

    implicitWidth: 260
    implicitHeight: minLabel || maxLabel ? 38 : 22

    readonly property real frac: (Math.max(from, Math.min(to, value)) - from) / (to - from)

    Item {
        id: trackArea
        width: parent.width
        height: 22

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            x: 9; width: parent.width - 18; height: 4; radius: 2
            color: Theme.fg(0.16)
            Rectangle { width: parent.width * root.frac; height: parent.height; radius: 2; color: Theme.accent }
        }
        Repeater {
            model: root.ticks
            delegate: Rectangle {
                required property int index
                x: track.x + track.width * index / (root.ticks - 1) - 1
                y: track.y + 9
                width: 2; height: 5; radius: 1
                color: Theme.fg(0.3)
            }
        }
        Rectangle {
            x: track.x + track.width * root.frac - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18; radius: 9
            color: drag.pressed ? "#e6e6e6" : "white"
            border.color: Qt.rgba(0, 0, 0, 0.25)
        }
        MouseArea {
            id: drag
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function update(mx) {
                let v = root.from + Math.max(0, Math.min(1, (mx - track.x) / track.width)) * (root.to - root.from)
                if (root.stepSize > 0) v = Math.round(v / root.stepSize) * root.stepSize
                if (v !== root.value) root.moved(v)
            }
            onPressed: e => update(e.x)
            onPositionChanged: e => { if (pressed) update(e.x) }
        }
    }
    Label { visible: root.minLabel !== ""; y: 24; x: 2; text: root.minLabel; dim: true; font.pixelSize: 10 }
    Label { visible: root.maxLabel !== ""; y: 24; anchors.right: parent.right; anchors.rightMargin: 2; text: root.maxLabel; dim: true; font.pixelSize: 10 }
}
