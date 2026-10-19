import QtQuick
import qs.common

// One setting: label (+ optional hint) on the left, control on the right
Item {
    id: root
    property string label
    property string hint: ""
    property bool last: false
    default property alias control: right.data
    width: parent ? parent.width : 400
    height: Math.max(hint ? 50 : 40, right.childrenRect.height + 16)

    Column {
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - right.width - 40
        Label { width: parent.width; text: root.label }
        Label { width: parent.width; text: root.hint; visible: root.hint !== ""; dim: true; font.pixelSize: Theme.smallFontSize }
    }
    Item {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
    Rectangle {
        visible: !root.last
        anchors.bottom: parent.bottom
        x: 14
        width: parent.width - 28
        height: 1
        color: Theme.fg(0.07)
    }
}
