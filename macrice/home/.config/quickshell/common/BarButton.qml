import QtQuick

// Hoverable item in the menu bar. Put an Icon/Label (or a Row) inside.
Item {
    id: root
    default property alias content: inner.data
    property bool active: false
    property int padding: 8
    property int vInset: 6
    signal clicked()
    signal rightClicked()

    implicitWidth: inner.childrenRect.width + padding * 2
    implicitHeight: Theme.barHeight

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: root.vInset
        anchors.bottomMargin: root.vInset
        radius: 6
        color: root.active ? Theme.fg(0.22) : mouse.containsMouse ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Item {
        id: inner
        x: root.padding
        width: childrenRect.width
        height: parent.height
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        // Act on press, like macOS: a tap that drifts a few pixels before release still counts
        onPressed: e => e.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
