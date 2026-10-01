pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool   available:     false
    property string deviceName:    ""
    property int    brightness:    0
    property int    maxBrightness: 0

    // Detection
    Process {
        id: detectProc
        command: ["brightnessctl", "--list", "--machine-readable"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                for (const line of lines) {
                    const parts = line.trim().split(",")
                    if (parts.length < 5) continue
                    const id  = parts[0]
                    const cls = parts[1]
                    const cur = parseInt(parts[2], 10)
                    const max = parseInt(parts[4], 10)
                    if (cls === "leds" && id.includes("kbd_backlight")) {
                        root.deviceName    = id
                        root.maxBrightness = max
                        root.brightness    = cur
                        root.available     = true
                        break
                    }
                }
            }
        }
    }

    // Read
    Process {
        id: readProc
        command: ["brightnessctl", "-d", root.deviceName, "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(this.text.trim(), 10)
                if (!isNaN(val)) root.brightness = val
            }
        }
    }

    // Write — toggle running false→true each call (Quickshell no-op otherwise)
    Process {
        id: writeProc
        command: []
        running: false
    }

    // Poll
    Timer {
        interval: 1000
        repeat: true
        running: root.available
        onTriggered: {
            if (!writeProc.running) {
                readProc.running = false
                readProc.running = true
            }
        }
    }

    // API
    function setBrightness(val) {
        if (!root.available) return
        const v = Math.max(0, Math.min(root.maxBrightness, Math.round(val)))
        root.brightness = v
        writeProc.running = false
        writeProc.command = ["brightnessctl", "-d", root.deviceName, "set", String(v)]
        writeProc.running = true
    }

    function refresh() {
        if (!root.available) return
        readProc.running = false
        readProc.running = true
    }
}
