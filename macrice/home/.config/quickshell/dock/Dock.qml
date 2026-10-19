import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common

// macOS-style dock. Pinned apps (DockState) | other running apps | app launcher.
// Drag icons to rearrange, drag a running app into the pinned area to keep it,
// drag a pinned icon up out of the dock to remove it. Auto-hides by default.
PanelWindow {
    id: dock
    // Lives on the main display (System Settings → Displays), the built-in one by default
    screen: (InputSettings.mainDisplay === "external" ? Quickshell.screens.find(s => s.name === InputSettings.extName) : null)
            ?? Quickshell.screens.find(s => s.name === "eDP-1") ?? Quickshell.screens[0]

    readonly property int size: DockState.iconSize
    readonly property int slot: size + row.spacing

    anchors { bottom: true; left: true; right: true }
    implicitHeight: size + 130                      // room for labels / dragging above the dock
    exclusionMode: DockState.autoHide ? ExclusionMode.Ignore : ExclusionMode.Normal
    exclusiveZone: DockState.autoHide ? 0 : size + 24
    color: "transparent"
    WlrLayershell.namespace: "dock"
    WlrLayershell.layer: WlrLayer.Top

    readonly property bool fullscreen: Hyprland.focusedWorkspace?.hasFullscreen ?? false
    readonly property bool emptySpace: DockState.showOnEmptySpace
        && (Hyprland.focusedWorkspace?.toplevels.values.length ?? 1) === 0
    property bool menuOpen: false
    readonly property bool dragging: dragKey !== ""
    readonly property bool wantShow: !fullscreen && (!DockState.autoHide || edgeHover.hovered || dockHover.hovered
                                                     || menuOpen || dragging || emptySpace)
    readonly property bool revealed: wantShow || hideTimer.running

    onWantShowChanged: if (!wantShow) hideTimer.restart()
    Timer { id: hideTimer; interval: Settings.dockHideDelay }

    // Only the visible dock (or a thin strip at the bottom edge) takes the mouse
    mask: Region { item: dock.revealed ? dockBg : edge }

    Item {
        id: edge
        anchors.bottom: parent.bottom
        width: parent.width
        height: dock.fullscreen ? 0 : 3
        HoverHandler { id: edgeHover }
    }

    // ── Items: pinned apps + other running apps ─────────────────────
    readonly property var items: {
        DesktopEntries.applications.values.length   // re-evaluate once entries load
        const groups = []
        const byKey = {}
        const add = (key, entry, appId) => {
            if (!byKey[key]) { byKey[key] = { key: key, entry: entry, appId: appId, toplevels: [], hiddenToplevels: [], pinned: false }; groups.push(byKey[key]) }
            return byKey[key]
        }
        for (const id of DockState.pinned) {
            const e = DesktopEntries.byId(id)
            add(e ? e.id : id, e, id).pinned = true
        }
        // Windows ⌘Q hid (apps kept running in the background) don't count as open
        const hidden = Hyprland.toplevels.values.filter(h => h.workspace?.name === "special:hidden").map(h => h.wayland)
        for (const t of ToplevelManager.toplevels.values) {
            if (!t.appId) continue
            if (t.appId === "dropdown-term") continue   // ⌘` terminal: lives hidden, not a dock app
            const e = DesktopEntries.heuristicLookup(t.appId)
            const g = add(e ? e.id : t.appId, e, t.appId)
            if (hidden.includes(t)) g.hiddenToplevels.push(t)
            else g.toplevels.push(t)
        }
        // Background-only apps take no room in the dock unless pinned
        return groups.filter(g => g.pinned || g.toplevels.length > 0)
    }
    readonly property var pinnedItems: items.filter(i => i.pinned)
    readonly property var runningItems: items.filter(i => !i.pinned)

    // ── Drag & drop ────────────────────────────────────────────────
    property string dragKey: ""
    property var dragItem: null
    property int dragFrom: -1          // index in the pinned list, -1 = dragging a running app
    property point dragPos: Qt.point(0, 0)
    property int dropIndex: -1         // where it would land in the pinned list (-1 = nowhere)
    property bool removing: false      // dragged far enough up to remove
    property bool justDragged: false   // swallow the click that ends a drag

    function startDrag(item, pinnedIndex, p) {
        dragItem = item
        dragFrom = pinnedIndex
        dragKey = item.key
        moveDrag(p)
    }
    function moveDrag(p) {
        dragPos = p
        const r = pinnedRow.mapFromItem(null, p.x, p.y)
        const n = pinnedItems.length
        removing = dragFrom >= 0 && p.y < dockBg.y - 40
        if (removing) dropIndex = -1
        else if (r.y > -70 && r.x > -slot && r.x < pinnedRow.width + slot)
            dropIndex = dragFrom >= 0 ? Math.max(0, Math.min(n - 1, Math.floor(r.x / slot)))
                                      : Math.max(0, Math.min(n, Math.round(r.x / slot)))
        else dropIndex = dragFrom      // back where it was (or nowhere, for running apps)
    }
    function endDrag() {
        if (removing) DockState.unpin(dragKey)
        else if (dropIndex >= 0 && dragItem?.entry && (dragFrom < 0 || dropIndex !== dragFrom))
            DockState.pin(dragKey, dropIndex)
        dragKey = ""
        dragItem = null
        dragFrom = -1
        dropIndex = -1
        removing = false
        justDragged = true
        Qt.callLater(() => justDragged = false)
    }
    // How far pinned icon j slides to make room while dragging
    function shiftFor(j) {
        if (!dragging || j < 0) return 0
        if (j === dragFrom) return 0
        let pos = j
        if (dragFrom >= 0 && j > dragFrom) pos--
        if (dropIndex >= 0 && pos >= dropIndex) pos++
        return (pos - j) * slot
    }

    Rectangle {
        id: dockBg
        anchors.horizontalCenter: parent.horizontalCenter
        width: row.width + 12
        height: dock.size + 18
        y: dock.revealed ? dock.height - height - 6 : dock.height + 8
        Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        radius: 22
        color: Theme.dockBg
        border.color: Theme.fg(0.16)
        border.width: 1

        HoverHandler { id: dockHover }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 4

            Row {
                id: pinnedRow
                spacing: row.spacing
                Repeater {
                    model: dock.pinnedItems
                    delegate: DockItem {
                        required property var modelData
                        required property int index
                        item: modelData
                        pinnedIndex: index
                        dockWindow: dock
                    }
                }
            }
            Rectangle {
                visible: dock.runningItems.length > 0
                width: 1; height: dock.size - 8
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fg(0.25)
            }
            Repeater {
                model: dock.runningItems
                delegate: DockItem { required property var modelData; item: modelData; pinnedIndex: -1; dockWindow: dock }
            }
            Rectangle {
                width: 1; height: dock.size - 8
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fg(0.25)
            }
            // App launcher (same as ⌘Space)
            Item {
                width: dock.size; height: dock.size
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: 12
                    color: appsMouse.containsMouse ? Theme.fg(0.22) : Theme.fg(0.12)
                    Icon { anchors.centerIn: parent; text: Glyphs.apps; size: Math.round(dock.size / 2) }
                }
                MouseArea {
                    id: appsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Ui.run("$HOME/.config/hypr/scripts/launcher")
                }
            }
        }
    }

    // The icon being dragged follows the cursor
    Item {
        visible: dock.dragging
        x: dock.dragPos.x - dock.size / 2
        y: dock.dragPos.y - dock.size / 2
        width: dock.size
        height: dock.size
        IconImage {
            anchors.fill: parent
            source: Quickshell.iconPath(dock.dragItem?.entry?.icon || dock.dragItem?.appId || "", "application-x-executable")
            opacity: dock.removing ? 0.45 : 1
            scale: dock.removing ? 0.85 : 1.08
            Behavior on scale { NumberAnimation { duration: 120 } }
        }
        Rectangle {
            visible: dock.removing
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: 4
            width: removeLabel.implicitWidth + 16
            height: 22
            radius: 7
            color: Theme.panelSolid
            border.color: Theme.panelBorder
            Label { id: removeLabel; anchors.centerIn: parent; text: "Remove"; font.pixelSize: 11 }
        }
    }
}
