import QtQuick
import qs.common

// Round colour swatches; "auto" draws a half light / half dark dot
Row {
    id: sw
    property var colors: []
    property string value
    signal picked(string value)
    spacing: 7
    Repeater {
        model: sw.colors
        delegate: Rectangle {
            required property string modelData
            readonly property bool selected: sw.value === modelData
            width: 20; height: 20; radius: 10
            color: modelData === "auto" ? "transparent" : modelData
            border.width: selected ? 2 : 1
            border.color: selected ? Theme.fg(0.85) : Theme.fg(0.2)
            gradient: modelData === "auto" ? autoGrad : null
            Gradient {
                id: autoGrad
                orientation: Gradient.Horizontal
                GradientStop { position: 0.49; color: "#f5f5f7" }
                GradientStop { position: 0.51; color: "#3a3a40" }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sw.picked(parent.modelData) }
        }
    }
}
