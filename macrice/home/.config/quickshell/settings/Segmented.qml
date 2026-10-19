import QtQuick
import qs.common

// Segmented picker: options = [{ label, value }]
Rectangle {
    id: root
    property var options: []
    property var value
    signal picked(var value)

    implicitWidth: row.implicitWidth + 4
    implicitHeight: 26
    radius: 7
    color: Theme.fg(0.08)

    Row {
        id: row
        x: 2; y: 2
        height: parent.height - 4
        Repeater {
            model: root.options
            delegate: Rectangle {
                required property var modelData
                readonly property bool selected: root.value === modelData.value
                width: Math.max(64, lbl.implicitWidth + 22)
                height: parent.height
                radius: 5
                color: selected ? Theme.fg(0.22) : mouse.containsMouse ? Theme.hover : "transparent"
                Label { id: lbl; anchors.centerIn: parent; text: modelData.label; font.pixelSize: 12; bold: parent.selected }
                MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.picked(modelData.value) }
            }
        }
    }
}
