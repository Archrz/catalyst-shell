import QtQuick
import Quickshell
import Quickshell.Io as Io
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: win
    visible: false
    color: "transparent"
    screen: Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "qs-colorpicker"
    exclusionMode: ExclusionMode.Ignore

    property string hexColor: "888888"
    property int zoom: 8
    property int magSize: 160
    property bool mouseTracked: false

    readonly property real scaleX: bgImg.sourceSize.width > 0 ? bgImg.sourceSize.width / win.width : 1
    readonly property real scaleY: bgImg.sourceSize.height > 0 ? bgImg.sourceSize.height / win.height : 1

    Io.Process {
        id: grabProc
        running: false
        command: ["true"]
        onExited: exitCode => {
            running = false
            if (exitCode !== 0) return
            const url = "file:///tmp/qs-colorpicker.png?" + Date.now()
            bgImg.source = url
            colorCanvas.load(url)
            magCanvas.load(url)
        }
    }

    Io.IpcHandler {
        target: "colorpicker"
        function pick(): void {
            grabProc.command = ["grim", "/tmp/qs-colorpicker.png"]
            grabProc.running = false
            grabProc.running = true
        }
    }

    function close() { visible = false; mouseTracked = false }

    Image {
        id: bgImg
        anchors.fill: parent
        fillMode: Image.Stretch
        smooth: false
        cache: false
    }

    Rectangle {
        anchors.fill: parent
        color: "#55000000"
    }

    // Pixel sampler
    Canvas {
        id: colorCanvas
        anchors.fill: parent
        z: -1

        property string imgSrc: ""
        property bool ready: false

        function load(url) {
            imgSrc = url
            ready = false
            loadImage(url)
        }

        onImageLoaded: {
            requestPaint()
            win.visible = true
            mouseArea.forceActiveFocus()
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.drawImage(imgSrc, 0, 0, width, height)
            ready = true
        }

        function hexAt(x, y) {
            if (!ready) return win.hexColor
            var ctx = getContext("2d")
            var d = ctx.getImageData(x, y, 1, 1).data
            return ("000000" + ((d[0] << 16) | (d[1] << 8) | d[2]).toString(16)).slice(-6).toUpperCase()
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        focus: true
        cursorShape: Qt.BlankCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        Keys.onEscapePressed: win.close()

        onPositionChanged: {
            win.mouseTracked = true
            win.hexColor = colorCanvas.hexAt(mouseX, mouseY)
            magCanvas.requestPaint()
        }

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) { win.close(); return }
            const hex = win.hexColor
            copyProc.command = ["sh", "-c",
                `printf '%s' '#${hex}' | wl-copy; notify-send -t 2000 "Color picked" "#${hex}"`
            ]
            copyProc.running = false
            copyProc.running = true
            win.close()
        }
    }

    Io.Process {
        id: copyProc
        running: false
        command: ["true"]
        onExited: () => { running = false }
    }

    Item {
        x: mouseArea.mouseX - win.magSize / 2
        y: mouseArea.mouseY - win.magSize / 2
        width: win.magSize
        height: win.magSize
        enabled: false
        visible: win.mouseTracked

        // Magnifier
        Canvas {
            id: magCanvas
            width: win.magSize
            height: win.magSize

            property string imgSrc: ""

            function load(url) {
                imgSrc = url
                loadImage(url)
            }

            onImageLoaded: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (!imgSrc) return

                var r = width / 2
                var physX = mouseArea.mouseX * win.scaleX
                var physY = mouseArea.mouseY * win.scaleY
                var srcW = width / win.zoom
                var srcH = height / win.zoom

                ctx.save()
                ctx.beginPath()
                ctx.arc(r, r, r, 0, Math.PI * 2)
                ctx.clip()

                ctx.drawImage(imgSrc,
                    physX - srcW / 2, physY - srcH / 2, srcW, srcH,
                    0, 0, width, height)

                // Crosshair
                ctx.strokeStyle = "rgba(255,255,255,0.5)"
                ctx.lineWidth = 1
                ctx.beginPath(); ctx.moveTo(0, r); ctx.lineTo(width, r); ctx.stroke()
                ctx.beginPath(); ctx.moveTo(r, 0); ctx.lineTo(r, height); ctx.stroke()

                ctx.restore()

                // Border ring
                ctx.beginPath()
                ctx.arc(r, r, r - 2, 0, Math.PI * 2)
                ctx.strokeStyle = "#" + win.hexColor
                ctx.lineWidth = 3
                ctx.stroke()
            }
        }

        Rectangle {
            anchors.top: magCanvas.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: hexText.implicitWidth + 14
            height: hexText.implicitHeight + 8
            radius: 4
            color: "#" + win.hexColor

            Text {
                id: hexText
                anchors.centerIn: parent
                text: "#" + win.hexColor
                font.family: PanelColors.monoFont
                font.pixelSize: 13
                color: {
                    var h = win.hexColor
                    var r = parseInt(h.substring(0, 2), 16) / 255
                    var g = parseInt(h.substring(2, 4), 16) / 255
                    var b = parseInt(h.substring(4, 6), 16) / 255
                    return (r * 0.299 + g * 0.587 + b * 0.114) > 0.5 ? "#000000" : "#ffffff"
                }
            }
        }
    }
}
