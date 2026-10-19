pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Which special Space (⌘⇧M minimized windows, ⌘` terminal…) is open on each screen.
// Hyprland doesn't tell Quickshell this directly, so follow its activespecial events.
Singleton {
    id: root

    property var shown: ({})    // screen name → "special:name" (missing = none open)

    function on(screenName) { return shown[screenName] ?? "" }
    // Is this special Space open on any screen? (a window in special:hidden never is)
    function isShown(name) { return Object.values(shown).includes(name) }

    function set(screenName, name) {
        const s = Object.assign({}, shown)
        if (name) s[screenName] = name
        else delete s[screenName]
        shown = s
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activespecial") return
            const [name, mon] = event.data.split(",")
            root.set(mon, name)
        }
    }
    Process {   // what's already open when the shell starts
        running: true
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    for (const m of JSON.parse(text)) root.set(m.name, m.specialWorkspace?.name ?? "")
                } catch (e) {}
            }
        }
    }
}
