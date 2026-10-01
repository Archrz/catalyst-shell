import QtQuick
import QtCore
import Quickshell

Singleton {
    id: root

    property string _serialized: ""

    Settings {
        location: "file://" + Quickshell.env("HOME") + "/.config/catalyst/settings.conf"
        category: "Launcher"
        property alias hiddenApps: root._serialized
    }

    property var hiddenApps: []

    Component.onCompleted: _load()

    function _load() {
        if (_serialized === "") { hiddenApps = []; return }
        try {
            var parsed = JSON.parse(_serialized)
            hiddenApps = Array.isArray(parsed) ? parsed : []
        } catch (e) {
            hiddenApps = []
        }
    }

    function _commit() {
        _serialized = JSON.stringify(hiddenApps)
    }

    function hide(id, name, icon) {
        if (isHidden(id)) return
        hiddenApps = hiddenApps.concat([{ id: id, name: name, icon: icon }])
        _commit()
    }

    function show(id) {
        hiddenApps = hiddenApps.filter(function(a) { return a.id !== id })
        _commit()
    }

    function isHidden(id) {
        return hiddenApps.some(function(a) { return a.id === id })
    }
}
