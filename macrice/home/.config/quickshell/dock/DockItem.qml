import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

Item {
    id: root
    required property var item          // { key, entry, appId, toplevels, pinned }
    required property var dockWindow
    property int pinnedIndex: -1        // position in the pinned list, -1 = not pinned
    readonly property bool running: item.toplevels.length > 0
    readonly property string name: item.entry ? item.entry.name : item.appId
    readonly property bool beingDragged: dockWindow.dragKey === item.key
    property bool menuOpen: false
    onMenuOpenChanged: {
        // Work out where the icon is right now (icons move as apps open and close)
        if (menuOpen) {
            const p = root.mapToItem(null, root.width / 2, 0)
            menu.margins.left = Math.max(8, Math.min(p.x - menu.implicitWidth / 2, dockWindow.width - menu.implicitWidth - 8))
        }
        dockWindow.menuOpen = menuOpen
    }

    width: dockWindow.size
    height: dockWindow.size
    opacity: beingDragged ? 0 : 1

    // Slide aside to make room while another icon is dragged
    transform: Translate {
        x: root.dockWindow.shiftFor(root.pinnedIndex)
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    function launch() {
        if (!item.entry) return
        bounce.restart()
        Ui.launch(item.entry.id + ".desktop")
    }
    function activate() {
        const tops = item.toplevels
        if (tops.length === 0) return launch()
        // Already focused → cycle through this app's windows
        const i = tops.findIndex(t => t.activated)
        tops[(i + 1) % tops.length].activate()
    }

    IconImage {
        id: icon
        anchors.centerIn: parent
        implicitSize: root.dockWindow.size - 4
        source: Quickshell.iconPath(root.item.entry?.icon || root.item.appId, "application-x-executable")
        scale: mouse.containsMouse && !root.dockWindow.dragging ? 1.14 : 1
        transformOrigin: Item.Bottom
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        SequentialAnimation on anchors.verticalCenterOffset {
            id: bounce
            running: false
            loops: 2
            NumberAnimation { to: -14; duration: 220; easing.type: Easing.OutQuad }
            NumberAnimation { to: 0; duration: 220; easing.type: Easing.InQuad }
        }
    }

    // "running" dot
    Rectangle {
        visible: root.running
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 2
        width: 4; height: 4; radius: 2
        color: Theme.fg(0.85)
    }

    // Name bubble above the icon
    Rectangle {
        visible: mouse.containsMouse && !root.menuOpen && !root.dockWindow.dragging
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 18
        width: tip.implicitWidth + 20
        height: 26
        radius: 8
        color: Theme.panelSolid
        border.color: Theme.panelBorder
        Label { id: tip; anchors.centerIn: parent; text: root.name }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        property point pressAt

        onPressed: e => pressAt = mapToItem(null, e.x, e.y)
        onPositionChanged: e => {
            if (!(pressedButtons & Qt.LeftButton)) return
            const p = mapToItem(null, e.x, e.y)
            if (root.beingDragged) root.dockWindow.moveDrag(p)
            else if (!root.dockWindow.dragging && root.item.entry && Math.hypot(p.x - pressAt.x, p.y - pressAt.y) > 8)
                root.dockWindow.startDrag(root.item, root.pinnedIndex, p)
        }
        onReleased: if (root.beingDragged) root.dockWindow.endDrag()
        onClicked: e => {
            if (root.dockWindow.justDragged) return
            if (e.button === Qt.RightButton) root.menuOpen = true
            else if (e.button === Qt.MiddleButton) root.launch()
            else root.activate()
        }
    }

    // Right-click menu: its own layer above the dock, plus a backdrop to close it
    Backdrop {
        screen: root.dockWindow.screen
        active: root.menuOpen
        coverBar: true
        onDismissed: root.menuOpen = false
    }
    PanelWindow {
        id: menu
        screen: root.dockWindow.screen
        visible: root.menuOpen
        color: "transparent"
        anchors { bottom: true; left: true }
        exclusionMode: ExclusionMode.Ignore
        margins.bottom: root.dockWindow.size + 40
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "dropdown"
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        implicitWidth: 230
        implicitHeight: menuCol.implicitHeight + 10

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.menuOpen = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Theme.panelBg
            border.color: Theme.panelBorder
            Column {
                id: menuCol
                x: 5; y: 5
                width: parent.width - 10
                Repeater {
                    model: root.item.toplevels
                    delegate: MenuItem {
                        required property var modelData
                        text: modelData.title || root.name
                        checked: modelData.activated
                        onClicked: { root.menuOpen = false; modelData.activate() }
                    }
                }
                MenuSeparator { visible: root.running }
                MenuItem {
                    text: root.running ? "New Window" : "Open"
                    visible: root.item.entry !== null
                    onClicked: { root.menuOpen = false; root.launch() }
                }
                Repeater {
                    model: root.item.entry ? root.item.entry.actions : []
                    delegate: MenuItem {
                        required property var modelData
                        text: modelData.name
                        visible: !/^new.window$/i.test(modelData.name)
                        onClicked: { root.menuOpen = false; modelData.execute() }
                    }
                }
                MenuSeparator { visible: root.item.entry !== null }
                MenuItem {
                    visible: root.item.entry !== null
                    text: root.item.pinned ? "Remove from Dock" : "Keep in Dock"
                    onClicked: {
                        root.menuOpen = false
                        root.item.pinned ? DockState.unpin(root.item.key) : DockState.pin(root.item.key)
                    }
                }
                MenuSeparator { visible: root.running }
                MenuItem {
                    visible: root.running
                    text: "Quit"
                    destructive: true
                    onClicked: { root.menuOpen = false; for (const t of root.item.toplevels) t.close() }
                }
            }
        }
    }
}
