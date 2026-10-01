import QtQuick
import "../../theme"

Pill {
    id: root

    // Optimistic scroll
    property int internalVolume: AudioState.volume

    Timer {
        id: wheelTimer
        interval: 400
    }

    readonly property int displayVolume: wheelTimer.running ? internalVolume : AudioState.volume
    readonly property bool isEffectivelyMuted: AudioState.muted || displayVolume === 0

    pillColor: isEffectivelyMuted ? PanelColors.rowBackground : PanelColors.audio
    textColor: isEffectivelyMuted ? PanelColors.textMain : PanelColors.pillForeground

    widestLabel: "󰕾 100%"
    label: {
        if (isEffectivelyMuted) return "󰝟 Muted"
        let ico = "󰕿"
        if (displayVolume >= 66) ico = "󰕾"
        else if (displayVolume >= 33) ico = "󰖀"
        return ico + " " + displayVolume + "%"
    }

    mouseArea.onClicked: AudioState.popupVisible ? AudioState.hide() : AudioState.show()

    mouseArea.onWheel: (wheel) => {
        var base = wheelTimer.running ? internalVolume : AudioState.volume
        var newVol = wheel.angleDelta.y > 0
            ? Math.min(100, base + 5)
            : Math.max(0, base - 5)

        internalVolume = newVol
        wheelTimer.restart()
        AudioState.setVolume(newVol)
    }
}
