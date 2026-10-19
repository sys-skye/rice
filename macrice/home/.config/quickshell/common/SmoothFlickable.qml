import QtQuick

// A Flickable that scrolls like macOS: two-finger trackpad scrolling keeps
// gliding after you lift your fingers (momentum), and a mouse wheel scrolls in
// smooth steps instead of jumps. (libinput sends no momentum, so we add it here.)
Flickable {
    id: root

    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 2200          // lower = glides further
    maximumFlickVelocity: 6000
    clip: true

    property real _velocity: 0       // px/s the content was moving, smoothed
    property real _lastTime: 0
    property bool _hasPhases: false  // trackpad reports begin/end of a scroll

    function _clamp(y) { return Math.max(0, Math.min(y, Math.max(0, contentHeight - height))) }
    function _release() {
        if (Math.abs(_velocity) > 120) flick(0, _velocity)
        _velocity = 0
    }

    // Fallback for devices that don't say when the fingers lift
    Timer { id: liftTimer; interval: 70; onTriggered: root._release() }

    NumberAnimation {
        id: wheelAnim
        target: root
        property: "contentY"
        duration: 160
        easing.type: Easing.OutCubic
    }

    WheelHandler {
        target: null                  // we move the content ourselves…
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => {
            e.accepted = true         // …so Flickable's own (abrupt) wheel scrolling stays out of it
            const now = Date.now()
            if (e.pixelDelta.y !== 0) {
                // Trackpad: follow the fingers, remember how fast they moved
                root.cancelFlick()
                wheelAnim.stop()
                root.contentY = root._clamp(root.contentY - e.pixelDelta.y)
                const dt = Math.max(4, now - root._lastTime)
                const v = e.pixelDelta.y / dt * 1000
                root._velocity = now - root._lastTime > 100 ? v : root._velocity * 0.5 + v * 0.5
                if (e.phase !== Qt.NoScrollPhase) root._hasPhases = true
                if (e.phase === Qt.ScrollEnd) root._release()
                else if (!root._hasPhases) liftTimer.restart()
            } else if (e.phase === Qt.ScrollEnd) {
                root._release()
            } else if (e.angleDelta.y !== 0) {
                // Mouse wheel: smooth step of ~3 lines per notch
                root.cancelFlick()
                const from = wheelAnim.running ? wheelAnim.to : root.contentY
                wheelAnim.stop()
                wheelAnim.from = root.contentY
                wheelAnim.to = root._clamp(from - e.angleDelta.y / 120 * 72)
                wheelAnim.start()
            }
            root._lastTime = now
        }
    }
}
