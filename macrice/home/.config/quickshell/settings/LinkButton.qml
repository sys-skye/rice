import QtQuick
import qs.common

// Small rounded push button ("Open…", "Advanced…")
Rectangle {
    id: root
    property string text
    property bool primary: false
    signal clicked()
    implicitWidth: lbl.implicitWidth + 24
    implicitHeight: 26
    radius: 7
    color: primary ? (mouse.containsMouse ? Qt.lighter(Theme.accent, 1.15) : Theme.accent)
                   : (mouse.containsMouse ? Theme.fg(0.2) : Theme.fg(0.12))
    Label { id: lbl; anchors.centerIn: parent; text: root.text; font.pixelSize: 12 }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
