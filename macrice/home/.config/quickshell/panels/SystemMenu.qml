import QtQuick
import Quickshell
import qs.common

// The "Apple menu" behind the Fedora logo
Panel {
    id: root
    name: "system"
    panelWidth: 240
    alignRight: false
    padding: 5
    spacing: 0

    property string confirm: ""
    onVisibleChanged: confirm = ""

    function act(cmd) { Ui.openPanel = ""; Ui.run(cmd) }
    // Dangerous items need a second click
    function confirmThen(id, cmd) { if (confirm === id) act(cmd); else confirm = id }

    MenuItem { text: "About This Computer"; onClicked: { Ui.openPanel = ""; Ui.launch(Settings.terminal + " --class about-this-computer -o window_padding_width=14 -o font_size=10 " + Settings.scripts + "/about") } }
    MenuSeparator {}
    MenuItem { text: "System Settings…"; onClicked: Ui.openSettings("") }
    MenuItem { text: "Keyboard Shortcuts"; shortcut: "⌘ /"; onClicked: Ui.openPanel = "keybinds" }
    MenuSeparator {}
    MenuItem { text: "Force Quit…"; shortcut: "click a window"; onClicked: root.act("hyprctl kill") }
    MenuSeparator {}
    MenuItem { text: "Sleep"; onClicked: root.act("systemctl suspend") }
    MenuItem {
        text: root.confirm === "reboot" ? "Click again to restart" : "Restart…"
        destructive: root.confirm === "reboot"
        onClicked: root.confirmThen("reboot", "systemctl reboot")
    }
    MenuItem {
        text: root.confirm === "off" ? "Click again to shut down" : "Shut Down…"
        destructive: root.confirm === "off"
        onClicked: root.confirmThen("off", "systemctl poweroff")
    }
    MenuSeparator {}
    MenuItem { text: "Lock Screen"; shortcut: "⌃⌘Q"; onClicked: root.act("loginctl lock-session") }
    MenuItem {
        text: root.confirm === "logout" ? "Click again to log out" : "Log Out…"
        destructive: root.confirm === "logout"
        onClicked: root.confirmThen("logout", "uwsm stop")
    }
}
