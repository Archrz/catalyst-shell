pragma Singleton
import QtQuick
import QtCore
import Quickshell

Singleton {
    id: root

    property string _serialized: ""

    Settings {
        location: "file://" + Quickshell.env("HOME") + "/.config/catalyst/settings.conf"
        category: "Launcher"
        property alias appUsage: root._serialized
    }

    property var usageMap: ({})

    Component.onCompleted: _load()

    function _load() {
        if (_serialized === "") {
            usageMap = {}
            return
        }
        try {
            usageMap = JSON.parse(_serialized)
            if (typeof usageMap !== 'object' || usageMap === null) usageMap = {}
        } catch (e) {
            usageMap = {}
        }
    }

    function _commit() {
        _serialized = JSON.stringify(usageMap)
    }

    function recordLaunch(appId) {
        var map = usageMap
        map[appId] = (map[appId] || 0) + 1
        usageMap = map
        _commit()
        usageMapChanged()
    }

    function getUsage(appId) {
        return usageMap[appId] || 0
    }
}
