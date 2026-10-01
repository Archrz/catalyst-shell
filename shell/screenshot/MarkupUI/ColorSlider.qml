import QtQuick

SliderTrack {
    id: slider
    property var colorAt
    property color repaintOn
    color: "transparent"
    onRepaintOnChanged: gradientCanvas.requestPaint()

    Canvas {
        id: gradientCanvas
        anchors.fill: parent; z: -1
        onPaint: {
            const ctx = getContext("2d")
            const grad = ctx.createLinearGradient(0, 0, width, 0)
            for (let i = 0; i <= 16; i++) grad.addColorStop(i / 16, String(slider.colorAt(i / 16)))
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = grad
            ctx.beginPath()
            ctx.roundedRect(0, 0, width, height, 10, 10)
            ctx.fill()
        }
    }
}
