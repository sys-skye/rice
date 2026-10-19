import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.common

// Cursor "motion blur": a soft, shape-neutral streak along the path the cursor
// just travelled, only when it moves fast (works for arrow, I-beam, hand…). Click-through overlay; toggle and
// tune in System Settings → Trackpad & Mouse.
Scope {
    id: root

    readonly property bool active: InputSettings.trailEnabled && PowerSettings.trailAllowed && !(Hyprland.focusedWorkspace?.hasFullscreen ?? false)
    readonly property int maxGhosts: 40
    readonly property real minSpeed: 500      // px/s before any blur shows
    readonly property real fullSpeed: 2500    // px/s for full-strength blur
    readonly property point streakOffset: Qt.point(3, 5)   // centre of the streak relative to the hotspot
    readonly property real windowMs: 70       // only motion this recent can leave ghosts
    readonly property real latencyMs: 16      // how far behind our position reports are; the streak is extended by this
    readonly property real maxLead: 48        // never extend the streak further than this (px)
    readonly property string type: InputSettings.trailType   // blur | comet | dots
    readonly property color tint: InputSettings.trailColor !== "auto" ? InputSettings.trailColor
                                  : type === "comet" ? Theme.accent : Theme.streak
    readonly property real dotGap: 9          // px between bubbles in the "dots" trail

    property var samples: []                  // [{ x, y, t }] newest last (t in Date.now() ms)
    property real clockOffset: NaN            // Date.now() − helper clock, smallest seen (= least delayed)
    property var ghosts: []                   // [{ x, y, o }] in global coords
    property rect box: Qt.rect(0, 0, 0, 0)    // area the ghosts cover (blur is limited to it)
    property real lastMove: 0
    property bool animating: false            // true while there is motion or a fading trail

    // Cursor positions from a tiny helper that polls Hyprland (≈0.03 ms per poll)
    Process {
        running: root.active
        command: ["python3", "-I", Quickshell.shellDir + "/assets/cursor-feed.py"]
        stdout: SplitParser {
            onRead: line => {
                const p = line.split(" ")
                root.addSample(Number(p[0]), Number(p[1]), Number(p[2]))
            }
        }
    }

    // Redraw at ~120 Hz while the trail is fading, otherwise sleep
    Timer {
        running: root.active && root.animating
        repeat: true
        interval: 8
        onTriggered: root.update()
    }
    onLastMoveChanged: if (active) update()
    onActiveChanged: if (!active) { samples = []; ghosts = [] }

    function addSample(x, y, helperT) {
        const now = Date.now()
        // Use the helper's sample time (steady) mapped onto our clock
        const off = now - helperT
        if (isNaN(clockOffset) || off < clockOffset || off - clockOffset > 1000) clockOffset = off
        const t = Math.min(now, helperT + clockOffset)
        const last = samples.length ? samples[samples.length - 1] : null
        if (last && last.x === x && last.y === y) return
        lastMove = now
        animating = true
        const keep = windowMs + 60
        samples = samples.filter(s => now - s.t < keep).concat([{ x: x, y: y, t: t }])
    }

    // Catmull-Rom: turn the sampled polyline into a smooth curve (no corners on fast circles)
    function smooth(pts) {
        if (pts.length < 3) return pts
        const out = [pts[0]]
        for (let i = 0; i < pts.length - 1; i++) {
            const p0 = pts[Math.max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[Math.min(pts.length - 1, i + 2)]
            const n = Math.max(1, Math.min(8, Math.ceil(Math.hypot(p2.x - p1.x, p2.y - p1.y) / 3)))
            for (let j = 1; j <= n; j++) {
                const u = j / n, u2 = u * u, u3 = u2 * u
                const c = (a, b, cc, d) => 0.5 * ((2 * b) + (-a + cc) * u + (2 * a - 5 * b + 4 * cc - d) * u2 + (-a + 3 * b - 3 * cc + d) * u3)
                out.push({ x: c(p0.x, p1.x, p2.x, p3.x), y: c(p0.y, p1.y, p2.y, p3.y), t: p1.t + (p2.t - p1.t) * u })
            }
        }
        return out
    }

    function update() {
        const now = Date.now()
        animating = ghosts.length > 0 || now - lastMove < 300
        const L = windowMs
        const maxDist = InputSettings.trailLength       // px: the smear never gets longer than this
        const pts = samples.filter(s => now - s.t < L + 60)
        if (pts.length < 2) { if (ghosts.length) ghosts = []; return }

        // Speed over the last ~40 ms
        const head = pts[pts.length - 1]
        let ref = pts[0]
        for (let i = pts.length - 1; i >= 0; i--) { ref = pts[i]; if (head.t - pts[i].t >= 40) break }
        const dt = Math.max(1, head.t - ref.t) / 1000
        const speed = Math.hypot(head.x - ref.x, head.y - ref.y) / dt
        // Fade out quickly once the mouse stops
        const still = Math.max(0, 1 - (now - head.t) / L)
        const k = Math.max(0, Math.min(1, (speed - minSpeed) / (fullSpeed - minSpeed))) * still
        if (k <= 0.01) { if (ghosts.length) ghosts = []; return }

        // Reports arrive a little late: extend the path to where the cursor probably is now.
        // Keep turning at the cursor's current rate, so circles stay circles (a straight
        // extension would shoot off the curve).
        const leadMs = Math.min(latencyMs, now - head.t + latencyMs * 0.5) * still
        let covered = 0                     // how much of the expected lag the extension covers (px)
        let expectedLag = 0
        if (pts.length >= 3 && leadMs > 0) {
            const p0 = pts[pts.length - 3], p1 = pts[pts.length - 2]
            const segLen = Math.hypot(head.x - p1.x, head.y - p1.y)
            const segMs = Math.max(1, head.t - p1.t)
            expectedLag = segLen / segMs * leadMs
            let turn = Math.atan2(head.y - p1.y, head.x - p1.x) - Math.atan2(p1.y - p0.y, p1.x - p0.x)
            turn = Math.atan2(Math.sin(turn), Math.cos(turn))          // wrap to −π…π
            if (Math.abs(turn) < 1.2 && segLen > 0) {                // skip sudden direction changes
                const steps = Math.min(6, leadMs / segMs)
                let dir = Math.atan2(head.y - p1.y, head.x - p1.x)
                let x = head.x, y = head.y, moved = 0
                for (let i = 0; i < Math.ceil(steps) && moved < maxLead; i++) {
                    const f = Math.min(1, steps - i)
                    dir += turn * f
                    const d = Math.min(segLen * f, maxLead - moved)
                    x += Math.cos(dir) * d; y += Math.sin(dir) * d; moved += d
                    pts.push({ x: x, y: y, t: head.t })
                }
                covered = moved
            }
        }
        // If the streak would still trail visibly behind the cursor, fade it instead of
        // showing a detached arc (only happens on extremely fast, twisty moves)
        const gap = Math.max(0, expectedLag - covered)
        const attached = Math.max(0, Math.min(1, 1 - (gap - 12) / 24))

        const path = smooth(pts)

        // Walk back along the path, dropping a ghost every `step` px
        let total = 0
        for (let i = path.length - 1; i > 0; i--) total += Math.hypot(path[i].x - path[i - 1].x, path[i].y - path[i - 1].y)
        const step = type === "dots" ? dotGap : Math.max(1.5, Math.min(total, maxDist) / maxGhosts)
        const out = []
        let want = 6                        // first ghost just behind the real cursor
        let walked = 0
        for (let i = path.length - 1; i > 0 && out.length < maxGhosts; i--) {
            const a = path[i], b = path[i - 1]
            const seg = Math.hypot(a.x - b.x, a.y - b.y)
            while (seg > 0 && want <= walked + seg && want <= maxDist && out.length < maxGhosts) {
                const f = (want - walked) / seg
                const age = (a.t + (b.t - a.t) * f) - head.t + (now - head.t)
                // Fades with both age and distance, so the tail always dissolves
                const fade = Math.pow(Math.max(0, 1 - age / L), 2) * Math.pow(Math.max(0, 1 - want / maxDist), 2)
                if (fade > 0) out.push({ x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f, o: fade, d: want / maxDist })
                want += step
            }
            walked += seg
        }
        // Many overlapping ghosts add up, so thin each one out (separate dots don't overlap)
        const thin = type === "dots" ? 0.6 : Math.min(1, (type === "comet" ? 14 : 9) / Math.max(1, out.length))
        for (const g of out) g.o *= InputSettings.trailStrength * k * thin * attached * 1.6
        ghosts = out
        if (out.length) {
            // Fixed-size box around the cursor, so the blur layer isn't reallocated every frame
            const half = InputSettings.trailLength + 40
            box = Qt.rect(Math.round(head.x - half), Math.round(head.y - half), half * 2, half * 2)
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.active
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}                  // never takes clicks
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "cursortrail"

            // Ghosts live in a box just big enough for them, softened with a blur
            // so they read as one smear instead of separate arrows.
            Item {
                x: root.box.x - modelData.x
                y: root.box.y - modelData.y
                width: root.box.width
                height: root.box.height
                visible: root.ghosts.length > 0
                layer.enabled: visible
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: root.type === "dots" ? 0.08 : root.type === "comet" ? 0.5 : 0.35
                    blurMax: 12
                }

                Repeater {
                    model: root.maxGhosts
                    // Soft dot, smaller towards the tail; the blur merges them into a streak
                    // (comet: big glowing head in the accent colour; dots: separate bubbles)
                    delegate: Rectangle {
                        required property int index
                        readonly property var g: root.ghosts[index] ?? null
                        readonly property real size: !g ? 0
                            : root.type === "comet" ? 14 - 11 * g.d
                            : root.type === "dots" ? 8 - 4 * g.d
                            : 11 - 6 * g.d
                        visible: g !== null
                        x: g ? g.x - root.box.x + root.streakOffset.x - size / 2 : 0
                        y: g ? g.y - root.box.y + root.streakOffset.y - size / 2 : 0
                        width: size
                        height: size
                        radius: size / 2
                        color: root.type === "comet" ? Qt.tint(root.tint, Qt.rgba(1, 1, 1, 0.5 * (1 - (g ? g.d : 0)))) : root.tint
                        opacity: g ? Math.min(1, g.o) : 0
                    }
                }
            }
        }
    }
}
