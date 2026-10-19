import QtQuick
import qs.common

Column {
    width: parent ? parent.width : 500
    readonly property var accentNames: ({ "#0a84ff": "Blue", "#bf5af2": "Purple", "#ff375f": "Pink", "#ff453a": "Red",
                                          "#ff9f0a": "Orange", "#ffcc00": "Yellow", "#30d158": "Green", "#8e8e93": "Graphite" })

    // Little window preview, like the macOS Appearance picker
    component ModeCard: Column {
        id: card
        property string mode
        property string label
        readonly property bool selected: Appearance.mode === mode
        spacing: 8
        width: 132

        Rectangle {
            width: parent.width
            height: 84
            radius: 10
            border.width: card.selected ? 3 : 1
            border.color: card.selected ? Theme.accent : Theme.panelBorder
            clip: true
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: card.mode === "light" ? "#dfe9fb" : card.mode === "dark" ? "#1b2140" : "#dfe9fb" }
                GradientStop { position: 0.5; color: card.mode === "auto" ? "#7b6fd6" : card.mode === "light" ? "#f4dbe8" : "#3a1f55" }
                GradientStop { position: 1; color: card.mode === "light" ? "#f7e9f1" : "#1b2140" }
            }
            // menu bar + window
            Rectangle {
                x: 0; y: 0; width: parent.width; height: 9
                color: card.mode === "light" ? Qt.rgba(1, 1, 1, 0.7) : Qt.rgba(0, 0, 0, 0.45)
            }
            Rectangle {
                x: 18; y: 20; width: 78; height: 50; radius: 5
                color: card.mode === "light" ? "#f5f5f7" : card.mode === "dark" ? "#26262b" : "transparent"
                gradient: card.mode === "auto" ? autoGrad : null
                border.color: Qt.rgba(0, 0, 0, 0.15)
                Gradient {
                    id: autoGrad
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.49; color: "#f5f5f7" }
                    GradientStop { position: 0.51; color: "#26262b" }
                }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Appearance.setMode(card.mode) }
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.label
            bold: card.selected
        }
    }

    Group {
        title: "Appearance"
        footer: "Switches the menu bar, dock, menus, apps (GTK, Firefox), the terminal and the wallpaper together."
        Item {
            width: parent.width
            height: cards.height + 28
            Row {
                id: cards
                anchors.centerIn: parent
                spacing: 22
                ModeCard { mode: "light"; label: "Light" }
                ModeCard { mode: "dark"; label: "Dark" }
                ModeCard { mode: "auto"; label: "Auto" }
            }
        }
    }

    Group {
        title: "Accent colour"
        footer: "Used for buttons, switches, sliders and selections in the menu bar, Control Center and System Settings."
        SettingRow {
            label: "Accent colour"
            hint: accentNames[Prefs.accent] ?? Prefs.accent
            last: true
            ColorSwatches {
                colors: Object.keys(accentNames)
                value: Prefs.accent
                onPicked: v => Prefs.set("accent", v)
            }
        }
    }

    Group {
        title: "Auto"
        visible: Appearance.mode === "auto"
        footer: "Right now: " + (Theme.isDark ? "dark" : "light") + "."
        SettingRow {
            label: "Light from"
            HourStepper { hour: Appearance.lightFrom; onChanged: h => Appearance.setTimes(h, Appearance.darkFrom) }
        }
        SettingRow {
            label: "Dark from"
            last: true
            HourStepper { hour: Appearance.darkFrom; onChanged: h => Appearance.setTimes(Appearance.lightFrom, h) }
        }
    }

    Group {
        title: "More"
        SettingRow {
            label: "App theme, icons and fonts"
            hint: "Fine-tune GTK apps such as Files and Calculator"
            last: true
            LinkButton { text: "Open…"; onClicked: Ui.launch("nwg-look") }
        }
    }
}
