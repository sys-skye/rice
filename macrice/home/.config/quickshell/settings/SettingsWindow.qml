import QtQuick
import Quickshell
import qs.common

// "System Settings" (Apple menu → System Settings…), macOS-style sidebar + pages.
// Add a page: make a *Page.qml in this folder and list it in `pages` below.
FloatingWindow {
    id: root
    title: "System Settings"
    visible: false
    color: Theme.windowBg
    implicitWidth: 860
    implicitHeight: 600
    minimumSize: Qt.size(720, 460)

    readonly property var pages: [
        { id: "wifi",       name: "Wi-Fi",            icon: 0xF0928, color: "#0a84ff", page: "WifiPage.qml" },
        { id: "bluetooth",  name: "Bluetooth",        icon: 0xF00AF, color: "#0a84ff", page: "BluetoothPage.qml" },
        { id: "sound",      name: "Sound",            icon: 0xF057E, color: "#ff375f", page: "SoundPage.qml" },
        { id: "display",    name: "Displays",         icon: 0xF0379, color: "#0a84ff", page: "DisplayPage.qml" },
        { id: "battery",    name: "Battery",          icon: 0xF0079, color: "#30d158", page: "BatteryPage.qml" },
        { id: "trackpad",   name: "Trackpad & Mouse", icon: 0xF037D, color: "#8e8e93", page: "TrackpadPage.qml" },
        { id: "keyboard",   name: "Keyboard",         icon: 0xF030C, color: "#8e8e93", page: "KeyboardPage.qml" },
        { id: "appearance", name: "Appearance",       icon: 0xF03D8, color: "#5e5ce6", page: "AppearancePage.qml" },
        { id: "dock",       name: "Desktop & Dock",   icon: 0xF10A9, color: "#1c1c1e", page: "DockPage.qml" },
    ]
    readonly property var current: pages.find(p => p.id === Ui.settingsPage) ?? pages[5]

    Connections {
        target: Ui
        function onSettingsOpenChanged() { if (root.visible !== Ui.settingsOpen) root.visible = Ui.settingsOpen }
    }
    onVisibleChanged: if (!visible) Ui.settingsOpen = false

    // ── Sidebar ─────────────────────────────────────────────────────
    Rectangle {
        id: sidebar
        width: 220
        height: parent.height
        color: Theme.fg(0.035)
        Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.fg(0.07) }

        Column {
            x: 10; y: 16
            width: parent.width - 20
            spacing: 2
            Repeater {
                model: root.pages
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool selected: root.current.id === modelData.id
                    width: parent.width
                    height: 32
                    radius: 7
                    color: selected ? Theme.accent : mouse.containsMouse ? Theme.fg(0.07) : "transparent"
                    Rectangle {
                        id: badge
                        x: 7
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22; height: 22; radius: 6
                        color: modelData.color
                        Icon { anchors.centerIn: parent; text: String.fromCodePoint(modelData.icon); size: 14; color: "white" }
                    }
                    Label {
                        anchors.left: badge.right
                        anchors.leftMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: parent.selected ? "white" : Theme.text
                    }
                    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: Ui.settingsPage = modelData.id }
                }
            }
        }
    }

    // ── Page ────────────────────────────────────────────────────────
    Label {
        id: heading
        x: sidebar.width + 28
        y: 18
        text: root.current.name
        bold: true
        font.pixelSize: 20
    }
    SmoothFlickable {
        id: flick
        x: sidebar.width + 24
        y: heading.y + heading.height + 18
        width: root.width - x - 24
        height: root.height - y
        contentHeight: loader.height + 24
        Loader {
            id: loader
            width: flick.width
            source: root.current.page
            onSourceChanged: flick.contentY = 0
        }
    }
}
