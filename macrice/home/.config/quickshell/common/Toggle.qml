import QtQuick

// macOS-style switch
Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 34
    implicitHeight: 20
    radius: height / 2
    color: checked ? Theme.accent : Theme.fg(0.18)
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        width: parent.height - 4
        height: width
        radius: width / 2
        y: 2
        x: root.checked ? parent.width - width - 2 : 2
        color: "white"
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        anchors.fill: parent
        anchors.margins: -6          // easier to hit than the 34×20 switch itself
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
