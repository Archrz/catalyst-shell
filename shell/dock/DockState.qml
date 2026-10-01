pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var    activeIcon:         null
    property string defaultGpuName:     ""
    property int    defaultGpuIndex:    -1
    property string nonDefaultGpuName:  ""
    property int    nonDefaultGpuIndex: -1
    property bool   gpuInfoReady:       false

    signal closeAll()

    function openFor(icon) {
        if (root.activeIcon && root.activeIcon !== icon)
            root.closeAll()
        root.activeIcon = icon
    }

    function close() {
        root.activeIcon = null
        root.closeAll()
    }

    Process {
        command: ["switcherooctl", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root._parse(this.text)
        }
    }

    function _parse(text) {
        var lines   = text.split("\n")
        var devices = []
        var current = null

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()

            var deviceMatch = line.match(/^Device:\s*(\d+)/)
            if (deviceMatch) {
                if (current) devices.push(current)
                current = { index: parseInt(deviceMatch[1]), name: "", isDefault: false }
                continue
            }
            if (!current) continue

            var nameMatch    = line.match(/^Name:\s+(.+)$/)
            if (nameMatch)    { current.name      = nameMatch[1].trim();              continue }

            var defaultMatch = line.match(/^Default:\s+(.+)$/)
            if (defaultMatch) { current.isDefault = defaultMatch[1].trim() === "yes"; continue }
        }
        if (current) devices.push(current)

        for (var j = 0; j < devices.length; j++) {
            var dev = devices[j]
            if (dev.isDefault) {
                root.defaultGpuName  = dev.name
                root.defaultGpuIndex = dev.index
            } else {
                root.nonDefaultGpuName  = dev.name
                root.nonDefaultGpuIndex = dev.index
            }
        }

        root.gpuInfoReady = true
    }
}
