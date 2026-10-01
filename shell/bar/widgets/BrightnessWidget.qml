import QtQuick
import Quickshell
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.brightness

    // Optimistic scroll
    property int internalBrightness: BrightnessState.brightness

    Timer {
        id: wheelTimer
        interval: 400
    }

    readonly property int displayBrightness: wheelTimer.running ? internalBrightness : BrightnessState.brightness

    widestLabel: "󰃠 100%"
    label: {
        let ico
        if      (displayBrightness >= 86) ico = "󰃠 "
        else if (displayBrightness >= 72) ico = "󰃟 "
        else if (displayBrightness >= 57) ico = "󰃞 "
        else if (displayBrightness >= 43) ico = "󰃝 "
        else if (displayBrightness >= 29) ico = "󰃜 "
        else if (displayBrightness >= 14) ico = "󰃛 "
        else                              ico = "󰃚 "
        return ico + displayBrightness + "%"
    }

    mouseArea.onClicked: (mouse) => {
        if (BrightnessState.popupVisible) {
            BrightnessState.hide()
        } else {
            SessionState.closeAllPopups()
            BrightnessState.show()
        }
        mouse.accepted = false
    }

    mouseArea.onWheel: (wheel) => {
        let base = wheelTimer.running ? internalBrightness : BrightnessState.brightness
        let step = wheel.angleDelta.y > 0 ? 5 : -5
        let newLevel = Math.max(0, Math.min(100, base + step))

        internalBrightness = newLevel
        wheelTimer.restart()
        BrightnessState.setBrightness(newLevel)
    }
}
