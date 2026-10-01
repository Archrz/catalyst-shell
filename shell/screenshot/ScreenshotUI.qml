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

    property bool saveToDisk: false
    property bool isMarkup: false

    signal markupReady(int w, int h)

    property int markupW: 0
    property int markupH: 0

    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "qs-screenshot"
    exclusionMode: ExclusionMode.Ignore

    Io.Process {
        id: grabProc
        running: false
        command: ["true"]
        onExited: exitCode => {
            if (exitCode !== 0) return
            masterImg.source = "file:///tmp/qs-master.png?t=" + Date.now()
            visible = true
            selectArea.forceActiveFocus()
        }
    }

    function startCapture(toDisk: bool): void {
        saveToDisk = toDisk
        SessionState.closeAllPopups()
        SessionState.dashboardVisible = false
        visible = false
        grabProc.command = ["grim", "/tmp/qs-master.png"]
        grabProc.running = false
        grabProc.running = true
    }

    function startMarkup(): void {
        isMarkup = true
        startCapture(false)
    }

    function runMarkupCrop(geo: string, w: int, h: int): void {
        markupW = w
        markupH = h
        markupCropProc.running = false
        markupCropProc.command = ["sh", "-c", `
            test -f /tmp/qs-master.png || { notify-send "Screenshot failed" "No screen capture — try again"; exit 1; }
            magick /tmp/qs-master.png -crop ${geo} /tmp/qs-markup.png
        `]
        markupCropProc.running = true
    }

    function runCrop(geo: string, toDisk: bool): void {
        cropProc.running = false
        cropProc.command = toDisk
            ? ["sh", "-c", `
                test -f /tmp/qs-master.png || { notify-send "Screenshot failed" "No screen capture — try again"; exit 1; }
                mkdir -p "$HOME/Pictures/Screenshots"
                file="$HOME/Pictures/Screenshots/Screenshot From $(date +'%Y-%m-%d %H-%M-%S').png"
                magick /tmp/qs-master.png -crop ${geo} "$file"
                notify-send "Screenshot" "Saved to Pictures/Screenshots"
            `]
            : ["sh", "-c", `
                test -f /tmp/qs-master.png || { notify-send "Screenshot failed" "No screen capture — try again"; exit 1; }
                magick /tmp/qs-master.png -crop ${geo} png:- | wl-copy -t image/png
                notify-send "Screenshot" "Copied to clipboard"
            `]
        cropProc.running = true
    }

    Io.IpcHandler {
        target: "screenshot"
        function capture(): void { win.startCapture(false) }
        function captureSave(): void { win.startCapture(true) }
        function captureMarkup(): void { win.startMarkup() }
    }

    function closeOverlay() {
        visible = false
        saveToDisk = false
        isMarkup = false
        selectArea.isDragging = false
        selectArea.startX = 0; selectArea.curX = 0
        selectArea.startY = 0; selectArea.curY = 0
    }

    Item {
        id: selectArea
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.closeOverlay()

        Image {
            id: masterImg
            anchors.fill: parent
            fillMode: Image.Stretch
            smooth: false
            cache: false

            Rectangle {
                anchors.fill: parent
                color: "#99000000"
            }
        }

        property int startX: 0
        property int startY: 0
        property int curX: 0
        property int curY: 0
        property bool isDragging: false

        readonly property int selX: Math.min(startX, curX)
        readonly property int selY: Math.min(startY, curY)
        readonly property int selW: Math.abs(curX - startX) + 1
        readonly property int selH: Math.abs(curY - startY) + 1

        Rectangle {
            visible: selectArea.isDragging || selectArea.selW > 0
            x: selectArea.selX
            y: selectArea.selY
            width: selectArea.selW
            height: selectArea.selH
            color: "#2280cbc4"
            border.color: PanelColors.launcher
            border.width: 2

            Item {
                anchors.fill: parent
                anchors.margins: 2
                clip: true
                Image {
                    source: masterImg.source
                    x: -parent.parent.x - 2
                    y: -parent.parent.y - 2
                    width: masterImg.width
                    height: masterImg.height
                    fillMode: Image.Stretch
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onPressed: mouse => {
                if (mouse.button === Qt.RightButton) {
                    win.closeOverlay()
                    return
                }
                selectArea.startX = mouse.x
                selectArea.startY = mouse.y
                selectArea.curX = mouse.x
                selectArea.curY = mouse.y
                selectArea.isDragging = true
            }

            onPositionChanged: mouse => {
                if (!selectArea.isDragging) return
                selectArea.curX = mouse.x
                selectArea.curY = mouse.y
            }

            onReleased: mouse => {
                if (mouse.button === Qt.RightButton) return
                selectArea.isDragging = false
                if (selectArea.selW <= 5 || selectArea.selH <= 5) { win.closeOverlay(); return }
                const geo = `${selectArea.selW}x${selectArea.selH}+${win.screen.x + selectArea.selX}+${win.screen.y + selectArea.selY}`
                win.visible = false
                if (win.isMarkup) { win.runMarkupCrop(geo, selectArea.selW, selectArea.selH); return }
                win.runCrop(geo, win.saveToDisk)
            }
        }
    }

    Io.Process {
        id: cropProc
        running: false
        command: ["true"]
        onExited: win.closeOverlay()
    }

    Io.Process {
        id: markupCropProc
        running: false
        command: ["true"]
        onExited: exitCode => {
            win.closeOverlay()
            if (exitCode === 0) win.markupReady(win.markupW, win.markupH)
        }
    }
}
