import QtQuick
import Quickshell
import Quickshell.Wayland

// A dropdown that hangs off the menu bar, like macOS menu bar extras.
// It's its own layer surface under the bar; the bar's Backdrop catches outside clicks.
// Opened/closed through Ui.openPanel. Esc closes it once you have clicked into it.
// (Keyboard focus must stay OnDemand: an Exclusive layer makes Hyprland send ALL
// clicks to it, so the Backdrop would never see outside clicks.)
PanelWindow {
    id: root
    required property string name
    required property Item anchorItem
    property int panelWidth: 300
    property bool alignRight: true
    default property alias content: column.data
    property alias spacing: column.spacing
    property int padding: 12
    property bool enabledHere: true   // false on bars of other monitors
    property var ownerWindow: null     // the menu bar this panel belongs to

    signal opened()

    screen: ownerWindow ? ownerWindow.screen : null
    visible: false
    color: "transparent"
    anchors { top: true; left: true }
    exclusionMode: ExclusionMode.Normal   // sits just below the menu bar
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "dropdown"
    // Appear without keyboard focus and allow it a moment later: Hyprland gives a layer that
    // maps with focus enabled the *pointer* focus too, so clicking its bar icon again without
    // moving the mouse went to this panel (outside it, so nowhere) instead of closing it.
    property bool focusable: false
    WlrLayershell.keyboardFocus: visible && focusable ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    Timer { id: focusDelay; interval: 150; onTriggered: root.focusable = root.visible }

    implicitWidth: panelWidth
    implicitHeight: column.implicitHeight + padding * 2 + 6

    // Line the panel up under its bar icon, staying on screen
    function place() {
        if (!anchorItem || !ownerWindow) return
        const p = anchorItem.mapToItem(null, 0, 0)
        const x = alignRight ? p.x + anchorItem.width - panelWidth : p.x
        margins.left = Math.max(8, Math.min(x, ownerWindow.width - panelWidth - 8))
    }

    // Re-evaluated whenever the open panel, its screen or the focused screen changes
    readonly property bool wanted: Ui.openPanel === name && Ui.panelOn(ownerWindow?.screen?.name ?? "", enabledHere)
    onWantedChanged: {
        if (wanted === visible) return
        if (wanted) place()
        visible = wanted
    }
    onVisibleChanged: {
        focusable = false
        if (visible) focusDelay.restart()
        if (visible) { bg.opacity = 0; bg.scale = 0.97; showAnim.restart(); keys.forceActiveFocus(); opened() }
        else if (wanted) Ui.closed(name)   // hidden by something other than Ui (e.g. the compositor)
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Ui.openPanel = ""
    }

    Rectangle {
        id: bg
        y: 6
        width: root.panelWidth
        height: column.implicitHeight + root.padding * 2
        radius: Theme.panelRadius
        color: Theme.panelBg
        border.color: Theme.panelBorder
        border.width: 1
        transformOrigin: root.alignRight ? Item.TopRight : Item.TopLeft

        ParallelAnimation {
            id: showAnim
            NumberAnimation { target: bg; property: "opacity"; to: 1; duration: 140; easing.type: Easing.OutCubic }
            NumberAnimation { target: bg; property: "scale"; to: 1; duration: 180; easing.type: Easing.OutCubic }
        }

        Column {
            id: column
            x: root.padding
            y: root.padding
            width: parent.width - root.padding * 2
            spacing: 4
        }
    }
}
