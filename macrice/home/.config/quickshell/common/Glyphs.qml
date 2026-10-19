pragma Singleton
import QtQuick
import Quickshell

// Nerd Font (Material Design) icons, by name.
Singleton {
    function g(cp) { return String.fromCodePoint(cp) }

    readonly property string logo: g(0xF0035)    // apple
    readonly property var wifi: [g(0xF092F), g(0xF091F), g(0xF0922), g(0xF0925), g(0xF0928)]
    readonly property string wifiOff: g(0xF092E)
    readonly property string bluetooth: g(0xF00AF)
    readonly property string bluetoothOff: g(0xF00B2)
    readonly property string bluetoothConnected: g(0xF00B1)
    readonly property var volume: [g(0xF057F), g(0xF0580), g(0xF057E)]
    readonly property string volumeMuted: g(0xF075F)
    readonly property var battery: [g(0xF007A), g(0xF007B), g(0xF007C), g(0xF007D), g(0xF007E),
                                    g(0xF007F), g(0xF0080), g(0xF0081), g(0xF0082), g(0xF0079)]
    readonly property string batteryCharging: g(0xF0084)
    readonly property string plug: g(0xF06A5)
    readonly property string bell: g(0xF009A)
    readonly property string bellOff: g(0xF009B)
    readonly property string coffee: g(0xF0176)
    readonly property string night: g(0xF0594)
    readonly property string brightness: g(0xF00DF)
    readonly property string controlCenter: g(0xF062E)
    readonly property string play: g(0xF040A)
    readonly property string pause: g(0xF03E4)
    readonly property string next: g(0xF04AD)
    readonly property string previous: g(0xF04AE)
    readonly property string music: g(0xF0387)
    readonly property string cpu: g(0xF035B)
    readonly property string memory: g(0xF061A)
    readonly property string thermometer: g(0xF050F)
    readonly property string check: g(0xF012C)
    readonly property string lock: g(0xF033E)
    readonly property string chevron: g(0xF0142)
    readonly property string refresh: g(0xF0450)
    readonly property string cog: g(0xF0493)
    readonly property string headphones: g(0xF02CB)
    readonly property string speaker: g(0xF04C3)
    readonly property string laptop: g(0xF0322)
    readonly property string keyboard: g(0xF030C)
    readonly property string mouse: g(0xF037D)
    readonly property string phone: g(0xF011C)
    readonly property string apps: g(0xF003B)
    readonly property string airdrop: g(0xF0003)
    readonly property string folder: g(0xF024B)
    readonly property string close: g(0xF0156)

    function wifiIcon(strength) { return wifi[Math.max(0, Math.min(4, Math.round(strength * 4)))] }
    function volumeIcon(vol, muted) {
        if (muted || vol <= 0) return volumeMuted
        return volume[vol < 0.34 ? 0 : vol < 0.67 ? 1 : 2]
    }
    function batteryIcon(pct) { return battery[Math.max(0, Math.min(9, Math.ceil(pct * 10) - 1))] }
    function deviceIcon(icon) {
        if (/headset|headphone|audio/.test(icon)) return headphones
        if (/keyboard/.test(icon)) return keyboard
        if (/mouse|input-tablet/.test(icon)) return mouse
        if (/phone/.test(icon)) return phone
        if (/computer/.test(icon)) return laptop
        return bluetooth
    }
}
