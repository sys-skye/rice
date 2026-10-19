pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Colours, fonts and sizes shared by the whole shell. Follows Appearance (light/dark).
Singleton {
    readonly property bool isDark: Appearance.isDark

    readonly property string font: "Inter"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    // Foreground tint at alpha `a`: white on dark, black on light (used for hovers, tracks, tiles…)
    function fg(a) { return isDark ? Qt.rgba(1, 1, 1, a) : Qt.rgba(0, 0, 0, a * 0.75) }

    readonly property color text: isDark ? "#f5f5f7" : "#1d1d1f"
    readonly property color textDim: isDark ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(0, 0, 0, 0.5)
    readonly property color accent: "#0a84ff"
    readonly property color red: isDark ? "#ff453a" : "#ff3b30"
    readonly property color orange: isDark ? "#ff9f0a" : "#ff9500"
    readonly property color yellow: isDark ? "#ffd60a" : "#c9a400"
    readonly property color green: isDark ? "#30d158" : "#28cd41"

    readonly property color barBg: isDark ? Qt.rgba(0.09, 0.09, 0.11, 0.45) : Qt.rgba(0.97, 0.97, 0.98, 0.55)
    readonly property color panelBg: isDark ? Qt.rgba(0.14, 0.14, 0.16, 0.80) : Qt.rgba(0.96, 0.96, 0.97, 0.86)
    readonly property color panelSolid: isDark ? Qt.rgba(0.13, 0.13, 0.15, 0.92) : Qt.rgba(0.97, 0.97, 0.98, 0.95)
    readonly property color windowBg: isDark ? Qt.rgba(0.11, 0.11, 0.13, 0.96) : Qt.rgba(0.95, 0.95, 0.96, 0.98)
    readonly property color dockBg: isDark ? Qt.rgba(0.16, 0.16, 0.19, 0.45) : Qt.rgba(1, 1, 1, 0.45)
    readonly property color dim: isDark ? Qt.rgba(0.05, 0.05, 0.08, 0.45) : Qt.rgba(0.85, 0.86, 0.9, 0.4)
    readonly property color panelBorder: isDark ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color tileBg: isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.7)
    readonly property color hover: fg(0.14)
    readonly property color separator: fg(0.12)
    readonly property color sliderFill: isDark ? Qt.rgba(1, 1, 1, 0.92) : "white"
    readonly property color streak: isDark ? Qt.rgba(0.92, 0.92, 0.96, 1) : Qt.rgba(0.2, 0.2, 0.25, 1)

    // The menu bar covers the notch strip. Sizes are in real screen pixels and converted
    // with the display scale, so they still match the notch at "More Space" (1.33×).
    readonly property bool hasNotch: true      // installer sets false on Macs without a notch
    readonly property var builtin: Quickshell.screens.find(s => s.name === "eDP-1") ?? Quickshell.screens[0]
    // real pixels ÷ logical pixels (Qt rounds its own ratio, so work it out from the widths)
    readonly property real panelPixels: Hyprland.monitors.values.find(m => m.name === (builtin?.name ?? "eDP-1"))?.width ?? 0
    readonly property real screenScale: builtin && builtin.width > 0 && panelPixels > 0 ? panelPixels / builtin.width : 2
    readonly property int barHeight: hasNotch ? Math.round(64 / screenScale) : 32     // 64 px ≈ notch height
    readonly property int notchWidth: hasNotch ? Math.round(460 / screenScale) : 0     // centre strip kept empty
    readonly property int panelRadius: 14
    readonly property int fontSize: 13
    readonly property int smallFontSize: 11
    readonly property int iconSize: 16
}
