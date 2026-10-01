pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpuUsage: 0
    property real ramUsage: 0
    property real gpuUsage: 0

    property int _prevCpuTotal: 0
    property int _prevCpuIdle: 0

    function updateCpu(text) {
        const line = text.split("\n").find(l => l.startsWith("cpu "))
        if (!line) return
        const parts = line.trim().split(/\s+/).slice(1).map(v => parseInt(v) || 0)
        const idle = parts[3] + parts[4]
        const total = parts.reduce((a, b) => a + b, 0)
        const diffTotal = total - _prevCpuTotal
        const diffIdle = idle - _prevCpuIdle
        if (_prevCpuTotal > 0 && diffTotal > 0)
            cpuUsage = Math.min(100, Math.max(0, Math.round(100 * (diffTotal - diffIdle) / diffTotal)))
        _prevCpuTotal = total
        _prevCpuIdle = idle
    }

    function updateMem(text) {
        let total = 0
        let avail = 0
        for (const line of text.split("\n")) {
            const parts = line.trim().split(/\s+/)
            if (parts[0] === "MemTotal:") total = parseInt(parts[1]) || 0
            if (parts[0] === "MemAvailable:") avail = parseInt(parts[1]) || 0
        }
        if (total > 0)
            ramUsage = Math.min(100, Math.max(0, Math.round(100 * (total - avail) / total)))
    }

    FileView {
        id: cpuStat
        path: "/proc/stat"
        onLoaded: root.updateCpu(text())
    }

    FileView {
        id: memInfo
        path: "/proc/meminfo"
        onLoaded: root.updateMem(text())
    }

    Process {
        id: gpuProc
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ' || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = parseInt(text.trim()) || 0
                root.gpuUsage = Math.min(100, Math.max(0, raw * 0.2 + root.gpuUsage * 0.8))
            }
        }
    }

    Component.onCompleted: {
        cpuStat.reload()
        memInfo.reload()
        gpuProc.running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuStat.reload()
            memInfo.reload()
            gpuProc.running = false
            gpuProc.running = true
        }
    }
}
