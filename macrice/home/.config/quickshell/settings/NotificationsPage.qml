import QtQuick
import qs.common

Column {
    width: parent ? parent.width : 500

    Group {
        title: "Notifications"
        footer: "Do Not Disturb hides banners but still lets urgent ones (like low battery) through."
        SettingRow {
            label: "Do Not Disturb"
            hint: "Also in Control Center"
            Toggle { checked: Ui.dnd; onToggled: v => Ui.setDnd(v) }
        }
        SettingRow {
            label: "Banner position"
            Segmented {
                options: [{ label: "Top right", value: "top-right" }, { label: "Top centre", value: "top-center" }]
                value: Prefs.bannerPosition
                onPicked: v => Prefs.set("bannerPosition", v)
            }
        }
        SettingRow {
            label: "Banners stay for"
            last: true
            Segmented {
                options: [3, 5, 10, 0].map(s => ({ label: s ? s + " s" : "Until dismissed", value: s }))
                value: Prefs.bannerSeconds
                onPicked: v => Prefs.set("bannerSeconds", v)
            }
        }
    }

    Group {
        title: "Test"
        SettingRow {
            label: "Show a test notification"
            last: true
            LinkButton { text: "Send"; onClicked: Ui.run("notify-send -a 'System Settings' -i preferences-system-notifications 'Hello!' 'This is how notifications look.'") }
        }
    }

    Group {
        title: "History"
        SettingRow {
            label: "Dismiss all notifications"
            LinkButton { text: "Clear"; onClicked: Ui.run("makoctl dismiss -a") }
        }
        SettingRow {
            label: "Bring back the last one"
            last: true
            LinkButton { text: "Restore"; onClicked: Ui.run("makoctl restore") }
        }
    }
}
