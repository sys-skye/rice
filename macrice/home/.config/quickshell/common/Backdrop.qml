import QtQuick
import Quickshell
import Quickshell.Wayland

// Invisible full-screen layer behind an open dropdown/menu.
// Clicking it (anywhere outside the dropdown) closes the dropdown.
PanelWindow {
    id: root
    property bool active: false
    property bool coverBar: false   // false: stop below the menu bar so its icons still work
    signal dismissed()

    visible: active
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: coverBar ? ExclusionMode.Ignore : ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "backdrop"

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: root.dismissed()
    }
}
