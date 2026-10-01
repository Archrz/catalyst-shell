pragma Singleton
import QtQuick
import Quickshell
import "."

Singleton {
    readonly property int transitionDuration: 250
    readonly property string monoFont: "JetBrainsMono Nerd Font"

    readonly property color barBackground: "#000000"
    readonly property color pillForeground: "#000000"
    readonly property color overlayBackground: "#66000000"

    readonly property color launcher: "#ffb454"
    readonly property color battery: "#ffb454"
    readonly property color network: "#39bae6"
    readonly property color audio: "#39bae6"
    readonly property color clock: "#ffb454"
    readonly property color date: "#a6e3a1"
    readonly property color brightness: "#ffb454"
    readonly property color bluetooth: "#39bae6"
    readonly property color session: "#a6e3a1"
    readonly property color dashboard: "#0d0d0d"

    readonly property color tray: "#0d0d0d"
    readonly property color workspaceActive: "#ffb454"
    readonly property color workspaceInactive: "#0d0d0d"
    readonly property color titleBackground: "#0d0d0d"
    readonly property color titleForeground: "#e6e1cf"

    readonly property color popupBackground: "#000000"
    readonly property color rowBackground: "#0d0d0d"
    readonly property color trackBackground: "#2d3640"
    readonly property color border: "#2d3640"

    readonly property color textMain: "#e6e1cf"
    readonly property color textDim: "#8E959E"
    readonly property color textAccent: "#ffb454"
    readonly property color textBox: "#0d0d0d"
    readonly property color textBoxDim: "#2d3640"

    readonly property color scanning: "#39bae6"
    readonly property color networkScanning: "#39bae6"
    readonly property color pairing: "#ffb454"
    readonly property color error: "#f07178"

    readonly property color dashboardBackground: "#000000"
    readonly property color dashboardCard: "#0d0d0d"
    readonly property color dashboardAccent: "#ffb454"
    readonly property color dashboardStripe: "#2d3640"
    readonly property color profile: "#a6e3a1"
    readonly property color system: "#39bae6"
    readonly property color cpuRing: "#f07178"
    readonly property color ramRing: "#39bae6"
    readonly property color gpuRing: "#a6e3a1"

    function profileColor(_profile) {
        return "#ffb454"
    }

    property var _hashCache: ({ })
    function hashColor(str) {
        if (!str || str === "") return "#2d3640"
        if (_hashCache[str]) return _hashCache[str]
        var palette = [ "#ffb454", "#a6e3a1", "#39bae6", "#f07178", "#d2a6ff", "#e6b673" ]
        var hash = 0
        for (var i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash)
            hash = hash & hash
        }
        var result = palette[Math.abs(hash) % palette.length]
        _hashCache[str] = result
        return result
    }
}
