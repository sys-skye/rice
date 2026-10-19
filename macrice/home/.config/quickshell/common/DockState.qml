pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The dock's pinned apps and options, saved in the shell's state folder.
// Edit by dragging in the dock, right-clicking an icon, or System Settings → Desktop & Dock.
Singleton {
    id: root

    property var pinned: Settings.pinnedApps.slice()   // desktop-file ids, in dock order
    property int iconSize: Settings.dockIconSize
    property bool autoHide: true
    property bool showOnEmptySpace: Settings.dockShowOnEmptySpace
    property bool loaded: false

    function isPinned(id) { return pinned.indexOf(id) >= 0 }
    function pin(id, index) {
        if (!id) return
        const p = pinned.filter(x => x !== id)
        p.splice(index === undefined || index < 0 ? p.length : Math.min(index, p.length), 0, id)
        pinned = p
        save()
    }
    function unpin(id) { pinned = pinned.filter(x => x !== id); save() }
    function move(id, index) { pin(id, index) }
    function set(prop, value) { root[prop] = value; save() }
    function reset() {
        pinned = Settings.pinnedApps.slice()
        iconSize = Settings.dockIconSize
        autoHide = true
        showOnEmptySpace = Settings.dockShowOnEmptySpace
        save()
    }

    readonly property string file: Quickshell.statePath("dock.json")
    function save() { saveTimer.restart() }
    Timer {
        id: saveTimer
        interval: 300
        onTriggered: {
            saver.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "sh", root.file,
                             JSON.stringify({ pinned: root.pinned, iconSize: root.iconSize, autoHide: root.autoHide,
                                              showOnEmptySpace: root.showOnEmptySpace })]
            saver.running = true
        }
    }
    Process { id: saver }
    Process {
        running: true
        command: ["sh", "-c", "cat '" + root.file + "' 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = JSON.parse(text)
                    if (Array.isArray(s.pinned)) root.pinned = s.pinned
                    if (s.iconSize) root.iconSize = s.iconSize
                    if (s.autoHide !== undefined) root.autoHide = s.autoHide
                    if (s.showOnEmptySpace !== undefined) root.showOnEmptySpace = s.showOnEmptySpace
                } catch (e) {}
                root.loaded = true
            }
        }
    }
}
