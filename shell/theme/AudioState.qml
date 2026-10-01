pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // State
    property bool   popupVisible:  false
    property var    sinks:         []
    property var    sources:       []
    property string defaultSink:   ""
    property string defaultSource: ""
    property int    volume:        0
    property bool   muted:         false
    property int    micVolume:     0
    property bool   micMuted:      false

    // Popup
    function show() {
        SessionState.closeAllPopups()
        refreshAll()
        popupVisible = true
    }

    function hide() {
        popupVisible = false
    }

    // Refresh
    function parseList(text) {
        const devices = []
        let defaultId = ""
        for (const line of text.split("\n")) {
            if (!line.trim())
                continue
            const parts = line.split("\t")
            if (parts.length < 2)
                continue
            const id = parts[0].trim()
            const description = parts[1].trim()
            if (!id || description.includes(".monitor"))
                continue
            const isDefault = parts.some(part => part.trim() === "*")
            devices.push({ name: id, description: description })
            if (isDefault)
                defaultId = id
        }
        return { devices: devices, defaultId: defaultId }
    }

    function parseVolume(text) {
        const volMatch = text.match(/([\d.]+)/)
        const volume = volMatch ? Math.round(parseFloat(volMatch[1]) * 100) : 0
        const muted = /muted/i.test(text)
        return { volume: volume, muted: muted }
    }

    function refreshSinks() {
        sinksProc.running = false
        sinksProc.running = true
    }

    function refreshSinkState() {
        sinkVolProc.running = false
        sinkVolProc.running = true
    }

    function refreshSources() {
        sourcesProc.running = false
        sourcesProc.running = true
    }

    function refreshSourceState() {
        sourceVolProc.running = false
        sourceVolProc.running = true
    }

    function refreshAll() {
        refreshSinks()
        refreshSinkState()
        refreshSources()
        refreshSourceState()
    }

    function setDefaultSink(id) {
        Quickshell.execDetached(["wpctl", "set-default", id])
    }

    function setDefaultSource(id) {
        Quickshell.execDetached(["wpctl", "set-default", id])
    }

    function setVolume(newVol) {
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", newVol + "%"])
    }

    function setMicVolume(newVol) {
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", newVol + "%"])
    }

    function setMute(mute) {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", mute ? "1" : "0"])
    }

    function setMicMute(mute) {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", mute ? "1" : "0"])
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            root.refreshSinkState()
            root.refreshSourceState()
        }
    }

    // pactl subscribe
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            root.refreshSinks()
            root.refreshSources()
        }
    }

    // Sink list
    Process {
        id: sinksProc
        command: ["wpctl", "list", "audio", "sinks"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = root.parseList(text)
                root.sinks = parsed.devices
                if (parsed.defaultId)
                    root.defaultSink = parsed.defaultId
            }
        }
    }

    // Source list
    Process {
        id: sourcesProc
        command: ["wpctl", "list", "audio", "sources"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = root.parseList(text)
                root.sources = parsed.devices
                if (parsed.defaultId)
                    root.defaultSource = parsed.defaultId
            }
        }
    }

    // Default sink / source
    Process {
        id: sinkVolProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = root.parseVolume(text)
                root.volume = parsed.volume
                root.muted = parsed.muted
            }
        }
    }

    // Mute
    Process {
        id: sourceVolProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = root.parseVolume(text)
                root.micVolume = parsed.volume
                root.micMuted = parsed.muted
            }
        }
    }
}
