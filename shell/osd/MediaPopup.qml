import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../theme"

PopupBase {
    id: root

    readonly property int contentCardWidth: 300

    // Layout
    readonly property int arrowWidth: 36
    readonly property int arrowGap:   6
    readonly property int arrowOffset: arrowWidth + arrowGap

    implicitWidth: contentCardWidth + arrowOffset * 2

    showDefaultBackground: false

    borderColor:   PanelColors.clock
    clipContent:   false
    contentHeight: popupColumn.implicitHeight

    // Metadata
    function getCleanMetadata(rawTitle, rawArtist) {
        let t = (rawTitle || "").replace(/\s*-\s*YouTube$/, "")
                                 .replace(/\s*-\s*Mozilla Firefox$/, "")
                                 .replace(/\s*-\s*Zen Browser$/, "")
                                 .trim();
        let a = (rawArtist || "").trim();

        if (a === "" && t.includes(" - ")) {
            const parts = t.split(" - ");
            a = parts[0].trim();
            t = parts.slice(1).join(" - ").trim();
        }

        return { title: t, artist: a };
    }

    function getPlayerIcon(identity) {
        const id = (identity || "").toLowerCase();
        if (id.includes("spotify")) return "󰓇";
        if (id.includes("firefox")) return "󰈹";
        if (id.includes("zen"))     return "󰈹";
        if (id.includes("chrome"))  return "󰊯";
        if (id.includes("vlc"))     return "󰕼";
        return "󰎆";
    }

    Connections {
        target: SessionState
        function onMediaPopupVisibleChanged() {
            root.animState = SessionState.mediaPopupVisible ? "open" : "closing"
        }
    }

    // Player list
    readonly property var playerList: {
        const result = []
        const vals = Mpris.players.values
        for (let i = 0; i < vals.length; i++) {
            const p = vals[i]
            if (p && (p.trackTitle ?? "") !== "") result.push(p)
        }
        return result
    }

    property int selectedIndex: 0

    onPlayerListChanged: {
        if (root.playerList.length === 0)
            root.selectedIndex = 0
        else if (root.selectedIndex >= root.playerList.length)
            root.selectedIndex = root.playerList.length - 1
    }

    readonly property MprisPlayer activePlayer: {
        if (root.playerList.length === 0) return null
        const sel = root.playerList[root.selectedIndex]
        if (sel) return sel
        for (let i = 0; i < root.playerList.length; i++) {
            if (root.playerList[i].playbackState === MprisPlaybackState.Playing)
                return root.playerList[i]
        }
        return root.playerList[0]
    }

    // MPRIS length
    property real _stableLength: 0

    onActivePlayerChanged: {
        const idx = root.playerList.indexOf(root.activePlayer)
        if (idx !== -1) root.selectedIndex = idx
        root.userSeeking = false
        root._playerSwitching = true
        root._stableLength = root.activePlayer?.length ?? 0
        root.livePosition = root.activePlayer?.position ?? 0
        playerSwitchSettleTimer.restart()
        root._crossfadeText()        // show cached metadata now
        metaSettleTimer.restart()    // re-check after metadata settles
    }

    Connections {
        target: root.activePlayer
        function onLengthChanged() {
            const newLen = root.activePlayer?.length ?? 0
            if (newLen <= 0) return

            // Browsers report length ≈ position; reject within 2s of playhead
            const pos = root.livePosition
            if (Math.abs(newLen - pos) < 2) return

            // Never shrink mid-track (reset on track/player change)
            if (root._stableLength <= 0 || newLen >= root._stableLength)
                root._stableLength = newLen
        }
    }

    // Player switch settle
    property bool _playerSwitching: false
    Timer {
        id: playerSwitchSettleTimer
        interval: 150
        onTriggered: root._playerSwitching = false
    }

    // Metadata settle — browsers mutate title/artist without onTrackChanged
    Timer {
        id: metaSettleTimer
        interval: 120
        onTriggered: root._crossfadeText()
    }

    Connections {
        target: root.activePlayer
        function onTrackTitleChanged()  { metaSettleTimer.restart() }
        function onTrackArtistChanged() { metaSettleTimer.restart() }
    }

    // Live streams — INT64_MAX µs sentinel exceeds 1 year in seconds
    readonly property int _liveStreamThreshold: 86400 * 365
    readonly property bool isLiveStream: (root._stableLength <= 0 || root._stableLength > root._liveStreamThreshold) && !root._playerSwitching

    // Text crossfade state
    property bool _textShowA: true

    function _crossfadeText() {
        const meta = root.getCleanMetadata(
            root.activePlayer?.trackTitle,
            root.activePlayer?.trackArtist
        );

        let id = root.activePlayer?.identity ?? "";
        const idLow = id.toLowerCase();
        if (idLow.includes("firefox"))       id = "Firefox";
        else if (idLow.includes("zen"))      id = "Zen";
        else if (idLow.includes("chrome"))   id = "Chrome";
        else if (idLow.includes("spotify"))  id = "Spotify";

        const newTitle  = meta.title  || "Unknown Title";
        const newArtist = meta.artist || "Unknown Artist";

        const cur = _textShowA ? textSlotA : textSlotB;
        if (cur.title === newTitle && cur.artist === newArtist && cur.identity === id) return;

        if (_textShowA) {
            textSlotB.title    = newTitle;
            textSlotB.artist   = newArtist;
            textSlotB.identity = id;
        } else {
            textSlotA.title    = newTitle;
            textSlotA.artist   = newArtist;
            textSlotA.identity = id;
        }
        _textShowA = !_textShowA
    }

    Connections {
        target: root.activePlayer
        function onTrackChanged() {
            root.livePosition = 0
            root._stableLength = root.activePlayer?.length ?? 0
            metaSettleTimer.restart()
        }
    }

    readonly property bool isPlaying:   activePlayer?.playbackState === MprisPlaybackState.Playing
    readonly property bool hasContent:  activePlayer !== null
    readonly property bool multiPlayer: root.playerList.length > 1

    property real livePosition: activePlayer?.position ?? 0
    property bool userSeeking:  false

    Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying && !root.userSeeking
        onTriggered: {
            if (root.activePlayer) {
                const pos = root.activePlayer.position
                if (pos === 0 && root.livePosition > 1) return;
                root.livePosition = pos
            }
        }
    }

    function fmtTime(secs) {
        if (!secs || secs < 0) return "0:00"
        const s = Math.floor(secs)
        const m = Math.floor(s / 60)
        const rem = s % 60
        return m + ":" + (rem < 10 ? "0" + rem : rem)
    }

    Rectangle {
        id: contentCard
        x: root.arrowOffset
        width: root.contentCardWidth
        anchors.verticalCenter: parent.verticalCenter
        height: popupColumn.implicitHeight + (root.padding * 2)

        color: PanelColors.popupBackground
        border.color: root.borderColor
        border.width: 2
        radius: 10

        Column {
            id: popupColumn
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: root.padding }
            spacing: 12

            Text {
                visible: !root.hasContent
                width: parent.width
                text: "No active media session"
                font.pixelSize: 13
                font.family: PanelColors.monoFont
                color: PanelColors.textDim
                horizontalAlignment: Text.AlignHCenter
                topPadding: 8
                bottomPadding: 8
            }

            Row {
                visible: root.hasContent
                width: parent.width
                spacing: 12

                Item {
                    id: artContainer
                    width: 64
                    height: 64

                    property string _urlA: ""
                    property string _urlB: ""
                    property bool   _showA: true

                    Component.onCompleted: Qt.callLater(() => {
                        _switchArt(root.activePlayer?.trackArtUrl ?? "")
                    })

                    function _switchArt(newUrl) {
                        if (_showA) {
                            _urlB = newUrl
                            _showA = false
                        } else {
                            _urlA = newUrl
                            _showA = true
                        }
                    }

                    Connections {
                        target: root
                        function onActivePlayerChanged() {
                            artContainer._switchArt(root.activePlayer?.trackArtUrl ?? "")
                        }
                    }

                    Connections {
                        target: root.activePlayer
                        function onTrackArtUrlChanged() {
                            artContainer._switchArt(root.activePlayer?.trackArtUrl ?? "")
                        }
                    }

                    Image {
                        id: artImageB
                        anchors.fill: parent
                        anchors.margins: 2
                        source: artContainer._urlB
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        mipmap: true
                        smooth: true
                        opacity: artContainer._showA ? 0.0 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.InOutSine } }
                        visible: opacity > 0
                    }

                    Image {
                        id: artImageA
                        anchors.fill: parent
                        anchors.margins: 2
                        source: artContainer._urlA
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        mipmap: true
                        smooth: true
                        opacity: artContainer._showA ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.InOutSine } }
                        visible: opacity > 0
                    }

                    Text {
                        visible: artImageA.status !== Image.Ready && artImageB.status !== Image.Ready
                        anchors.centerIn: parent
                        text: ""
                        font.pixelSize: 24
                        font.family: PanelColors.monoFont
                        color: PanelColors.textDim
                        z: 1
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 2
                        border.color: PanelColors.clock
                        radius: 4
                    }
                }

                Item {
                    id: textStack
                    width: parent.width - artContainer.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    height: root._textShowA ? textSlotA.implicitHeight : textSlotB.implicitHeight

                    component TextSlot: Column {
                        id: slot
                        property string title:    ""
                        property string artist:   ""
                        property string identity: ""
                        width: parent.width
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 20
                            clip: true
                            Text {
                                id: slotTitle
                                text: slot.title || "Unknown Title"
                                font.pixelSize: 15
                                font.bold: true
                                font.family: PanelColors.monoFont
                                color: PanelColors.textAccent
                                readonly property bool overflow: implicitWidth > parent.width
                                onOverflowChanged: { slotMarquee.stop(); slotTitle.x = 0; if (overflow) slotMarquee.start() }
                                onTextChanged:     { slotMarquee.stop(); slotTitle.x = 0; if (overflow) slotMarquee.start() }
                                SequentialAnimation {
                                    id: slotMarquee
                                    running: false; loops: Animation.Infinite
                                    PauseAnimation { duration: 1200 }
                                    NumberAnimation { target: slotTitle; property: "x"; from: 0; to: -slotTitle.implicitWidth; duration: slotTitle.implicitWidth * 14; easing.type: Easing.Linear }
                                    PropertyAction  { target: slotTitle; property: "x"; value: slotTitle.parent.width }
                                    NumberAnimation { target: slotTitle; property: "x"; from: slotTitle.parent.width; to: 0; duration: slotTitle.implicitWidth * 10; easing.type: Easing.Linear }
                                    PauseAnimation { duration: 1200 }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: slot.artist || "Unknown Artist"
                            font.pixelSize: 12
                            font.family: PanelColors.monoFont
                            color: PanelColors.textDim
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            visible: slot.identity !== ""
                            height: 18
                            width: slotPillRow.implicitWidth + 12
                            radius: height / 2
                            color: Qt.rgba(PanelColors.clock.r, PanelColors.clock.g, PanelColors.clock.b, 0.15)
                            Row {
                                id: slotPillRow
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: root.getPlayerIcon(slot.identity)
                                    font.pixelSize: 10; font.family: PanelColors.monoFont
                                    color: PanelColors.textAccent
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: slot.identity
                                    font.pixelSize: 9; font.bold: true; font.family: PanelColors.monoFont
                                    color: PanelColors.textAccent
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    TextSlot {
                        id: textSlotA
                        opacity: root._textShowA ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.InOutSine } }
                    }

                    TextSlot {
                        id: textSlotB
                        opacity: root._textShowA ? 0.0 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.InOutSine } }
                    }
                }
            }

            Column {
                visible: root.hasContent && (root.activePlayer?.positionSupported ?? false)
                width: parent.width
                spacing: 4

                WaveBar {
                    id: waveBar
                    width: parent.width
                    accentColor: PanelColors.clock
                    from: 0
                    to: root.isLiveStream ? 1 : Math.max(1, root._stableLength)
                    value: root.isLiveStream ? 1.0 : Math.min(root.livePosition, Math.max(1, root._stableLength))
                    playing: root.isPlaying
                    forceNoNeedle: root.isLiveStream
                    seekable: !root.isLiveStream && (root.activePlayer?.canSeek ?? false)
                    onSeeked: (v) => {
                        root.userSeeking = true
                        const targetPos = Math.max(0, Math.min(v, root._stableLength))
                        root.activePlayer.position = targetPos
                        root.livePosition = targetPos
                        seekReleaseTimer.restart()
                    }
                }

                Timer {
                    id: seekReleaseTimer
                    interval: 1200
                    onTriggered: root.userSeeking = false
                }

                Row {
                    width: parent.width
                    Text {
                        id: posLeft
                        text: root.isLiveStream ? "Live" : root.fmtTime(root.livePosition)
                        font.pixelSize: 11
                        font.family: PanelColors.monoFont
                        color: PanelColors.textDim
                    }
                    Item { width: parent.width - posLeft.implicitWidth - posRight.implicitWidth; height: 1 }
                    Text {
                        id: posRight
                        text: root.isLiveStream ? "∞" : root.fmtTime(root._stableLength)
                        font.pixelSize: 11
                        font.family: PanelColors.monoFont
                        color: PanelColors.textDim
                    }
                }
            }

            Item {
                visible: root.hasContent
                width: parent.width
                height: playPauseBtn.height

                MediaButton {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: (root.activePlayer?.shuffleSupported ?? false) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutSine } }
                    visible: opacity > 0
                    icon: ""
                    accentColor: PanelColors.clock
                    highlighted: root.activePlayer?.shuffle ?? false
                    onClicked: {
                        if (root.activePlayer)
                            root.activePlayer.shuffle = !(root.activePlayer.shuffle ?? false)
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 4

                    MediaButton {
                        icon: ""; accentColor: PanelColors.clock
                        enabled: root.activePlayer?.canGoPrevious ?? false
                        opacity: enabled ? 1.0 : 0.45
                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutSine } }
                        onClicked: root.activePlayer?.previous()
                    }
                    MediaButton {
                        id: playPauseBtn
                        icon: root.isPlaying ? "" : ""
                        highlighted: true
                        accentColor: PanelColors.clock
                        enabled: root.isPlaying
                            ? (root.activePlayer?.canPause ?? false)
                            : (root.activePlayer?.canPlay ?? false)
                        onClicked: root.isPlaying ? root.activePlayer?.pause() : root.activePlayer?.play()
                    }
                    MediaButton {
                        icon: ""; accentColor: PanelColors.clock
                        enabled: root.activePlayer?.canGoNext ?? false
                        opacity: enabled ? 1.0 : 0.45
                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutSine } }
                        onClicked: root.activePlayer?.next()
                    }
                }

                MediaButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: (root.activePlayer?.loopSupported ?? false) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutSine } }
                    visible: opacity > 0
                    icon: (root.activePlayer?.loopState ?? MprisLoopState.None) === MprisLoopState.Track ? "" : ""
                    accentColor: PanelColors.clock
                    highlighted: (root.activePlayer?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                    onClicked: {
                        if (!root.activePlayer) return
                        const s = root.activePlayer.loopState ?? MprisLoopState.None
                        if (s === MprisLoopState.None)           root.activePlayer.loopState = MprisLoopState.Playlist
                        else if (s === MprisLoopState.Playlist)  root.activePlayer.loopState = MprisLoopState.Track
                        else                                     root.activePlayer.loopState = MprisLoopState.None
                    }
                }
            }
        }
    }

    // Arrow buttons
    PlayerNavButton {
        visible: root.multiPlayer
        icon: ""
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        accentColor: PanelColors.clock
        onClicked: root.selectedIndex = (root.selectedIndex - 1 + root.playerList.length) % root.playerList.length
    }

    PlayerNavButton {
        visible: root.multiPlayer
        icon: ""
        x: contentCard.x + contentCard.width + root.arrowGap
        anchors.verticalCenter: parent.verticalCenter
        accentColor: PanelColors.clock
        onClicked: root.selectedIndex = (root.selectedIndex + 1) % root.playerList.length
    }

    // Components

    component PlayerNavButton: Rectangle {
        id: navBtn
        property string icon: ""
        property color accentColor: PanelColors.clock
        signal clicked()
        width: 36; height: 36; radius: 10
        color: navMouse.containsMouse ? Qt.lighter(PanelColors.rowBackground, 1.3) : PanelColors.rowBackground
        border.color: PanelColors.border
        border.width: 2
        scale: navMouse.pressed ? 0.88 : 1.0
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        Text {
            anchors.centerIn: parent
            text: navBtn.icon
            font.pixelSize: 16
            font.family: PanelColors.monoFont
            color: navMouse.containsMouse ? navBtn.accentColor : PanelColors.textMain
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
            id: navMouse
            anchors.fill: parent; hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: navBtn.clicked()
        }
    }

    component WaveBar: Item {
        id: bar
        property real value: 0
        property real from: 0
        property real to: 100
        property color accentColor: PanelColors.clock
        property bool playing: false
        property bool seekable: true
        property bool forceNoNeedle: false
        signal seeked(real value)
        implicitWidth: 120
        implicitHeight: 32
        property bool dragging: barMouse.pressed
        property real internalValue: 0
        readonly property bool activeInteraction: dragging
        readonly property bool isNeedle: !forceNoNeedle && (activeInteraction || playing)
        readonly property bool hovered: barMouse.containsMouse || barMouse.pressed
        readonly property real targetValue: activeInteraction ? internalValue : value
        // animValue is declarative — never assign imperatively
        property real animValue: targetValue
        Behavior on animValue {
            enabled: !bar.dragging
            NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
        }
        readonly property real _fillWidth: ((bar.animValue - bar.from) / (bar.to - bar.from)) * bar.width
        function _updateFromMouse(mouseX) {
            var newVal = Math.max(bar.from, Math.min(bar.to, bar.from + (mouseX / bar.width) * (bar.to - bar.from)))
            bar.internalValue = newVal;
            bar.seeked(newVal)
        }
        property real _phase: 0
        NumberAnimation on _phase { from: 0; to: Math.PI * 2; duration: 1200; loops: Animation.Infinite; running: bar.playing && !bar.activeInteraction }
        property real _waveAmount: 0.0
        Behavior on _waveAmount { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
        onPlayingChanged: _waveAmount = (playing && !activeInteraction) ? 1.0 : 0.0
        onActiveInteractionChanged: _waveAmount = (playing && !activeInteraction) ? 1.0 : 0.0

        property color _strokeColor: hovered ? Qt.lighter(bar.accentColor, 1.15) : bar.accentColor
        Behavior on _strokeColor { ColorAnimation { duration: 150 } }

        Rectangle {
            x: Math.max(0, bar._fillWidth - 3)
            width: Math.max(0, parent.width - x - 3); height: 6; radius: 3
            anchors.verticalCenter: parent.verticalCenter
            color: bar.hovered ? Qt.rgba(PanelColors.trackBackground.r, PanelColors.trackBackground.g, PanelColors.trackBackground.b, 0.4) : Qt.lighter(PanelColors.trackBackground, 1.1)
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        Canvas {
            id: waveCanvas
            anchors.fill: parent; antialiasing: true
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (bar._fillWidth <= 0) return
                const cy = height / 2; const amp = 3.5 * bar._waveAmount; const freq = 0.16
                ctx.beginPath(); ctx.lineWidth = 6; ctx.lineCap = "round"
                ctx.strokeStyle = bar._strokeColor
                const startX = 3
                const endX = Math.min(bar._fillWidth, width - 3)
                if (bar._waveAmount > 0) {
                    for (let x = startX; x <= endX; x++) {
                        const y = cy + Math.sin(x * freq + bar._phase) * amp
                        if (x === startX) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                    }
                } else { ctx.moveTo(startX, cy); ctx.lineTo(endX, cy) }
                ctx.stroke()
            }
            Connections {
                target: bar
                function onAnimValueChanged()    { waveCanvas.requestPaint() }
                function on_PhaseChanged()       { waveCanvas.requestPaint() }
                function on_WaveAmountChanged()  { waveCanvas.requestPaint() }
                function onHoveredChanged()      { waveCanvas.requestPaint() }
                function on_StrokeColorChanged() { waveCanvas.requestPaint() }
            }
        }
        Item {
            width: 0; height: 0; anchors.verticalCenter: parent.verticalCenter; x: bar._fillWidth
            opacity: bar.forceNoNeedle ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutSine } }
            Rectangle {
                anchors.centerIn: parent
                width: bar.isNeedle ? 6 : (bar.hovered ? 18 : 14)
                height: bar.isNeedle ? 24 : (bar.hovered ? 18 : 14)
                radius: width / 2
                color: bar.hovered ? Qt.lighter(bar.accentColor, 1.15) : bar.accentColor
                Behavior on width  { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                Behavior on color  { ColorAnimation { duration: 150 } }
            }
        }
        MouseArea {
            id: barMouse; anchors.fill: parent; hoverEnabled: true; enabled: bar.seekable
            property bool _hasDragged: false
            onPressed: (mouse) => { bar.internalValue = bar.animValue; _hasDragged = false }
            onPositionChanged: (mouse) => { if (pressed) { _hasDragged = true; bar._updateFromMouse(mouse.x) } }
            onClicked: (mouse) => { if (!_hasDragged) bar._updateFromMouse(mouse.x) }
        }
    }

    component MediaButton: Rectangle {
        id: btn
        property string icon: ""
        property bool highlighted: false
        property color accentColor: PanelColors.clock
        property bool enabled: true
        signal clicked()
        width: 40; height: 40; radius: 8
        color: {
            if (!enabled) return Qt.rgba(PanelColors.rowBackground.r, PanelColors.rowBackground.g, PanelColors.rowBackground.b, 0.35)
            if (highlighted) return btnMouse.containsMouse ? Qt.lighter(accentColor, 1.1) : accentColor
            return btnMouse.containsMouse ? Qt.lighter(PanelColors.rowBackground, 1.25) : PanelColors.rowBackground
        }
        border.color: highlighted ? "transparent" : Qt.rgba(1, 1, 1, btnMouse.containsMouse ? 0.10 : 0.04)
        border.width: 1
        scale: btnMouse.pressed ? 0.91 : 1.0
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        Text {
            anchors.centerIn: parent; text: btn.icon
            font.pixelSize: 18; font.family: PanelColors.monoFont
            color: {
                if (!btn.enabled)    return PanelColors.textDim
                if (btn.highlighted) return PanelColors.pillForeground
                return btnMouse.containsMouse ? PanelColors.textAccent : PanelColors.textMain
            }
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        MouseArea {
            id: btnMouse; anchors.fill: parent; hoverEnabled: true; enabled: btn.enabled
            cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked()
        }
    }
}
