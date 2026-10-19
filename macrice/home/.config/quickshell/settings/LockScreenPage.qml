import QtQuick
import qs.common

Column {
    width: parent ? parent.width : 500

    Group {
        title: "Lock Screen"
        footer: "The screen dims 30 seconds before it turns off. Playing video keeps it on. "
              + "Sleeping when idle is set in Battery → Energy Saver."
        SettingRow {
            label: "Turn display off after"
            Segmented {
                options: [1, 2, 5, 10, 20, 0].map(m => ({ label: m ? m + " min" : "Never", value: m }))
                value: Prefs.displayOffAfter
                onPicked: v => Prefs.set("displayOffAfter", v)
            }
        }
        SettingRow {
            label: "Require password"
            hint: Prefs.displayOffAfter === 0 ? "The display never turns off on its own" : "After the display turns off"
            last: true
            Segmented {
                options: [{ label: "Immediately", value: 0 }, { label: "1 min", value: 1 }, { label: "5 min", value: 5 }, { label: "Never", value: -1 }]
                value: Prefs.lockDelay
                onPicked: v => Prefs.set("lockDelay", v)
            }
        }
    }

    Group {
        title: "Sleep"
        footer: "The Mac always locks before it goes to sleep."
        SettingRow {
            label: "Lock Screen now"
            hint: "Also ⌃⌘Q"
            LinkButton { text: "Lock"; onClicked: { Ui.settingsOpen = false; Ui.run("loginctl lock-session") } }
        }
        SettingRow {
            label: "Keep awake"
            hint: "Never dim, lock or sleep while this is on"
            last: true
            Toggle { checked: Ui.keepAwake; onToggled: v => Ui.keepAwake = v }
        }
    }
}
