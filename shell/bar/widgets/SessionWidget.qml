import QtQuick
import "../../theme"

Pill {
    pillColor: PanelColors.error
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
