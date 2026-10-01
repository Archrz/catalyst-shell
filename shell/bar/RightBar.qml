import QtQuick
import qs.bar.widgets
import qs.widgets

Row {
    spacing: 4

    property alias audioWidget: audioWidget
    property alias sessionWidget: sessionWidget
    property alias trayBar: trayBar
    property alias dateWidget: dateWidget
    property alias tailscaleWidget: tailscaleWidget

    TrayBar { id: trayBar; anchors.verticalCenter: parent.verticalCenter }
    Extras { anchors.verticalCenter: parent.verticalCenter }
    TailscaleWidget { id: tailscaleWidget; anchors.verticalCenter: parent.verticalCenter }
    AudioWidget { id: audioWidget; anchors.verticalCenter: parent.verticalCenter }
    DateWidget { id: dateWidget; anchors.verticalCenter: parent.verticalCenter }
    SessionWidget { id: sessionWidget; anchors.verticalCenter: parent.verticalCenter }
}
