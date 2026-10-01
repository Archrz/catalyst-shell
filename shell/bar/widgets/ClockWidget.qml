import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../../theme"
import "../../osd"
import "../../dashboard"

Pill {
    pillColor: PanelColors.clock

    // Media state
    readonly property bool isPlaying: {
        const vals = Mpris.players.values
        for (let i = 0; i < vals.length; i++) {
            const p = vals[i]
            if (p && p.playbackState === MprisPlaybackState.Playing && (p.trackTitle ?? "") !== "")
              return true
        }
        return false
    }

    // Privacy
    readonly property bool micActive: {
        const nodes = Pipewire.nodes.values
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i]
            if (n && n.isStream && !n.isSink && n.audio !== null)
                return true
        }
        return false
    }

    // Camera via lsof — PipeWire has no reliable capture-node API in QS
    property bool cameraActive: false

    Process {
        id: cameraProc
        command: ["bash", "-c", "lsof /dev/video* 2>/dev/null | grep -c '' || echo 0"]
        stdout: SplitParser {
            onRead: data => {
                cameraActive = parseInt(data.trim()) > 0
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: cameraProc.running = true
    }

    // Clock
    SystemClock { id: clock; precision: SystemClock.Seconds }

    Canvas {
        id: clockCanvas
        width: 16
        height: 16
        antialiasing: true
        anchors.verticalCenter: parent.verticalCenter

        property var timeDate: clock.date
        onTimeDateChanged: requestPaint()

        readonly property color fgColor: PanelColors.pillForeground
        onFgColorChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.clearRect(0, 0, width, height)

            var cx = width / 2
            var cy = height / 2
            var r = width / 2 - 1

            ctx.strokeStyle = PanelColors.pillForeground
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.stroke()

            var h = timeDate.getHours() % 12
            var m = timeDate.getMinutes()

            var mAngle = m * (Math.PI * 2 / 60) - Math.PI / 2
            ctx.beginPath()
            ctx.lineWidth = 1.5
            ctx.lineCap = "round"
            ctx.moveTo(cx, cy)
            ctx.lineTo(cx + Math.cos(mAngle) * (r - 2.5), cy + Math.sin(mAngle) * (r - 2.5))
            ctx.stroke()

            var hAngle = (h + m / 60) * (Math.PI * 2 / 12) - Math.PI / 2
            ctx.beginPath()
            ctx.lineWidth = 1.75
            ctx.lineCap = "round"
            ctx.moveTo(cx, cy)
            ctx.lineTo(cx + Math.cos(hAngle) * (r - 4.0), cy + Math.sin(hAngle) * (r - 4.0))
            ctx.stroke()
        }
    }

    Text {
        text: Qt.formatTime(clock.date, "HH:mm")
        font.pixelSize: 16
        font.bold: true
        font.family: PanelColors.monoFont
        color: PanelColors.pillForeground
        Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }
    }

    // DND indicator
    Item {
        id: dndContainer
        width: NotificationState.dndOn ? 16 : 0
        height: 16
        clip: true
        anchors.verticalCenter: parent.verticalCenter

        Behavior on width {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        opacity: NotificationState.dndOn ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: ""
            font.family: PanelColors.monoFont
            font.pixelSize: 16
            color: PanelColors.pillForeground
            Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }
        }
    }

    // Visualizer
    Item {
        id: visualizerContainer
        width: isPlaying ? 14 : 0
        height: 16
        clip: true
        anchors.verticalCenter: parent.verticalCenter

        Behavior on width {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        opacity: isPlaying ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Row {
            spacing: 2
            anchors.centerIn: parent

            Repeater {
                model: 3
                Rectangle {
                    id: bar
                    width: 2.2
                    radius: width / 2
                    color: PanelColors.pillForeground
                    Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }
                    anchors.verticalCenter: parent.verticalCenter

                    readonly property int targetHeight: index === 0 ? 14 : (index === 1 ? 10 : 16)
                    readonly property int animDuration: index === 0 ? 350 : (index === 1 ? 500 : 420)

                    SequentialAnimation on height {
                        running: isPlaying && visualizerContainer.opacity > 0.1
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: bar.targetHeight
                            duration: bar.animDuration
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            to: 4
                            duration: bar.animDuration
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
        }
    }

    // Privacy
    Item {
        id: micContainer
        width: micActive ? 16 : 0
        height: 16
        clip: true
        anchors.verticalCenter: parent.verticalCenter

        Behavior on width {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        opacity: micActive ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: ""
            font.family: PanelColors.monoFont
            font.pixelSize: 16
            color: Colors.red400
            Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }
        }
    }

    // Camera
    Item {
        id: cameraContainer
        width: cameraActive ? 16 : 0
        height: 16
        clip: true
        anchors.verticalCenter: parent.verticalCenter

        Behavior on width {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        opacity: cameraActive ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: ""
            font.family: PanelColors.monoFont
            font.pixelSize: 16
            color: Colors.red400
            Behavior on color { ColorAnimation { duration: PanelColors.transitionDuration } }
        }
    }

    mouseArea.onClicked: SessionState.mediaPopupVisible = !SessionState.mediaPopupVisible
}
