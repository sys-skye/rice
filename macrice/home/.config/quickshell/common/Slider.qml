import QtQuick

// Control Center slider: rounded track with an icon inside
Item {
    id: root
    property real value: 0.5           // 0..1
    property string icon: ""
    signal moved(real value)

    width: parent ? parent.width : 200
    height: 26

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.fg(0.12)
        clip: true

        Rectangle {
            width: Math.max(track.height, track.width * root.value)
            height: parent.height
            radius: height / 2
            color: Theme.sliderFill
        }
    }
    Icon {
        x: 7
        anchors.verticalCenter: parent.verticalCenter
        size: 14
        text: root.icon
        color: "#3a3a3c"
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function set(mx) { root.moved(Math.max(0, Math.min(1, mx / width))) }
        onPressed: e => set(e.x)
        onPositionChanged: e => { if (pressed) set(e.x) }
        onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
