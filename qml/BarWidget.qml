import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "../js/Model.js" as Model

// Bar button for the Time Tracker app. It reads the app's data file (it never
// writes it) and shows what is running: " Reading 12:03". Left click opens
// the app, right click stops every timer.
BarWidget {
    id: root
    moduleName: "rimuru.timetracker"

    readonly property string pluginDir: {
        var u = Qt.resolvedUrl("..").toString();
        return u.startsWith("file://") ? u.slice(7).replace(/\/$/, "") : u;
    }
    readonly property string launcher: pluginDir + "/bin/omarchy-timetracker"
    readonly property string dataPath: Quickshell.env("HOME") + "/.local/share/omarchy-timetracker/data.json"

    property var db: Model.defaultData(Date.now())
    property double now: Date.now()

    readonly property var running: db.running.map(function (r) {
        var a = Model.activityById(db, r.activity);
        return {
            "name": a ? a.name : "?",
            "ms": Math.max(0, now - r.start)
        };
    })
    readonly property bool showName: {
        var v = root.setting("showName", true);
        return v === true || v === "true";
    }

    readonly property string glyph: ""
    readonly property string label: {
        if (running.length === 0)
            return "";
        var first = running[0];
        var text = (showName ? first.name + " " : "") + Model.fmtElapsed(first.ms);
        return running.length > 1 ? text + " +" + (running.length - 1) : text;
    }
    readonly property string tooltip: running.length === 0 ? "Time Tracker · nothing running" : running.map(function (r) {
        return r.name + "  " + Model.fmtElapsed(r.ms);
    }).join("\n") + "\nRight click to stop"

    FileView {
        id: dataFile
        path: root.dataPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            var parsed = Model.parseData(text(), Date.now());
            if (parsed.ok)
                root.db = parsed.data;
        }
    }

    // Live counter while something runs; otherwise just re-read now and then
    // in case the file watch missed an atomic replace.
    Timer {
        interval: root.running.length > 0 ? 1000 : 5000
        repeat: true
        running: true
        onTriggered: {
            root.now = Date.now();
            if (root.running.length === 0)
                dataFile.reload();
        }
    }

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: root.vertical || root.label === "" ? root.glyph : root.glyph + " " + root.label
        horizontalMargin: 8.5
        tooltipText: root.tooltip
        onPressed: function (b) {
            if (b === Qt.RightButton)
                Quickshell.execDetached([root.launcher, "stop"]);
            else
                Quickshell.execDetached([root.launcher]);
            refresh.restart();
        }
    }

    // The app saves a moment after a change; pick it up quickly.
    Timer {
        id: refresh
        interval: 900
        onTriggered: dataFile.reload()
    }

    IpcHandler {
        target: "rimuru.timetracker"
        function open(): void {
            Quickshell.execDetached([root.launcher]);
        }
        function status(): string {
            return root.tooltip;
        }
    }
}
