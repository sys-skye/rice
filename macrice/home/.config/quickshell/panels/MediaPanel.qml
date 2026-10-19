import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.common

Panel {
    id: root
    name: "media"
    panelWidth: 300
    property var player: null

    MediaCard { player: root.player; width: parent.width }
}
