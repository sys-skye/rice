import QtQuick

// One row of a dropdown menu: text, optional shortcut on the right.
Item {
    id: root
    property string text
    property string shortcut: ""
    property string icon: ""
    property bool destructive: false
    property bool checked: false
    signal clicked()

    width: parent ? parent.width : 200
    height: 26

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: mouse.containsMouse && root.enabled ? Theme.accent : "transparent"
    }
    Icon {
        id: check
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        size: 13
        visible: root.checked || root.icon !== ""
        text: root.checked ? Glyphs.check : root.icon
        color: label.color
    }
    Label {
        id: label
        x: check.visible ? 26 : 10
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - shortcutLabel.width - 16
        text: root.text
        color: !root.enabled ? Theme.textDim : mouse.containsMouse ? "white" : root.destructive ? Theme.red : Theme.text
    }
    Label {
        id: shortcutLabel
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.shortcut
        dim: !mouse.containsMouse
        color: mouse.containsMouse ? "white" : Theme.textDim
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
