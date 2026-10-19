import QtQuick
import Quickshell
import qs.common

Panel {
    id: root
    name: "calendar"
    panelWidth: 260

    property date shown: new Date()
    onOpened: shown = new Date()

    readonly property var days: {
        const first = new Date(shown.getFullYear(), shown.getMonth(), 1)
        const offset = (first.getDay() + 6) % 7          // weeks start on Monday
        const out = []
        for (let i = 0; i < 42; i++) out.push(new Date(first.getFullYear(), first.getMonth(), 1 - offset + i))
        return out
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Label {
        x: 4
        text: Qt.formatDateTime(clock.date, "dddd d MMMM yyyy")
        bold: true
        font.pixelSize: 14
        height: 26
    }
    MenuSeparator {}
    Item {
        width: parent.width
        height: 26
        Label { x: 4; anchors.verticalCenter: parent.verticalCenter; text: Qt.formatDate(root.shown, "MMMM yyyy"); bold: true }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Repeater {
                model: [{ t: "‹", d: -1 }, { t: "•", d: 0 }, { t: "›", d: 1 }]
                delegate: BarButton {
                    required property var modelData
                    implicitHeight: 24
                    padding: 6
                    vInset: 0
                    Label { anchors.verticalCenter: parent.verticalCenter; text: modelData.t; font.pixelSize: 15 }
                    onClicked: root.shown = modelData.d === 0 ? new Date()
                        : new Date(root.shown.getFullYear(), root.shown.getMonth() + modelData.d, 1)
                }
            }
        }
    }
    Grid {
        columns: 7
        width: parent.width
        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            delegate: Label {
                required property string modelData
                width: parent.width / 7; height: 22
                horizontalAlignment: Text.AlignHCenter
                text: modelData; dim: true; font.pixelSize: Theme.smallFontSize
            }
        }
        Repeater {
            model: root.days
            delegate: Item {
                required property var modelData
                readonly property bool today: modelData.toDateString() === clock.date.toDateString()
                width: parent.width / 7
                height: 30
                Rectangle {
                    anchors.centerIn: parent
                    width: 26; height: 26; radius: 13
                    color: parent.today ? Theme.red : "transparent"
                }
                Label {
                    anchors.centerIn: parent
                    text: modelData.getDate()
                    bold: parent.today
                    opacity: modelData.getMonth() === root.shown.getMonth() ? 1 : 0.3
                }
            }
        }
    }
}
