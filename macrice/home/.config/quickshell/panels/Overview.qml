import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

// Mission Control–style overview: live thumbnails of every open window on
// every Space. Three-finger swipe up (or ⌃⌘↑) opens it. Point at a window and
// swipe down (or click it) to go there; middle-click closes a window;
// Esc / click empty space / swipe down with nothing under the pointer leaves.
PanelWindow {
    id: root
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "overview"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Windows sorted by Space, then left-to-right, top-to-bottom
    readonly property var windows: Hyprland.toplevels.values
        .filter(t => t.wayland && t.workspace && t.workspace.id > 0 && (t.lastIpcObject?.mapped ?? true))
        .sort((a, b) => (a.workspace.id - b.workspace.id)
                      || ((a.lastIpcObject?.at?.[1] ?? 0) - (b.lastIpcObject?.at?.[1] ?? 0))
                      || ((a.lastIpcObject?.at?.[0] ?? 0) - (b.lastIpcObject?.at?.[0] ?? 0)))

    // Spaces are numbered per display (hypr/scripts/space): 101 on the external screen is its Space 1
    function spaceNumber(ws) {
        return Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === ws.monitor)
            .map(w => w.id).sort((a, b) => a - b).indexOf(ws.id) + 1
    }

    // Pick the column count that makes thumbnails as big as possible
    readonly property real areaW: width - 120
    readonly property real areaH: height - 200
    readonly property int labelH: 30
    readonly property int gap: 28
    readonly property var grid: {
        const n = Math.max(1, windows.length)
        let best = { cols: 1, rows: n, cellW: areaW, cellH: areaH / n }
        let bestScore = 0
        for (let cols = 1; cols <= n; cols++) {
            const rows = Math.ceil(n / cols)
            const cellW = (areaW - gap * (cols - 1)) / cols
            const cellH = (areaH - gap * (rows - 1)) / rows - labelH
            // assume 16:10 windows when scoring
            const score = Math.min(cellW, cellH * 1.6)
            if (score > bestScore) { bestScore = score; best = { cols, rows, cellW, cellH } }
        }
        return best
    }

    property var hovered: null          // window under the pointer

    function open() {
        hovered = null
        Hyprland.refreshToplevels()
        Ui.openPanel = ""
        visible = true
        content.opacity = 0
        content.scale = 0.94
        showAnim.restart()
    }
    function close() { visible = false }
    function go(t) {
        close()
        const addr = t.lastIpcObject?.address
        if (addr) Hyprland.dispatch("focuswindow address:" + addr)
        else t.wayland?.activate()
    }

    Connections {
        target: Ui
        function onOverviewOpenChanged() { Ui.overviewOpen ? root.open() : root.close() }
        function onOverviewCommitChanged() { root.hovered ? root.go(root.hovered) : root.close() }
    }
    onVisibleChanged: if (!visible) Ui.overviewOpen = false

    // Dimmed, frosted backdrop (Hyprland blurs the "overview" layer)
    Rectangle {
        anchors.fill: parent
        color: Theme.dim
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Item {
        anchors.fill: parent
        focus: root.visible
        Keys.onEscapePressed: root.close()
    }

    Item {
        id: content
        anchors.fill: parent

        ParallelAnimation {
            id: showAnim
            NumberAnimation { target: content; property: "opacity"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { target: content; property: "scale"; to: 1; duration: 220; easing.type: Easing.OutCubic }
        }

        Label {
            anchors.centerIn: parent
            visible: root.windows.length === 0
            text: "No open windows"
            font.pixelSize: 18
            dim: true
        }

        Grid {
            id: gridView
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 10
            columns: root.grid.cols
            columnSpacing: root.gap
            rowSpacing: root.gap

            Repeater {
                model: root.visible ? root.windows : []
                delegate: Item {
                    id: cell
                    required property var modelData
                    readonly property var ipc: modelData.lastIpcObject ?? ({})
                    readonly property real winW: ipc.size?.[0] ?? 16
                    readonly property real winH: ipc.size?.[1] ?? 10
                    readonly property real s: Math.min(root.grid.cellW / winW, root.grid.cellH / winH, 1)
                    readonly property var entry: DesktopEntries.heuristicLookup(modelData.wayland?.appId ?? "")
                    width: root.grid.cellW
                    height: root.grid.cellH + root.labelH

                    Rectangle {
                        id: frame
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: (root.grid.cellH - height) / 2
                        width: cell.winW * cell.s + 6
                        height: cell.winH * cell.s + 6
                        radius: 12
                        color: "transparent"
                        border.width: 3
                        border.color: mouse.containsMouse ? Theme.accent : "transparent"
                        scale: mouse.containsMouse ? 1.03 : 1
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        ClippingRectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: 9
                            color: Theme.fg(0.06)
                            ScreencopyView {
                                anchors.fill: parent
                                captureSource: cell.modelData.wayland
                                live: true
                                constraintSize: Qt.size(width, height)
                            }
                        }
                    }

                    // App icon + name under the thumbnail
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: frame.y + frame.height + 8
                        spacing: 7
                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 20
                            source: Quickshell.iconPath(cell.entry?.icon || cell.modelData.wayland?.appId || "", "application-x-executable")
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, root.grid.cellW - 80)
                            text: (cell.entry?.name ?? cell.ipc.class ?? "") +
                                  (cell.modelData.workspace.id !== Hyprland.focusedWorkspace?.id ? "  ·  Space " + root.spaceNumber(cell.modelData.workspace) : "")
                            bold: mouse.containsMouse
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: frame
                        hoverEnabled: true
                        onContainsMouseChanged: {
                            if (containsMouse) root.hovered = cell.modelData
                            else if (root.hovered === cell.modelData) root.hovered = null
                        }
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: e => e.button === Qt.MiddleButton ? cell.modelData.wayland?.close() : root.go(cell.modelData)
                    }
                }
            }
        }
    }
}
