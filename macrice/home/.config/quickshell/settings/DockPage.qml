import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.common

Column {
    id: page
    width: parent ? parent.width : 500

    property bool adding: false
    property string query: ""
    readonly property var apps: DesktopEntries.applications.values
        .filter(e => !e.noDisplay && !DockState.isPinned(e.id))
        .filter(e => !query || (e.name + " " + e.genericName + " " + e.keywords).toLowerCase().includes(query.toLowerCase()))
        .sort((a, b) => a.name.localeCompare(b.name))

    Group {
        title: "Dock"
        SettingRow {
            label: "Size"
            SettingSlider {
                from: 32; to: 72; stepSize: 2; ticks: 6
                minLabel: "Small"; maxLabel: "Large"
                value: DockState.iconSize
                onMoved: v => DockState.set("iconSize", Math.round(v))
            }
        }
        SettingRow {
            label: "Automatically hide and show the Dock"
            hint: DockState.autoHide ? "Move the pointer to the bottom edge to show it" : "Windows make room for the Dock"
            Toggle { checked: DockState.autoHide; onToggled: v => DockState.set("autoHide", v) }
        }
        SettingRow {
            label: "Show the Dock on empty Spaces"
            last: true
            Toggle { checked: DockState.showOnEmptySpace; onToggled: v => DockState.set("showOnEmptySpace", v) }
        }
    }

    Group {
        title: "Windows"
        footer: "Spacing for tiled windows. Changes apply instantly."
        SettingRow {
            label: "Gap between windows"
            hint: (InputSettings.gapsIn * 2) + " px"
            SettingSlider {
                from: 0; to: 20; stepSize: 1; ticks: 11
                minLabel: "None"; maxLabel: "Wide"
                value: InputSettings.gapsIn
                onMoved: v => InputSettings.set("gapsIn", Math.round(v))
            }
        }
        SettingRow {
            label: "Gap at screen edges"
            hint: InputSettings.gapsOut + " px"
            SettingSlider {
                from: 0; to: 40; stepSize: 1; ticks: 9
                minLabel: "None"; maxLabel: "Wide"
                value: InputSettings.gapsOut
                onMoved: v => InputSettings.set("gapsOut", Math.round(v))
            }
        }
        SettingRow {
            label: "Rounded corners"
            hint: InputSettings.rounding + " px"
            last: true
            SettingSlider {
                from: 0; to: 24; stepSize: 1; ticks: 7
                minLabel: "Square"; maxLabel: "Round"
                value: InputSettings.rounding
                onMoved: v => InputSettings.set("rounding", Math.round(v))
            }
        }
    }

    Group {
        title: "Apps in the Dock"
        footer: "Tip: drag icons in the Dock to rearrange them, drag a running app into the pinned area to keep it, "
              + "or drag an icon up out of the Dock to remove it."
        Repeater {
            model: DockState.pinned
            delegate: SettingRow {
                required property string modelData
                required property int index
                readonly property var entry: DesktopEntries.byId(modelData)
                label: entry ? entry.name : modelData
                last: index === DockState.pinned.length - 1 && !page.adding
                Row {
                    spacing: 4
                    LinkButton { text: "↑"; visible: index > 0; onClicked: DockState.move(modelData, index - 1) }
                    LinkButton { text: "↓"; visible: index < DockState.pinned.length - 1; onClicked: DockState.move(modelData, index + 1) }
                    LinkButton { text: "Remove"; onClicked: DockState.unpin(modelData) }
                }
            }
        }
        SettingRow {
            label: page.adding ? "Add an app" : ""
            last: !page.adding
            Row {
                spacing: 6
                Rectangle {
                    visible: page.adding
                    width: 200; height: 26; radius: 6
                    color: Theme.fg(0.08)
                    border.color: search.activeFocus ? Theme.accent : Theme.panelBorder
                    TextInput {
                        id: search
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        clip: true
                        onTextChanged: page.query = text
                        Label { anchors.verticalCenter: parent.verticalCenter; text: "Search apps"; dim: true; visible: !search.text }
                    }
                }
                LinkButton {
                    text: page.adding ? "Done" : "Add App…"
                    primary: !page.adding
                    onClicked: { page.adding = !page.adding; search.text = ""; if (page.adding) search.forceActiveFocus() }
                }
            }
        }
        Repeater {
            model: page.adding ? page.apps.slice(0, 40) : []
            delegate: SettingRow {
                required property var modelData
                required property int index
                label: modelData.name
                hint: modelData.genericName || ""
                last: index === Math.min(page.apps.length, 40) - 1
                Row {
                    spacing: 8
                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 22
                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                    }
                    LinkButton { text: "Add"; onClicked: DockState.pin(modelData.id) }
                }
            }
        }
    }

    Group {
        SettingRow {
            label: "Reset the Dock to its default apps and settings"
            last: true
            LinkButton { text: "Reset…"; onClicked: DockState.reset() }
        }
    }
}
