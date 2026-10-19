import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.common

// Drop-down terminal (⌘`) that grows out of the notch, Dynamic-Island style.
// Opening: a black pill swells out of the notch with a spring (wider first, then
// taller), then quickly fades away to reveal the normal frosted kitty window.
// Closing plays it backwards into the notch.
// The terminal is kitty --class dropdown-term in the hidden "dropdown" Space.
// Driven by: qs ipc call dropdown toggle|open|close   (scripts/dropdown-term)
Scope {
    id: root

    readonly property var screen: Quickshell.screens.find(s => s.name === "eDP-1") ?? Quickshell.screens[0]
    readonly property real sw: screen?.width ?? 1512
    readonly property real sh: screen?.height ?? 982

    // The notch, and where the terminal sits (right under it)
    readonly property rect notchRect: Qt.rect((sw - Theme.notchWidth * 0.8) / 2, 0, Theme.notchWidth * 0.8, Theme.barHeight)
    readonly property rect defaultRect: Qt.rect(Math.round(sw * 0.25), Theme.barHeight + 6, Math.round(sw * 0.5), Math.round(sh * 0.48))
    // Where the terminal actually is. It always opens at defaultRect; if you resize it
    // while it's open, it's measured when it hides so the shrink still matches.
    property rect windowRect: defaultRect

    // Animation feel
    readonly property int growMs: 200           // the shape swelling out of the notch
    readonly property real spring: 1.15         // overshoot of the swell (0 = none)
    readonly property int shrinkMs: 200
    readonly property int meltMs: 100           // black → translucent terminal at the end

    property bool spaceShown: false             // is the "dropdown" Space visible?
    property bool busy: false                   // an animation is running

    // cursor:no_warps as configured (opening flips it on briefly)
    property bool noWarps: false
    Process {
        running: true
        command: ["hyprctl", "getoption", "cursor:no_warps", "-j"]
        stdout: StdioCollector { onStreamFinished: { try { const o = JSON.parse(text); root.noWarps = o.bool ?? o.int === 1 } catch (e) {} } }
    }

    function exists() { return Hyprland.toplevels.values.some(t => t.wayland?.appId === "dropdown-term") }
    function toggle() { spaceShown ? hide() : show() }

    function show() {
        if (busy || spaceShown || !exists()) return
        busy = true
        // Always open at the original size, right under the notch (floating: size and
        // position are ignored if it was switched to tiled with ⌥⌘F)
        windowRect = defaultRect
        const term = "window = 'class:^(dropdown-term)$'"
        Hyprland.dispatch("hl.dsp.window.float({ action = 'on', " + term + " })")
        Hyprland.dispatch("hl.dsp.window.resize({ x = " + Math.round(windowRect.width) + ", y = " + Math.round(windowRect.height) + ", " + term + " })")
        Hyprland.dispatch("hl.dsp.window.move({ x = " + Math.round(windowRect.x) + ", y = " + Math.round(windowRect.y) + ", " + term + " })")
        shape.collapse()
        shape.opacity = 1
        grow.restart()
    }
    function hide() {
        if (busy || !spaceShown) return
        busy = true
        measure.running = true          // → startShrink() once we know the window's real size
    }
    function startShrink() {
        shape.expand()
        shape.opacity = 0
        shrink.restart()
    }

    // Read the terminal's real position/size (you may have moved or resized it)
    Process {
        id: measure
        command: ["sh", "-c", "hyprctl clients -j | jq -c '[.[] | select(.class == \"dropdown-term\")][0] | [.at[0], .at[1], .size[0], .size[1]]'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const g = JSON.parse(text)
                    if (g && g[2] > 50 && g[3] > 50) {
                        const r = Qt.rect(g[0], g[1], g[2], g[3])
                        root.windowRect = r
                    }
                } catch (e) {}
                root.startShrink()
            }
        }
    }

    // Track the Space; hide when another window takes focus (like a menu)
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activespecial") {
                // only the built-in screen's Space counts: that's where it lives
                const [name, mon] = event.data.split(",")
                if (mon === root.screen?.name) root.spaceShown = name === "special:dropdown"
            } else if (event.name === "activewindow" && root.spaceShown && !root.busy) {
                const cls = event.data.split(",")[0]
                if (cls && cls !== "dropdown-term") root.hide()
            }
        }
    }

    // ── Opening ─────────────────────────────────────────────────────
    SequentialAnimation {
        id: grow
        // 1. The shape swells out of the notch: wider first, then taller, with a spring
        ParallelAnimation {
            NumberAnimation { target: shape; property: "bodyY"; to: root.windowRect.y; duration: 260; easing.type: Easing.OutCubic }
            NumberAnimation { target: shape; property: "bodyX"; to: root.windowRect.x; duration: root.growMs; easing.type: Easing.OutBack; easing.overshoot: root.spring }
            NumberAnimation { target: shape; property: "bodyW"; to: root.windowRect.width; duration: root.growMs; easing.type: Easing.OutBack; easing.overshoot: root.spring }
            SequentialAnimation {
                PauseAnimation { duration: 60 }
                NumberAnimation { target: shape; property: "bodyH"; to: root.windowRect.height; duration: root.growMs; easing.type: Easing.OutBack; easing.overshoot: root.spring * 0.8 }
            }
            NumberAnimation { target: shape; property: "radius"; to: Theme.panelRadius + 6; duration: root.growMs }
            // 2. Near the end the terminal appears underneath…
            SequentialAnimation {
                PauseAnimation { duration: root.growMs - 180 }
                ScriptAction {
                    // Hyprland opens special Spaces on the focused screen, so focus the
                    // built-in one first (without yanking the cursor over there)
                    script: Quickshell.execDetached(["hyprctl", "--batch",
                        "eval hl.config({ cursor = { no_warps = true } }); dispatch hl.dsp.focus({ monitor = '" + root.screen?.name + "' })"
                        + "; dispatch hl.dsp.workspace.toggle_special('dropdown'); dispatch hl.dsp.focus({ window = 'class:^(dropdown-term)$' })"
                        + "; eval hl.config({ cursor = { no_warps = " + root.noWarps + " } })"])
                }
            }
        }
        // 3. …and the black quickly melts away, leaving the translucent window
        ParallelAnimation {
            NumberAnimation { target: shape; property: "opacity"; to: 0; duration: root.meltMs; easing.type: Easing.OutQuad }
            NumberAnimation { target: shape; property: "radius"; to: Theme.panelRadius; duration: root.meltMs }
        }
        ScriptAction { script: root.busy = false }
    }

    // ── Closing (the same, backwards) ───────────────────────────────
    SequentialAnimation {
        id: shrink
        NumberAnimation { target: shape; property: "opacity"; to: 1; duration: 110; easing.type: Easing.OutQuad }
        ScriptAction { script: Hyprland.dispatch("hl.dsp.workspace.toggle_special('dropdown')") }  // fades out under the shape
        ParallelAnimation {
            NumberAnimation { target: shape; property: "bodyH"; to: root.notchRect.height; duration: root.shrinkMs; easing.type: Easing.InBack; easing.overshoot: 0.6 }
            SequentialAnimation {
                PauseAnimation { duration: 50 }
                ParallelAnimation {
                    NumberAnimation { target: shape; property: "bodyX"; to: root.notchRect.x; duration: root.shrinkMs - 50; easing.type: Easing.InCubic }
                    NumberAnimation { target: shape; property: "bodyW"; to: root.notchRect.width; duration: root.shrinkMs - 50; easing.type: Easing.InCubic }
                }
            }
            NumberAnimation { target: shape; property: "radius"; to: 10; duration: root.shrinkMs }
            SequentialAnimation {
                PauseAnimation { duration: root.shrinkMs - 140 }
                ParallelAnimation {
                    NumberAnimation { target: shape; property: "bodyY"; to: 0; duration: 140; easing.type: Easing.InCubic }
                }
            }
        }
        NumberAnimation { target: shape; property: "opacity"; to: 0; duration: 70 }
        ScriptAction { script: root.busy = false }
    }

    // ── The black shape ─────────────────────────────────────────────
    PanelWindow {
        screen: root.screen
        visible: shape.opacity > 0
        color: "transparent"
        anchors { top: true; left: true; right: true }
        implicitHeight: root.sh
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}                           // never takes clicks
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notchmorph"

        Item {
            id: shape
            anchors.fill: parent
            opacity: 0

            property real bodyX: root.notchRect.x
            property real bodyY: 0
            property real bodyW: root.notchRect.width
            property real bodyH: root.notchRect.height
            property real radius: 10

            function collapse() {
                bodyX = root.notchRect.x; bodyY = 0
                bodyW = root.notchRect.width; bodyH = root.notchRect.height; radius = 10
            }
            function expand() {
                bodyX = root.windowRect.x; bodyY = root.windowRect.y
                bodyW = root.windowRect.width; bodyH = root.windowRect.height; radius = Theme.panelRadius
            }

            Rectangle {
                x: shape.bodyX
                y: shape.bodyY
                width: shape.bodyW
                height: shape.bodyH
                radius: Math.min(shape.radius, height / 2, width / 2)
                color: "black"
                // square top corners while still tucked into the notch
                Rectangle {
                    visible: shape.bodyY < 2
                    width: parent.width
                    height: parent.radius
                    color: "black"
                }
            }
        }
    }
}
