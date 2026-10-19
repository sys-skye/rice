import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import qs.panels

// The top menu bar. The middle (Theme.notchWidth) is kept empty for the notch.
PanelWindow {
    id: bar
    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "menubar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: Ui.openPanel === "wifi" && Ui.panelOn(screen?.name ?? "", isFocusedScreen) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    readonly property bool isFocusedScreen: Hyprland.focusedMonitor?.name === screen?.name
    readonly property bool hasNotch: screen?.name === "eDP-1"      // external screens have no notch
    readonly property real sideMax: hasNotch ? width / 2 - Theme.notchWidth / 2 - 12 : width - 260

    // Focused app
    readonly property var win: Hyprland.activeToplevel
    // (a focused window in a special Space that's open — ⌘⇧M minimized, ⌘` terminal — is on screen too,
    //  but not one ⌘Q just hid in special:hidden, which Hyprland may still report as active)
    readonly property bool hasWindow: win !== null && win.workspace !== null
        && (win.workspace?.id === Hyprland.focusedWorkspace?.id || SpecialSpaces.isShown(win.workspace?.name ?? ""))
    readonly property string appId: !hasWindow ? "" : (win.wayland?.appId || win.lastIpcObject?.class || "")
    readonly property var entry: appId ? DesktopEntries.heuristicLookup(appId) : null
    readonly property string appName: !hasWindow ? "Desktop"
        : entry ? entry.name : appId.replace(/^.*\./, "").replace(/^./, c => c.toUpperCase())

    // Media / audio / power
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var battery: UPower.displayDevice
    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNet: wifiDev ? wifiDev.networks.values.find(n => n.connected) ?? null : null
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btConnected: Bluetooth.devices.values.some(d => d.connected)

    // Open a dropdown under this bar (not whichever screen Hyprland thinks is focused)
    function toggle(name) { Ui.toggle(name, bar.screen?.name ?? "") }

    PwObjectTracker { objects: [bar.sink] }
    IdleInhibitor { window: bar; enabled: Ui.keepAwake }
    SystemClock { id: clock; precision: Prefs.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes }

    Rectangle { anchors.fill: parent; color: Theme.barBg }

    // ── Left: logo, app name, spaces ─────────────────────────────────
    Row {
        id: left
        x: 8
        height: parent.height
        width: Math.min(implicitWidth, bar.sideMax)
        clip: true

        BarButton {
            id: logoBtn
            padding: 11
            active: Ui.openPanel === "system"
            Icon { anchors.verticalCenter: parent.verticalCenter; text: Glyphs.logo; size: 17 }
            onClicked: bar.toggle("system")
        }
        BarButton {
            id: appBtn
            active: Ui.openPanel === "app"
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: bar.appName
                bold: true
                width: Math.min(implicitWidth, 260)
            }
            onClicked: if (bar.hasWindow) bar.toggle("app")
        }
        Row {
            height: parent.height
            leftPadding: 6
            spacing: 2
            Repeater {
                // Each display has its own Spaces (hypr/scripts/space): show this screen's
                model: [...new Set(Hyprland.workspaces.values
                    .filter(w => w.id > 0 && w.monitor?.name === bar.screen?.name).map(w => w.id))].sort((a, b) => a - b)
                delegate: BarButton {
                    required property int modelData
                    readonly property var ws: Hyprland.workspaces.values.find(w => w.id === modelData) ?? null
                    // the Space this screen is showing
                    readonly property bool current: (Hyprland.monitorFor(bar.screen)?.activeWorkspace?.id ?? -1) === modelData
                    padding: 5
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: current ? 16 : 7
                        height: 7
                        radius: 3.5
                        color: current ? Theme.text : ws && ws.toplevels.values.length > 0 ? Theme.fg(0.6) : Theme.fg(0.28)
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData + " })")
                }
            }
        }
    }

    // ── Right: tray, now playing, stats, status icons, clock ────────
    Row {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: 8
        height: parent.height

        Repeater {
            model: SystemTray.items
            delegate: BarButton {
                id: trayBtn
                required property var modelData
                padding: 6
                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 16
                    source: trayBtn.modelData.icon
                }
                onClicked: trayBtn.modelData.onlyMenu ? openMenu() : trayBtn.modelData.activate()
                onRightClicked: openMenu()
                function openMenu() {
                    if (!modelData.hasMenu) return
                    const p = trayBtn.mapToItem(bar.contentItem, 0, bar.height)
                    modelData.display(bar, p.x, p.y)
                }
            }
        }

        BarButton {
            id: mediaBtn
            visible: bar.player !== null
            active: Ui.openPanel === "media"
            readonly property bool compact: statusRow.width + right.trayWidth + 190 > bar.sideMax
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Icon { anchors.verticalCenter: parent.verticalCenter; text: Glyphs.music; size: 14 }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !mediaBtn.compact
                    width: Math.min(implicitWidth, 150)
                    text: bar.player ? [bar.player.trackTitle, bar.player.trackArtist].filter(s => s).join(" · ") : ""
                }
            }
            onClicked: bar.toggle("media")
        }

        readonly property real trayWidth: SystemTray.items.values.length * 28

        Row {
            id: statusRow
            height: parent.height

            BarButton {
                visible: SleepTimer.active
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Icon { anchors.verticalCenter: parent.verticalCenter; text: Glyphs.night; size: 14; color: Theme.orange }
                    Label { anchors.verticalCenter: parent.verticalCenter; text: SleepTimer.minutesLeft + "m"; font.pixelSize: 12 }
                }
                onClicked: bar.toggle("control")
            }
            BarButton {
                id: statsBtn
                active: Ui.openPanel === "stats"
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Icon { anchors.verticalCenter: parent.verticalCenter; text: Glyphs.cpu; size: 14 }
                    Label { anchors.verticalCenter: parent.verticalCenter; text: Math.round(Stats.cpu * 100) + "%"; font.pixelSize: 12; width: 28 }
                    Icon { anchors.verticalCenter: parent.verticalCenter; text: Glyphs.memory; size: 14 }
                    Label { anchors.verticalCenter: parent.verticalCenter; text: Math.round(Stats.mem * 100) + "%"; font.pixelSize: 12; width: 28 }
                }
                onClicked: bar.toggle("stats")
            }
            BarButton {
                id: airdropBtn
                visible: AirDrop.receiving || AirDrop.sending
                active: Ui.openPanel === "airdrop"
                AirDropIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 17
                    color: AirDrop.sending ? Theme.accent : Theme.text
                }
                onClicked: bar.toggle("airdrop")
                onRightClicked: AirDrop.toggle()
            }
            BarButton {
                id: btBtn
                active: Ui.openPanel === "bluetooth"
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: !bar.btAdapter?.enabled ? Glyphs.bluetoothOff : bar.btConnected ? Glyphs.bluetoothConnected : Glyphs.bluetooth
                }
                onClicked: bar.toggle("bluetooth")
            }
            BarButton {
                id: wifiBtn
                active: Ui.openPanel === "wifi"
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: !Networking.wifiEnabled || !bar.wifiNet ? Glyphs.wifiOff
                        : Glyphs.wifiIcon(bar.wifiNet.signalStrength > 1 ? bar.wifiNet.signalStrength / 100 : bar.wifiNet.signalStrength)
                    opacity: Networking.wifiEnabled ? 1 : 0.5
                }
                onClicked: bar.toggle("wifi")
            }
            BarButton {
                id: soundBtn
                active: Ui.openPanel === "sound"
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Glyphs.volumeIcon(bar.sink?.audio?.volume ?? 0, bar.sink?.audio?.muted ?? false)
                }
                onClicked: bar.toggle("sound")
                onRightClicked: if (bar.sink?.audio) bar.sink.audio.muted = !bar.sink.audio.muted
                WheelHandler {
                    onWheel: e => {
                        const a = bar.sink?.audio
                        if (a) a.volume = Math.max(0, Math.min(1, a.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05)))
                    }
                }
            }
            BarButton {
                id: batteryBtn
                visible: bar.battery?.isLaptopBattery ?? false
                active: Ui.openPanel === "battery"
                readonly property real pct: bar.battery?.percentage ?? 0
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Label { anchors.verticalCenter: parent.verticalCenter; text: Math.round(batteryBtn.pct * 100) + "%"; font.pixelSize: 12 }
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 18
                        // bolt = charging, plug = plugged in but holding at the charge limit
                        text: UPower.onBattery ? Glyphs.batteryIcon(batteryBtn.pct)
                            : bar.battery?.state === UPowerDeviceState.Charging ? Glyphs.batteryCharging : Glyphs.plug
                        color: UPower.onBattery && batteryBtn.pct <= 0.1 ? Theme.red
                             : PowerProfiles.profile === PowerProfile.PowerSaver ? Theme.yellow
                             : UPower.onBattery && batteryBtn.pct <= 0.2 ? Theme.orange : Theme.text
                    }
                }
                onClicked: bar.toggle("battery")
            }
            BarButton {
                id: ccBtn
                active: Ui.openPanel === "control"
                Icon { anchors.verticalCenter: parent.verticalCenter; text: Glyphs.controlCenter }
                onClicked: bar.toggle("control")
            }
            BarButton {
                id: clockBtn
                active: Ui.openPanel === "calendar"
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, Prefs.clockFormat)
                    font.weight: Font.Medium
                }
                onClicked: bar.toggle("calendar")
            }
        }
    }

    // ── Dropdowns ────────────────────────────────────────────────────
    Backdrop {
        screen: bar.screen
        active: Ui.openPanel !== "" && Ui.openPanel !== "keybinds" && Ui.panelOn(bar.screen?.name ?? "", bar.isFocusedScreen)
        onDismissed: Ui.openPanel = ""
    }
    SystemMenu { anchorItem: logoBtn; enabledHere: bar.isFocusedScreen; ownerWindow: bar }
    AppMenu {
        anchorItem: appBtn
        enabledHere: bar.isFocusedScreen; ownerWindow: bar
        window: bar.win
        entry: bar.entry
        appName: bar.appName
    }
    MediaPanel { anchorItem: mediaBtn; enabledHere: bar.isFocusedScreen; ownerWindow: bar; player: bar.player ?? Mpris.players.values[0] ?? null }
    StatsPanel { anchorItem: statsBtn; enabledHere: bar.isFocusedScreen; ownerWindow: bar }
    // Opened from the bar icon (while on) or from the Control Center tile
    AirDropPanel { anchorItem: airdropBtn.visible ? airdropBtn : ccBtn; enabledHere: bar.isFocusedScreen; ownerWindow: bar }
    BluetoothPanel { anchorItem: btBtn; enabledHere: bar.isFocusedScreen; ownerWindow: bar }
    WifiPanel { anchorItem: wifiBtn; enabledHere: bar.isFocusedScreen; ownerWindow: bar }
    SoundPanel { anchorItem: soundBtn; enabledHere: bar.isFocusedScreen; ownerWindow: bar }
    BatteryPanel { anchorItem: batteryBtn; enabledHere: bar.isFocusedScreen; ownerWindow: bar }
    ControlCenter { anchorItem: ccBtn; enabledHere: bar.isFocusedScreen; ownerWindow: bar }
    CalendarPanel { anchorItem: clockBtn; enabledHere: bar.isFocusedScreen; ownerWindow: bar }
}
