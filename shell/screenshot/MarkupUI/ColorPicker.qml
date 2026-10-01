import QtQuick

PopupPanel {
    id: picker
    property real hue: 0
    property real sat: 1
    property real val: 1
    readonly property color current: Qt.hsva(hue / 360, sat, val, 1)
    signal edited(real h, real s, real v)
    signal focusReleased()

    width: 200
    spacing: 8

    ColorSlider {
        value: picker.hue / 360
        repaintOn: picker.current
        colorAt: t => Qt.hsva(t, 1, 1, 1)
        onMoved: v => picker.edited(v * 359.9, picker.sat, picker.val)
    }
    ColorSlider {
        value: picker.sat
        repaintOn: picker.current
        colorAt: t => Qt.hsva(picker.hue / 360, t, picker.val, 1)
        onMoved: v => picker.edited(picker.hue, v, picker.val)
    }
    ColorSlider {
        value: picker.val
        repaintOn: picker.current
        colorAt: t => Qt.hsva(picker.hue / 360, picker.sat, t, 1)
        onMoved: v => picker.edited(picker.hue, picker.sat, v)
    }
    Item {
        width: parent.width; height: 24
        Rectangle {
            id: swatch
            width: 20; radius: 4
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            color: picker.current
            border.color: "#666"; border.width: 1
        }
        Rectangle {
            anchors { left: swatch.right; right: parent.right; top: parent.top; bottom: parent.bottom; leftMargin: 8 }
            radius: 4
            color: "#2a2a2a"; border.color: "#555"; border.width: 1

            TextInput {
                id: hexInput
                anchors { fill: parent; margins: 4 }
                color: "#ccc"; font.pixelSize: 12
                verticalAlignment: TextInput.AlignVCenter
                Binding {
                    when: !hexInput.activeFocus
                    target: hexInput; property: "text"
                    value: picker.current.toString().toUpperCase()
                }
                onActiveFocusChanged: if (!activeFocus) picker.focusReleased()
                Keys.onReturnPressed: {
                    const c = Qt.color(text.startsWith("#") ? text : "#" + text)
                    if (c.valid)
                        picker.edited(c.hsvHue >= 0 ? c.hsvHue * 360 : picker.hue, c.hsvSaturation, c.hsvValue)
                    picker.focusReleased()
                }
                Keys.onEscapePressed: picker.focusReleased()
            }
        }
    }
}
