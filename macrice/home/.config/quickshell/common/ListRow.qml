import QtQuick

// Row in a list (Wi-Fi network, Bluetooth device, audio output…)
Item {
    id: root
    property string icon: ""
    property string text
    property string subtitle: ""
    property bool highlighted: false   // e.g. connected → blue icon circle
    property bool busy: false
    default property alias trailing: right.data
    signal clicked()

    width: parent ? parent.width : 200
    height: subtitle ? 40 : 34

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: mouse.containsMouse ? Theme.hover : "transparent"
    }
    Rectangle {
        id: circle
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 26
        radius: 13
        color: root.highlighted ? Theme.accent : Theme.fg(0.12)
        Icon {
            anchors.centerIn: parent
            text: root.icon
            size: 14
            opacity: root.busy ? 0.4 : 1
            SequentialAnimation on opacity {
                running: root.busy
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 500 }
                NumberAnimation { to: 1; duration: 500 }
            }
        }
    }
    Column {
        anchors.left: circle.right
        anchors.leftMargin: 10
        anchors.right: right.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        Label { width: parent.width; text: root.text }
        Label { width: parent.width; text: root.subtitle; visible: root.subtitle !== ""; dim: true; font.pixelSize: Theme.smallFontSize }
    }
    Item {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        z: -1
        onClicked: root.clicked()
    }
}
