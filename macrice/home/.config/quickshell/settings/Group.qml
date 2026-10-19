import QtQuick
import qs.common

// Rounded box of rows, like a group in macOS System Settings
Column {
    id: root
    property string title: ""
    property string footer: ""
    default property alias rows: box.data
    width: parent ? parent.width : 400
    spacing: 6

    Label { visible: root.title !== ""; text: root.title; bold: true; leftPadding: 4; height: 22 }
    Rectangle {
        width: parent.width
        height: box.implicitHeight
        radius: 10
        color: Theme.fg(0.05)
        border.color: Theme.fg(0.07)
        Column { id: box; width: parent.width }
    }
    Label {
        visible: root.footer !== ""
        width: parent.width
        text: root.footer
        dim: true
        font.pixelSize: Theme.smallFontSize
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        leftPadding: 4
    }
    Item { width: 1; height: 8 }
}
