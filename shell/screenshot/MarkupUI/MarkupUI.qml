import QtQuick
import Quickshell
import Quickshell.Io as Io
import "../../theme"

FloatingWindow {
    id: markupWin
    visible: false
    title: "qs-markup"
    implicitWidth: 800
    implicitHeight: 600

    readonly property string defaultTool: "box"
    property string tool: defaultTool
    property int selectedShapeIndex: -1
    property real lineWidth: 2.5
    property bool showSizePicker: false
    property bool showHint: false
    property bool textInputActive: false
    property real textInputNX: 0
    property real textInputNY: 0
    property var shapes: []
    property var currentShape: null
    property bool showColorPicker: false
    property real pickerH: 0
    property real pickerS: 0.7333
    property real pickerV: 1
    readonly property color drawColor: Qt.hsva(pickerH / 360, pickerS, pickerV, 1)
    readonly property var toolKeys: ({
        [Qt.Key_B]: "box",
        [Qt.Key_P]: "pencil",
        [Qt.Key_F]: "fill",
        [Qt.Key_T]: "text",
        [Qt.Key_M]: "move"
    })

    readonly property bool popupOpen: showColorPicker || showSizePicker

    onToolChanged: selectedShapeIndex = -1

    function setTool(t) { tool = (tool === t) ? defaultTool : t }
    function selectedShape() { return selectedShapeIndex >= 0 ? shapes[selectedShapeIndex] : null }
    function dismissPopups() { showColorPicker = false; showSizePicker = false }

    function deleteSelected() {
        if (selectedShapeIndex < 0) return
        shapes.splice(selectedShapeIndex, 1)
        selectedShapeIndex = -1
        canvas.requestPaint()
    }

    function undo() {
        shapes.pop()
        if (selectedShapeIndex >= shapes.length) selectedShapeIndex = -1
        canvas.requestPaint()
    }
    
    function fontPx(lw) { return lw * 8 }

    function shapeBounds(s) {
        if (s.type === "text") {
            const fw = s.text.length * fontPx(s.lineWidth) * 0.6 / canvas.width
            return { minX: s.points[0].x, maxX: s.points[0].x + fw, minY: s.points[0].y - fontPx(s.lineWidth) / canvas.height, maxY: s.points[0].y }
        }
        const xs = s.points.map(p => p.x), ys = s.points.map(p => p.y)
        return { minX: Math.min(...xs), maxX: Math.max(...xs), minY: Math.min(...ys), maxY: Math.max(...ys) }
    }

    function hitTest(s, x, y) {
        const b = shapeBounds(s), pad = 0.02
        return x >= b.minX - pad && x <= b.maxX + pad && y >= b.minY - pad && y <= b.maxY + pad
    }

    function resizeShape(s, left, top, nx, ny, lastX, lastY) {
        switch (s.type) {
            case "text":
                s.lineWidth = Math.max(0.5, s.lineWidth + (top ? -1 : 1) * (ny - lastY) * canvas.height / 8)
                break
            case "rect":
                s.points[left ? 0 : 1].x = nx
                s.points[top ? 0 : 1].y = ny
                break
            default: {
                const b = shapeBounds(s)
                const anchorX = left ? b.maxX : b.minX, anchorY = top ? b.maxY : b.minY
                const scaleX = Math.abs(nx - anchorX) / Math.max(0.001, Math.abs(lastX - anchorX))
                const scaleY = Math.abs(ny - anchorY) / Math.max(0.001, Math.abs(lastY - anchorY))
                s.points.forEach(p => { p.x = anchorX + (p.x - anchorX) * scaleX; p.y = anchorY + (p.y - anchorY) * scaleY })
            }
        }
    }

    function createShape(t, x, y, col, lw) {
        if (t === "pencil") return { type: "pencil", points: [{ x, y }], color: col, lineWidth: lw }
        return { type: "rect", filled: t === "fill", points: [{ x, y }, { x, y }], color: col, lineWidth: lw }
    }

    function drawShape(ctx, s) {
        const w = canvas.width, h = canvas.height
        ctx.lineWidth = s.lineWidth
        ctx.strokeStyle = ctx.fillStyle = s.color
        switch (s.type) {
            case "text":
                ctx.font = `${Math.round(fontPx(s.lineWidth))}px '${PanelColors.monoFont}'`
                ctx.fillText(s.text, s.points[0].x * w, s.points[0].y * h)
                break
            case "rect": {
                const [a, b] = s.points
                if (s.filled) ctx.fillRect(a.x * w, a.y * h, (b.x - a.x) * w, (b.y - a.y) * h)
                else ctx.strokeRect(a.x * w, a.y * h, (b.x - a.x) * w, (b.y - a.y) * h)
                break
            }
            default:
                if (s.points.length < 2) return
                ctx.beginPath()
                s.points.forEach((p, i) => i ? ctx.lineTo(p.x * w, p.y * h) : ctx.moveTo(p.x * w, p.y * h))
                ctx.stroke()
        }
    }

    function drawSelection(ctx, s) {
        const w = canvas.width, h = canvas.height
        const b = shapeBounds(s)
        const bx = b.minX * w, by = b.minY * h, bw = (b.maxX - b.minX) * w, bh = (b.maxY - b.minY) * h
        ctx.save()
        ctx.setLineDash([6, 3]); ctx.strokeStyle = "white"; ctx.lineWidth = 1.5
        ctx.strokeRect(bx - 4, by - 4, bw + 8, bh + 8)
        ctx.setLineDash([]); ctx.fillStyle = "white"; ctx.strokeStyle = "#666"; ctx.lineWidth = 1
        for (const [hx, hy] of [[bx - 4, by - 4], [bx + bw + 4, by - 4], [bx - 4, by + bh + 4], [bx + bw + 4, by + bh + 4]]) {
            ctx.fillRect(hx - 4, hy - 4, 8, 8)
            ctx.strokeRect(hx - 4, hy - 4, 8, 8)
        }
        ctx.restore()
    }

    function open(w: int, h: int) {
        bgImg.source = "file:///tmp/qs-markup.png?" + Date.now()
        shapes = []; currentShape = null
        tool = defaultTool; selectedShapeIndex = -1; textInputActive = false
        dismissPopups(); showHint = false
        implicitWidth = w + 4; implicitHeight = h + 4
        visible = true
        rootItem.forceActiveFocus()
    }

    function close() {
        visible = false
        shapes = []; currentShape = null
        dismissPopups()
    }

    function copyToClipboard() {
        markupWin.selectedShapeIndex = -1
        canvas.requestPaint()
        bgImg.grabToImage(result => {
            result.saveToFile("/tmp/qs-markup.png")
            copyProc.running = false
            copyProc.command = ["sh", "-c", `
                wl-copy -t image/png < /tmp/qs-markup.png
                notify-send "Markup" "Copied to clipboard"
            `]
            copyProc.running = true
        })
    }

    Io.Process {
        id: copyProc
        running: false
        command: ["true"]
        onExited: markupWin.close()
    }

    Rectangle {
        anchors.fill: parent
        color: "#111111"
        border.color: PanelColors.launcher
        border.width: 2

        Item {
            id: rootItem
            anchors { fill: parent; margins: 2 }
            focus: true

            Keys.onPressed: ev => {
                const tool = markupWin.toolKeys[ev.key]
                if (tool) {
                    markupWin.setTool(tool)
                    return
                }
                switch (ev.key) {
                    case Qt.Key_Escape:
                        if (markupWin.popupOpen) markupWin.dismissPopups()
                        else markupWin.close()
                        break
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        markupWin.copyToClipboard()
                        break
                    case Qt.Key_Delete:
                    case Qt.Key_Backspace:
                        markupWin.deleteSelected()
                        break
                    case Qt.Key_Z:
                        if (ev.modifiers & Qt.ControlModifier) markupWin.undo()
                        break
                    case Qt.Key_C: markupWin.showColorPicker = !markupWin.showColorPicker; break
                    case Qt.Key_S: markupWin.showSizePicker = !markupWin.showSizePicker; break
                    case Qt.Key_H: markupWin.showHint = !markupWin.showHint; break
                }
            }

            Image {
                id: bgImg
                anchors.fill: parent
                cache: false
                smooth: false
                fillMode: Image.Stretch

                Canvas {
                    id: canvas
                    anchors.fill: parent

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.lineCap = "round"; ctx.lineJoin = "round"
                        for (const s of markupWin.shapes) markupWin.drawShape(ctx, s)
                        if (markupWin.currentShape) markupWin.drawShape(ctx, markupWin.currentShape)
                        const sel = markupWin.selectedShape()
                        if (sel) markupWin.drawSelection(ctx, sel)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.CrossCursor
                        property real dragLastX: 0
                        property real dragLastY: 0
                        property int resizeCorner: -1

                        onPressed: mouse => {
                            const nx = mouse.x / canvas.width, ny = mouse.y / canvas.height

                            if (markupWin.tool === "move") {
                                resizeCorner = -1
                                dragLastX = nx; dragLastY = ny
                                const sel = markupWin.selectedShape()
                                if (sel) {
                                    const b = markupWin.shapeBounds(sel)
                                    for (let i = 0; i < 4; i++) {
                                        const cornerX = i % 2 ? b.maxX : b.minX, cornerY = i < 2 ? b.minY : b.maxY
                                        if (Math.abs(nx - cornerX) < 12 / canvas.width && Math.abs(ny - cornerY) < 12 / canvas.height) {
                                            resizeCorner = i
                                            if (sel.type === "rect") sel.points = [{ x: b.minX, y: b.minY }, { x: b.maxX, y: b.maxY }]
                                            return
                                        }
                                    }
                                }
                                markupWin.selectedShapeIndex = -1
                                for (let i = markupWin.shapes.length - 1; i >= 0; i--)
                                    if (markupWin.hitTest(markupWin.shapes[i], nx, ny)) { markupWin.selectedShapeIndex = i; break }
                                canvas.requestPaint()
                                return
                            }

                            if (markupWin.tool === "text") {
                                markupTextInput.commit(false)
                                markupWin.textInputNX = nx; markupWin.textInputNY = ny
                                markupWin.textInputActive = true
                                markupTextInput.forceActiveFocus()
                                return
                            }

                            markupWin.currentShape = markupWin.createShape(markupWin.tool, nx, ny, markupWin.drawColor.toString(), markupWin.lineWidth)
                        }

                        onPositionChanged: mouse => {
                            const nx = mouse.x / canvas.width, ny = mouse.y / canvas.height

                            if (markupWin.tool === "move") {
                                const s = markupWin.selectedShape()
                                if (!s) return
                                if (resizeCorner >= 0)
                                    markupWin.resizeShape(s, resizeCorner % 2 === 0, resizeCorner < 2, nx, ny, dragLastX, dragLastY)
                                else
                                    s.points.forEach(p => { p.x += nx - dragLastX; p.y += ny - dragLastY })
                                dragLastX = nx; dragLastY = ny
                                canvas.requestPaint()
                                return
                            }

                            if (!markupWin.currentShape) return
                            if (markupWin.tool === "pencil") markupWin.currentShape.points.push({ x: nx, y: ny })
                            else markupWin.currentShape.points[1] = { x: nx, y: ny }
                            canvas.requestPaint()
                        }

                        onReleased: {
                            if (markupWin.tool === "move") { resizeCorner = -1; return }
                            if (!markupWin.currentShape) return
                            markupWin.shapes.push(markupWin.currentShape)
                            markupWin.currentShape = null
                            canvas.requestPaint()
                        }
                    }
                }

                TextInput {
                    id: markupTextInput
                    visible: markupWin.textInputActive
                    x: markupWin.textInputNX * parent.width
                    y: markupWin.textInputNY * parent.height - font.pixelSize
                    color: markupWin.drawColor
                    font.pixelSize: Math.round(markupWin.fontPx(markupWin.lineWidth))
                    z: 5

                    function commit(deactivate) {
                        if (text.length > 0) {
                            markupWin.shapes.push({ type: "text", points: [{ x: markupWin.textInputNX, y: markupWin.textInputNY }],
                                text: text, color: markupWin.drawColor.toString(), lineWidth: markupWin.lineWidth })
                            canvas.requestPaint()
                        }
                        text = ""
                        if (deactivate) { markupWin.textInputActive = false; rootItem.forceActiveFocus() }
                    }

                    Keys.onReturnPressed: commit(true)
                    Keys.onEscapePressed: { text = ""; commit(true) }
                    onActiveFocusChanged: if (!activeFocus && !markupWin.textInputActive) rootItem.forceActiveFocus()
                }
            }

            SizePicker {
                visible: markupWin.showSizePicker
                anchors { left: parent.left; top: parent.top; margins: 12 }
                lineWidth: markupWin.lineWidth
                previewColor: markupWin.drawColor
                onEdited: w => markupWin.lineWidth = w
            }

            ColorPicker {
                visible: markupWin.showColorPicker
                anchors { right: parent.right; top: parent.top; margins: 12 }
                hue: markupWin.pickerH
                sat: markupWin.pickerS
                val: markupWin.pickerV
                onEdited: (h, s, v) => {
                    markupWin.pickerH = h; markupWin.pickerS = s; markupWin.pickerV = v
                    const sel = markupWin.selectedShape()
                    if (sel) { sel.color = Qt.hsva(h / 360, s, v, 1).toString(); canvas.requestPaint() }
                }
                onFocusReleased: rootItem.forceActiveFocus()
            }

            Rectangle {
                visible: markupWin.showHint
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 10 }
                color: "#bb000000"; radius: 6
                width: hint.width + 20; height: hint.height + 10

                Text {
                    id: hint
                    anchors.centerIn: parent
                    text: "[" + markupWin.tool.charAt(0).toUpperCase() + markupWin.tool.slice(1) + "]  size: " + Math.round(markupWin.lineWidth) + "  B: box   P: pencil   F: fill   T: text   M: move   C: color   S: size   Ctrl+Z: undo   Enter: copy   Esc: cancel"
                    color: "#cccccc"; font.pixelSize: 12
                }
            }
        }
    }
}
