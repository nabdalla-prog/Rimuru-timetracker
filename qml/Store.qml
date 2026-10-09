import QtQuick
import Quickshell
import Quickshell.Io
import "../js/Model.js" as Model

// Owns the data: loads it, saves it, and offers the actions the screens call.
// Timers are stored as start times, so they keep counting while the app is
// closed or the computer is off.
Item {
    id: root

    readonly property string dataDir: Quickshell.env("TIMETRACKER_HOME") || (Quickshell.env("HOME") + "/.local/share/omarchy-timetracker")
    readonly property string dataPath: dataDir + "/data.json"
    readonly property string exportDir: Quickshell.env("HOME") + "/Downloads"
    readonly property string appDir: {
        var u = Qt.resolvedUrl("..").toString();
        return u.startsWith("file://") ? u.slice(7).replace(/\/$/, "") : u;
    }
    readonly property string desktopPath: Quickshell.env("HOME") + "/.local/share/applications/omarchy-timetracker.desktop"

    // ---- App launcher entry (Settings > Add to App Launcher) ---------------------
    property bool launcherInstalled: false
    function installLauncher() {
        launcherJob.running = true;
    }
    Process {
        id: launcherJob
        command: [root.appDir + "/install.sh"]
        onExited: function (code) {
            launcherCheck.reload();
            root.notify(code === 0 ? "Added to the app launcher" : "Could not add to the app launcher", code === 0 ? "Open Time Tracker with Super + Space." : "Run install.sh from " + root.appDir + " to see why.");
        }
    }
    FileView {
        id: launcherCheck
        path: root.desktopPath
        printErrors: false
        onLoaded: root.launcherInstalled = true
        onLoadFailed: root.launcherInstalled = false
    }

    // Always replaced, never changed in place, so bindings re-evaluate.
    property var db: Model.defaultData(Date.now())
    property bool ready: false
    property double now: Date.now()

    readonly property var settings: db.settings
    readonly property var activities: Model.visibleActivities(db)
    readonly property var archived: db.activities.filter(function (a) {
        return a.archived;
    })
    readonly property bool anyRunning: db.running.length > 0

    function fmt(ms) {
        return Model.fmt(ms, settings.timeFormat);
    }

    function apply(next) {
        if (next === db)
            return;
        db = next;
        now = Date.now();
        saveSoon.restart();
    }

    // ---- Actions ---------------------------------------------------------------
    function toggle(id) {
        apply(Model.toggleTimer(db, id, Date.now()));
    }
    function stopAll() {
        apply(Model.stopAll(db, Date.now()));
    }
    function addActivity(name, color) {
        apply(Model.addActivity(db, name, color, Date.now()));
    }
    function updateActivity(id, changes) {
        apply(Model.updateActivity(db, id, changes));
    }
    function deleteActivity(id) {
        apply(Model.deleteActivity(db, id));
    }
    function moveActivity(id, delta) {
        apply(Model.moveActivity(db, id, delta));
    }
    function saveEvent(ev) {
        apply(Model.saveEvent(db, ev));
    }
    function deleteEvent(id) {
        apply(Model.deleteEvent(db, id));
    }
    // A running timer shown in the log: change when it started.
    function setRunningStart(activity, start) {
        var next = Object.assign({}, db);
        next.running = db.running.map(function (r) {
            return r.activity === activity ? { "activity": activity, "start": Math.min(start, Date.now()) } : r;
        });
        apply(next);
    }
    function saveGoal(goal) {
        apply(Model.saveGoal(db, goal, Date.now()));
    }
    function deleteGoal(id) {
        apply(Model.deleteGoal(db, id));
    }
    function set(key, value) {
        apply(Model.setSetting(db, key, value));
    }
    function toggleHidden(id) {
        apply(Model.toggleHidden(db, id));
    }
    function wipe() {
        apply(Model.defaultData(Date.now()));
    }

    // Writes every event to a CSV file in ~/Downloads and says where.
    function exportCsv() {
        var file = exportDir + "/time-tracker-" + Model.dayKey(new Date()) + ".csv";
        exporter.command = ["sh", "-c", "mkdir -p \"$1\" && cat > \"$2\"", "sh", exportDir, file];
        exporter.pendingText = Model.toCsv(db, Date.now());
        exporter.file = file;
        exporter.running = true;
    }

    Process {
        id: exporter
        property string pendingText: ""
        property string file: ""
        stdinEnabled: true
        onStarted: {
            write(pendingText);
            stdinEnabled = false;
        }
        onExited: function (code) {
            stdinEnabled = true;
            // No file path in the text: notify-send arguments are visible to other local users.
            root.notify(code === 0 ? "Exported" : "Export failed", code === 0 ? "Your CSV file was saved." : "Could not write the CSV file.");
        }
    }

    function notify(title, body) {
        Quickshell.execDetached(["notify-send", "--app-name=Time Tracker", "--icon=appointment-soon", title, body]);
    }

    // One line for the command line: what's running.
    function status() {
        if (db.running.length === 0)
            return "Nothing running";
        return db.running.map(function (r) {
            var a = Model.activityById(db, r.activity);
            return (a ? a.name : r.activity) + "  " + Model.fmtElapsed(Date.now() - r.start);
        }).join("\n");
    }

    function findActivity(name) {
        var key = String(name).trim().toLowerCase();
        for (var i = 0; i < db.activities.length; i++)
            if (db.activities[i].name.toLowerCase() === key)
                return db.activities[i];
        return null;
    }

    // ---- Clock -------------------------------------------------------------------
    // Every second while a timer runs (for the live counters), else every 30s.
    Timer {
        interval: root.anyRunning ? 1000 : 30000
        repeat: true
        running: root.ready
        onTriggered: {
            root.now = Date.now();
            root.checkReminders();
        }
    }

    // ---- Notifications -------------------------------------------------------------
    // Already announced, so each fires once: "remind|<activity>|<start>" and
    // "goal|<id>|<period start>".
    property var announced: ({})

    function checkReminders() {
        var next = null;
        var hours = settings.reminderHours;
        if (hours > 0) {
            db.running.forEach(function (r) {
                var id = "remind|" + r.activity + "|" + r.start;
                if (root.now - r.start >= hours * Model.HOUR && !root.announced[id]) {
                    next = next || Object.assign({}, root.announced);
                    next[id] = true;
                    // No activity names or durations: notify-send arguments are visible to other local users.
                    root.notify("A timer is still running", "Forgot to stop it? Open Time Tracker to see which one.");
                }
            });
        }
        if (settings.goalNotifications) {
            Model.goalStatus(db, now).forEach(function (s) {
                var start = s.goal.period === "week" ? Model.startOfWeek(root.now, root.settings.weekStart) : Model.startOfDay(root.now);
                var id = "goal|" + s.goal.id + "|" + start;
                var hit = s.goal.kind === "atMost" ? s.over : s.reached;
                if (!hit || root.announced[id])
                    return;
                next = next || Object.assign({}, root.announced);
                next[id] = true;
                // Goals already met when the app starts are noted quietly.
                if (root.primed)
                    root.notify(s.goal.kind === "atMost" ? "Over one of your limits" : "Goal reached", "Open Time Tracker to see which one.");
            });
        }
        if (next)
            announced = next;
        primed = true;
    }
    property bool primed: false
    onDbChanged: if (ready) Qt.callLater(checkReminders)

    // ---- Storage --------------------------------------------------------------------
    Timer {
        id: saveSoon
        interval: 400
        onTriggered: root.save()
    }

    function save() {
        if (ready)
            dataFile.setText(Model.serialize(db));
    }

    Process {
        id: ensureDir
        command: ["mkdir", "-p", root.dataDir]
        onExited: dataFile.path = root.dataPath
    }
    Process {
        id: keepCorrupt
        onExited: root.start()
    }

    FileView {
        id: dataFile
        printErrors: false
        atomicWrites: true
        onLoaded: {
            var parsed = Model.parseData(text(), Date.now());
            root.db = parsed.data;
            if (parsed.ok) {
                root.start();
            } else {
                console.warn("timetracker: " + root.dataPath + " is unreadable, keeping a copy and starting fresh");
                keepCorrupt.command = ["cp", "-f", root.dataPath, root.dataPath + ".corrupt-" + Date.now()];
                keepCorrupt.running = true;
            }
        }
        // First run: no file yet.
        onLoadFailed: root.start()
        onSaveFailed: console.warn("timetracker: could not save " + root.dataPath)
    }

    function start() {
        ready = true;
        save();
        now = Date.now();
        checkReminders();
    }

    Component.onCompleted: ensureDir.running = true
    Component.onDestruction: if (saveSoon.running) save()
}
