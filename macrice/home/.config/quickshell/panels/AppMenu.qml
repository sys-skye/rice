import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.common

// Menu behind the bold app name: the app's own actions (from its .desktop file)
// plus window commands. Real File/Edit/View menus aren't available on Hyprland.
Panel {
    id: root
    name: "app"
    panelWidth: 250
    alignRight: false
    padding: 5
    spacing: 0

    required property var window      // HyprlandToplevel
    required property var entry       // DesktopEntry or null
    required property string appName

    readonly property var ipc: window?.lastIpcObject ?? ({})
    // Lua selector for this window (Hyprland.dispatch takes Lua: hl.dsp.window.close({ window = … }))
    readonly property string addr: ipc.address ? "window = 'address:" + ipc.address + "'" : ""
    readonly property bool floating: ipc.floating ?? false
    readonly property string appClass: ipc.class ?? ""

    function dispatch(cmd) { Ui.openPanel = ""; Hyprland.dispatch(cmd) }
    onOpened: Hyprland.refreshToplevels()

    MenuItem {
        text: "New Window"
        shortcut: "⌘N"
        visible: root.entry !== null
        onClicked: { Ui.openPanel = ""; Ui.launch(root.entry.id + ".desktop") }
    }
    Repeater {
        model: root.entry ? root.entry.actions : []
        delegate: MenuItem {
            required property var modelData
            text: modelData.name
            visible: !/^new.window$/i.test(modelData.name)
            onClicked: { Ui.openPanel = ""; modelData.execute() }
        }
    }
    MenuSeparator { visible: root.entry !== null }

    MenuItem { text: root.floating ? "Tile Window" : "Float Window"; shortcut: "⌥⌘F"; onClicked: root.dispatch("hl.dsp.window.float({ action = 'toggle', " + root.addr + " })") }
    MenuItem { text: "Enter Full Screen"; shortcut: "⌃⌘F"; onClicked: root.dispatch("hl.dsp.window.fullscreen({ mode = 'fullscreen' })") }
    MenuItem { text: "Minimize"; shortcut: "⌘M"; onClicked: { Ui.openPanel = ""; Ui.run(Settings.scripts + "/minimize") } }
    MenuItem { text: "Pin to All Spaces"; visible: root.floating; checked: root.ipc.pinned ?? false; onClicked: root.dispatch("hl.dsp.window.pin({ " + root.addr + " })") }

    Item {
        width: parent.width
        height: 30
        Label { x: 10; anchors.verticalCenter: parent.verticalCenter; text: "Move to Space" }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Repeater {
                model: 5
                delegate: BarButton {
                    required property int index
                    implicitHeight: 24
                    padding: 6
                    vInset: 0
                    // Spaces of the window's own display (hypr/scripts/space)
                    active: Hyprland.workspaces.values
                        .filter(w => w.id > 0 && w.monitor?.id === root.ipc.monitor).map(w => w.id)
                        .sort((a, b) => a - b).indexOf(root.ipc.workspace?.id) === index
                    Label { anchors.verticalCenter: parent.verticalCenter; text: index + 1 }
                    onClicked: { Ui.openPanel = ""; Ui.run(Settings.scripts + "/space send " + (index + 1) + " " + root.ipc.address) }
                }
            }
        }
    }

    MenuItem { text: "Move to New Space"; shortcut: "⌥⌘0"; onClicked: { Ui.openPanel = ""; Ui.run(Settings.scripts + "/space move new " + root.ipc.address) } }

    // Move to another screen (only when more than one is connected)
    Item {
        visible: Hyprland.monitors.values.length > 1
        width: parent.width
        height: visible ? 30 : 0
        Label { x: 10; anchors.verticalCenter: parent.verticalCenter; text: "Move to Display" }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Repeater {
                model: Hyprland.monitors.values
                delegate: BarButton {
                    required property var modelData
                    implicitHeight: 24
                    padding: 6
                    vInset: 0
                    active: root.ipc.monitor === modelData.id
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name === "eDP-1" ? "MacBook" : (modelData.lastIpcObject?.model || modelData.name).replace(/^DELL /, "Dell ")
                        font.pixelSize: 12
                    }
                    onClicked: root.dispatch("hl.dsp.window.move({ monitor = '" + modelData.name + "', " + root.addr + " })")
                }
            }
        }
    }

    MenuSeparator {}
    MenuItem { text: "Close Window"; shortcut: "⌘Q"; onClicked: root.dispatch("hl.dsp.window.close({ " + root.addr + " })") }
    MenuItem {
        text: "Quit " + root.appName
        destructive: true
        visible: root.appClass !== ""
        // Close every window of this app, like ⌘Q on macOS
        onClicked: {
            Ui.openPanel = ""
            Ui.run("hyprctl clients -j | jq -r --arg c '" + root.appClass.replace(/'/g, "") + "' '.[] | select(.class == $c) | .address'"
                      + " | while read -r a; do hyprctl dispatch \"hl.dsp.window.close({ window = 'address:$a' })\"; done")
        }
    }
}
