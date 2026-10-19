import QtQuick
import qs.common

Column {
    width: parent ? parent.width : 500
    Component.onCompleted: InputSettings.refreshMice()

    Group {
        title: "Pointer"
        SettingRow {
            label: "Tracking speed"
            SettingSlider {
                from: -1; to: 1; ticks: 9
                minLabel: "Slow"; maxLabel: "Fast"
                value: InputSettings.sensitivity
                onMoved: v => InputSettings.set("sensitivity", v)
            }
        }
        SettingRow {
            label: "Acceleration"
            hint: InputSettings.accel === "flat" ? "Same speed no matter how fast you move" : "Faster movements go further, like macOS"
            last: true
            Segmented {
                options: [{ label: "Adaptive", value: "adaptive" }, { label: "Flat", value: "flat" }]
                value: InputSettings.accel
                onPicked: v => InputSettings.set("accel", v)
            }
        }
    }

    Group {
        title: "Cursor"
        footer: "Pointer style and size also follow GTK Settings. The motion-blur trail only appears when the cursor moves fast, and hides in fullscreen apps."
        SettingRow {
            label: "Pointer style"
            Segmented {
                options: CursorSync.themes.map(t => ({ label: t.replace(/_cursors$/, "").replace(/_/g, " "), value: t }))
                value: CursorSync.theme
                onPicked: v => CursorSync.setTheme(v)
            }
        }
        SettingRow {
            label: "Pointer size"
            SettingSlider {
                from: 16; to: 64; stepSize: 4; ticks: 13
                minLabel: "Normal"; maxLabel: "Large"
                value: CursorSync.size
                onMoved: v => CursorSync.setSize(v)
            }
        }
        SettingRow {
            label: "Motion blur trail"
            last: !InputSettings.trailEnabled
            Toggle { checked: InputSettings.trailEnabled; onToggled: v => InputSettings.set("trailEnabled", v) }
        }
        SettingRow {
            visible: InputSettings.trailEnabled
            label: "Trail type"
            Segmented {
                options: [{ label: "Blur", value: "blur" }, { label: "Comet", value: "comet" }, { label: "Dots", value: "dots" }]
                value: InputSettings.trailType
                onPicked: v => InputSettings.set("trailType", v)
            }
        }
        SettingRow {
            visible: InputSettings.trailEnabled
            label: "Trail length"
            SettingSlider {
                from: 15; to: 150; ticks: 8
                minLabel: "Short"; maxLabel: "Long"
                value: InputSettings.trailLength
                onMoved: v => InputSettings.set("trailLength", v)
            }
        }
        SettingRow {
            visible: InputSettings.trailEnabled
            label: "Strength"
            last: true
            SettingSlider {
                from: 0.15; to: 1; ticks: 7
                minLabel: "Subtle"; maxLabel: "Strong"
                value: InputSettings.trailStrength
                onMoved: v => InputSettings.set("trailStrength", v)
            }
        }
    }

    Group {
        title: "Clicking"
        SettingRow {
            label: "Tap to click"
            hint: "Tap with one finger instead of pressing"
            Toggle { checked: InputSettings.tapToClick; onToggled: v => InputSettings.set("tapToClick", v) }
        }
        SettingRow {
            label: "Tap and drag"
            hint: "Double-tap and hold to drag"
            Toggle { checked: InputSettings.tapAndDrag; onToggled: v => InputSettings.set("tapAndDrag", v) }
        }
        SettingRow {
            label: "Secondary click with two fingers"
            hint: InputSettings.twoFingerRightClick ? "Two-finger click = right click" : "Click the bottom-right corner to right click"
            Toggle { checked: InputSettings.twoFingerRightClick; onToggled: v => InputSettings.set("twoFingerRightClick", v) }
        }
        SettingRow {
            label: "Ignore trackpad while typing"
            last: true
            Toggle { checked: InputSettings.disableWhileTyping; onToggled: v => InputSettings.set("disableWhileTyping", v) }
        }
    }

    Group {
        title: "Scrolling"
        SettingRow {
            label: "Natural scrolling"
            hint: "Content moves with your fingers"
            Toggle { checked: InputSettings.naturalScroll; onToggled: v => InputSettings.set("naturalScroll", v) }
        }
        SettingRow {
            label: "Scroll speed"
            SettingSlider {
                from: 0.1; to: 1.5; ticks: 8
                minLabel: "Slow"; maxLabel: "Fast"
                value: InputSettings.scrollFactor
                onMoved: v => InputSettings.set("scrollFactor", v)
            }
        }
        SettingRow {
            label: "Terminal scroll speed"
            hint: "Extra multiplier inside terminals"
            last: true
            SettingSlider {
                from: 0.5; to: 4; ticks: 8
                minLabel: "Slow"; maxLabel: "Fast"
                value: InputSettings.terminalScroll
                onMoved: v => InputSettings.set("terminalScroll", v)
            }
        }
    }

    Group {
        title: "Swiping between Spaces"
        footer: "Three fingers left/right. Lighter = less finger travel to move a whole Space. "
              + "The switch point is how far you must swipe before it switches instead of snapping back; "
              + "a quick flick switches anyway."
        SettingRow {
            label: "Swipe distance"
            hint: InputSettings.swipeDistance + " px for one Space"
            SettingSlider {
                // reversed: right = lighter (less travel)
                from: 100; to: 700; stepSize: 25; ticks: 7
                minLabel: "Firm"; maxLabel: "Light"
                value: 800 - InputSettings.swipeDistance
                onMoved: v => InputSettings.set("swipeDistance", Math.round(800 - v))
            }
        }
        SettingRow {
            label: "Switch point"
            hint: Math.round(InputSettings.swipeSwitchAt * 100) + "% of the way"
            SettingSlider {
                from: 0.15; to: 0.85; stepSize: 0.05; ticks: 8
                minLabel: "Early"; maxLabel: "Late"
                value: InputSettings.swipeSwitchAt
                onMoved: v => InputSettings.set("swipeSwitchAt", v)
            }
        }
        SettingRow {
            label: "Flick to switch"
            SettingSlider {
                // reversed: right = easier (lower speed needed)
                from: 0; to: 100; stepSize: 5; ticks: 6
                minLabel: "Hard"; maxLabel: "Easy"
                value: 110 - InputSettings.swipeFlick
                onMoved: v => InputSettings.set("swipeFlick", Math.round(110 - v))
            }
        }
        SettingRow {
            label: "Swipe through several Spaces"
            hint: "One long swipe can move more than one Space"
            last: true
            Toggle { checked: InputSettings.swipeForever; onToggled: v => InputSettings.set("swipeForever", v) }
        }
    }

    Group {
        title: "Mouse"
        footer: InputSettings.connectedMice.length === 0 ? "Connect a mouse to adjust its tracking speed here." : ""
        Repeater {
            model: InputSettings.connectedMice
            delegate: Column {
                required property string modelData
                width: parent.width
                SettingRow {
                    label: modelData
                    hint: "Tracking speed"
                    SettingSlider {
                        from: -1; to: 1; ticks: 9
                        minLabel: "Slow"; maxLabel: "Fast"
                        value: InputSettings.mouse(modelData).sensitivity
                        onMoved: v => InputSettings.setMouse(modelData, "sensitivity", v)
                    }
                }
                SettingRow {
                    label: "Acceleration"
                    Segmented {
                        options: [{ label: "Adaptive", value: "adaptive" }, { label: "Flat", value: "flat" }]
                        value: InputSettings.mouse(modelData).accel
                        onPicked: v => InputSettings.setMouse(modelData, "accel", v)
                    }
                }
            }
        }
        SettingRow {
            label: "Mouse scroll speed"
            SettingSlider {
                from: 0.2; to: 3; ticks: 8
                minLabel: "Slow"; maxLabel: "Fast"
                value: InputSettings.mouseScrollFactor
                onMoved: v => InputSettings.set("mouseScrollFactor", v)
            }
        }
        SettingRow {
            label: "Natural scrolling for mouse"
            last: true
            Toggle { checked: InputSettings.mouseNaturalScroll; onToggled: v => InputSettings.set("mouseNaturalScroll", v) }
        }
    }
}
