pragma Singleton
import QtQuick
import Quickshell

// Things you'll probably want to change.
Singleton {
    // Dock: desktop-file ids (filename in /usr/share/applications without .desktop)
    readonly property var pinnedApps: [
        "org.gnome.Nautilus",
        "org.mozilla.firefox",
        "kitty",
        "org.kde.kwrite",
        "org.gnome.Calculator",
    ]
    readonly property int dockIconSize: 48
    readonly property int dockHideDelay: 450      // ms after the cursor leaves
    readonly property bool dockShowOnEmptySpace: true

    readonly property string terminal: "kitty"
    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts"
    readonly property string backlight: "apple-panel-bl"
}
