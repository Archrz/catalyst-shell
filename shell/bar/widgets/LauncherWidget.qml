import QtQuick
import Quickshell
import "../../theme"

Pill {
    id: root
    pillColor: PanelColors.dashboard
    textColor: PanelColors.textMain

    label: "󰖔"

    mouseArea.onClicked: {
        if (SessionState.dashboardVisible) {
            SessionState.dashboardVisible = false
        } else {
            SessionState.dashboardVisible = true
        }
    }
}
