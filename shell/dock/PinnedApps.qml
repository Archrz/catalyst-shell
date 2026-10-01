pragma Singleton
import QtQuick
import QtCore
import Quickshell

Singleton {
    id: root

    property string _serialized: ""

    Settings {
        location: "file://" + Quickshell.env("HOME") + "/.config/catalyst/settings.conf"
        category: "Dock"
        property alias pinnedApps: root._serialized
    }

    property var apps: []

    Component.onCompleted: _load()

    function _load() {
        if (_serialized === "") {
            apps = _defaults()
            _serialized = JSON.stringify(apps)
            return
        }
        try {
            var parsed = JSON.parse(_serialized)
            apps = Array.isArray(parsed) ? parsed : _defaults()
        } catch (e) {
            apps = _defaults()
        }
    }

    function _defaults() {
        return [
            { id: "ghostty",            label: "Terminal", icon: "ghostty",           execName: "",         steamId: "" },
            { id: "org.gnome.Nautilus", label: "Files",    icon: "system-file-manager", execName: "nautilus", steamId: "" }
        ]
    }

    function _commit() {
        _serialized = JSON.stringify(apps)
    }

    function pinApp(id, label, icon, execName, steamId) {
        for (var i = 0; i < apps.length; i++)
            if (apps[i].id === id) return
        apps = apps.concat([{
            id:       id,
            label:    label,
            icon:     icon,
            execName: execName || "",
            steamId:  steamId  || ""
        }])
        _commit()
    }

    function unpinApp(id) {
        apps = apps.filter(function(a) { return a.id !== id })
        _commit()
    }

    function isPinned(id) {
        for (var i = 0; i < apps.length; i++)
            if (apps[i].id === id) return true
        return false
    }
}
