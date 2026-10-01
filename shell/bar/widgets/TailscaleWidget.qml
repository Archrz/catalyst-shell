import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar.widgets
import "../../theme"

Pill {
    id: root

    property string ip: ""
    property bool busy: false
    property bool forcingOff: false
    readonly property bool online: !forcingOff && ip.length > 0

    hoverReveal: false
    pillColor: online ? PanelColors.launcher : PanelColors.rowBackground
    textColor: online ? PanelColors.pillForeground : PanelColors.textMain
    widestLabel: "100.000.000.000"
    label: online ? root.ip : "off"

    Process {
        id: ipProc
        command: [ "tailscale", "ip", "-4" ]
        running: false
        stdout: SplitParser {
            onRead: line => {
                const value = line.trim()
                if (value.length > 0 && !root.forcingOff)
                    root.ip = value
            }
        }
        onExited: (code) => {
            if (code !== 0 || root.forcingOff)
                root.ip = ""
        }
    }

    Process {
        id: downProc
        command: [ "tailscale", "down" ]
        running: false
        onExited: () => {
            root.busy = false
            ipProc.running = true
        }
    }

    Process {
        id: upProc
        command: [ "tailscale", "up", "--accept-routes" ]
        running: false
        onExited: () => {
            root.busy = false
            root.forcingOff = false
            ipProc.running = true
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!root.busy && !downProc.running && !upProc.running)
                ipProc.running = true
        }
        Component.onCompleted: ipProc.running = true
    }

    mouseArea.onClicked: {
        if (root.busy || downProc.running || upProc.running)
            return
        root.busy = true

        if (root.online || root.ip.length > 0) {
            root.forcingOff = true
            root.ip = ""
            downProc.running = true
        }
        else {
            root.forcingOff = false
            upProc.running = true
        }
    }
}
