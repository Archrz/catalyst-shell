import QtQuick
import "../theme"

SectionBase {
    id: statsSection
    width: parent.width
    implicitHeight: statRow.height

    Row {
        id: statRow
        width: parent.width
        spacing: (width - (cpuRing.width * 3)) / 2

        StatRing {
            id: cpuRing
            label: "CPU"; icon: ""; value: SystemStatsState.cpuUsage; color: PanelColors.cpuRing
        }
        StatRing {
            id: ramRing
            label: "RAM"; icon: ""; value: SystemStatsState.ramUsage; color: PanelColors.ramRing
        }
        StatRing {
            id: gpuRing
            label: "GPU"; icon: "󰢮"; value: SystemStatsState.gpuUsage; color: PanelColors.gpuRing
        }
    }
}
