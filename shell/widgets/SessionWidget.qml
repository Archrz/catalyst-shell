import QtQuick
import qs.bar.widgets
import "../theme"

Pill {
    pillColor: PanelColors.error
    textColor: PanelColors.pillForeground
    label: ""

    mouseArea.onClicked: {
        if (SessionState.visible) {
            SessionState.hide()
        } else {
            SessionState.closeAllPopups()
            SessionState.show()
        }
    }
}
