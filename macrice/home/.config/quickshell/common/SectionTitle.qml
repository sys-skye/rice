import QtQuick

// Bold heading row, with an optional control (e.g. a Toggle) on the right.
Item {
    id: root
    property string text
    default property alias trailing: right.data
    width: parent ? parent.width : 200
    height: 30
    Label {
        x: 4
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        bold: true
        font.pixelSize: 14
    }
    Item {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
