//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
// macOS-style shell: menu bar + dropdowns + dock.  Docs: https://quickshell.org
// Reload happens automatically when you save a file. Logs: qs log
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.bar
import qs.dock
import qs.common
import qs.panels
import qs.settings
import qs.effects

ShellRoot {
    // Keep Hyprland's cursor in sync with the GTK/GNOME cursor setting
    Component.onCompleted: CursorSync.start()
    // Sleep-when-idle and other battery savers (Settings → Battery)
    readonly property bool powerSettingsLoaded: PowerSettings.loaded

    Variants {
        model: Quickshell.screens
        MenuBar {}
    }

    Dock {}

    // Drop-down terminal (⌘`) that pops out of the notch
    NotchDropdown { id: notchDropdown }

    // Volume / brightness indicator that pops out of the notch
    NotchOSD { id: notchOsd }
    Keybinds {}
    SettingsWindow {}
    CursorTrail {}
    Overview {}

    // From a terminal or a Hyprland bind:  qs ipc call panel toggle control
    // Names: system app wifi bluetooth sound battery control calendar stats media
    IpcHandler {
        target: "panel"
        function toggle(name: string): void { Ui.toggle(name) }
        function close(): void { Ui.openPanel = "" }
    }
    // qs ipc call overview toggle   (bound to a three-finger swipe up)
    IpcHandler {
        target: "overview"
        function toggle(): void { Ui.overviewOpen = !Ui.overviewOpen }
        function close(): void { Ui.overviewOpen = false }
        // Swipe down: jump to the window under the cursor (or just close)
        function commit(): void { if (Ui.overviewOpen) Ui.overviewCommit++ }
    }
    // qs ipc call appearance set light|dark|auto   ·   qs ipc call appearance toggle
    IpcHandler {
        target: "appearance"
        function set(mode: string): void { Appearance.setMode(mode) }
        function toggle(): void { Appearance.toggle() }
    }
    // qs ipc call osd pop volume 40   (kinds: volume muted brightness keyboard mic micmuted)
    IpcHandler {
        target: "osd"
        function pop(kind: string, value: int): void { notchOsd.show(kind, value) }
    }
    // qs ipc call dropdown toggle|open|close   (⌘` runs scripts/dropdown-term)
    // ("show" is a word of the qs command itself, so it can't be a function name here)
    IpcHandler {
        target: "dropdown"
        function toggle(): void { notchDropdown.toggle() }
        function open(): void { notchDropdown.show() }
        function close(): void { notchDropdown.hide() }
    }
    // qs ipc call settings open trackpad   (general wifi bluetooth notifications sound display battery lock trackpad keyboard appearance dock)
    IpcHandler {
        target: "settings"
        function open(page: string): void { Ui.openSettings(page) }
    }
}
