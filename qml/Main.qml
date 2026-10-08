import QtQuick
import qs.qml
import "../js/Model.js" as Model
import "components"

// The whole app inside the window: five tabs, the floating tab bar, and the
// sheets that slide up to add or edit things.
//
// Keys: 1-5 switch tabs. Tracking: arrows move, Enter/Space start or stop,
// S stops everything. Timeline: ←/→ page through periods, D/W/M/Y pick the
// period. N adds (activity, event or goal, by tab). Esc closes a sheet.
Rectangle {
    id: root
    required property var store
    property int tab: 0

    color: Theme.bg
    focus: true

    readonly property bool sheetOpen: activitySheet.open || eventSheet.open || goalSheet.open || choiceSheet.open || visSheet.open || aboutSheet.open
    readonly property bool typing: nameBox.editing

    function closeSheets() {
        activitySheet.open = false;
        eventSheet.open = false;
        goalSheet.open = false;
        choiceSheet.open = false;
        visSheet.open = false;
        aboutSheet.open = false;
        root.forceActiveFocus();
    }

    // Opens a sheet by name (for the command line): activity, event, goal, visible, about.
    function openSheet(name) {
        closeSheets();
        if (name === "activity") { tab = 0; activitySheet.edit(""); }
        else if (name === "event") { tab = 1; eventSheet.edit(null); }
        else if (name === "goal") { tab = 3; goalSheet.edit(null); }
        else if (name === "visible") { tab = 2; visSheet.open = true; }
        else if (name === "about") { tab = 4; aboutSheet.open = true; }
    }

    function addForTab() {
        if (tab === 0 || tab === 4)
            activitySheet.edit("");
        else if (tab === 1)
            eventSheet.edit(null);
        else if (tab === 3)
            goalSheet.edit(null);
    }

    Keys.onPressed: function (e) {
        if (typing)
            return;
        if (e.key === Qt.Key_Escape) {
            if (sheetOpen)
                closeSheets();
            e.accepted = true;
            return;
        }
        if (sheetOpen)
            return;
        var t = e.text;
        if (t >= "1" && t <= "5") {
            tab = Number(t) - 1;
        } else if (t === "n" || t === "N") {
            addForTab();
        } else if (tab === 0) {
            if (e.key === Qt.Key_Left || t === "h")
                tracking.moveCursor(-1, 0);
            else if (e.key === Qt.Key_Right || t === "l")
                tracking.moveCursor(1, 0);
            else if (e.key === Qt.Key_Up || t === "k")
                tracking.moveCursor(0, -1);
            else if (e.key === Qt.Key_Down || t === "j")
                tracking.moveCursor(0, 1);
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space)
                tracking.activateCursor();
            else if (t === "s" || t === "S")
                store.stopAll();
            else
                return;
        } else if (tab === 2) {
            if (e.key === Qt.Key_Left || t === "h")
                timeline.page(1);
            else if (e.key === Qt.Key_Right || t === "l")
                timeline.page(-1);
            else if (t === "d" || t === "w" || t === "m" || t === "y")
                timeline.setKind({ "d": "day", "w": "week", "m": "month", "y": "year" }[t]);
            else
                return;
        } else {
            return;
        }
        e.accepted = true;
    }

    // ---- Tabs ------------------------------------------------------------------
    Item {
        id: pages
        anchors.fill: parent

        TrackingView {
            id: tracking
            anchors.fill: parent
            visible: root.tab === 0
            store: root.store
            onAddRequested: activitySheet.edit("")
            onEditRequested: function (id) {
                activitySheet.edit(id);
            }
            onReportRequested: root.tab = 2
        }
        EventsView {
            anchors.fill: parent
            visible: root.tab === 1
            store: root.store
            onAddRequested: eventSheet.edit(null)
            onEditRequested: function (ev) {
                eventSheet.edit(ev);
            }
        }
        TimelineView {
            id: timeline
            anchors.fill: parent
            visible: root.tab === 2
            store: root.store
            onVisibilityRequested: visSheet.open = true
        }
        GoalsView {
            anchors.fill: parent
            visible: root.tab === 3
            store: root.store
            onAddRequested: goalSheet.edit(null)
            onEditRequested: function (g) {
                goalSheet.edit(g);
            }
        }
        SettingsView {
            anchors.fill: parent
            visible: root.tab === 4
            store: root.store
            onChoiceRequested: function (title, key, options) {
                choiceSheet.title = title;
                choiceSheet.key = key;
                choiceSheet.options = options;
                choiceSheet.open = true;
            }
            onEditActivityRequested: function (id) {
                activitySheet.edit(id);
            }
            onAddActivityRequested: activitySheet.edit("")
            onAboutRequested: aboutSheet.open = true
        }
    }

    // Fade the content under the floating tab bar.
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 100
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: 0.7
                color: Theme.bg
            }
        }
    }

    TabBar {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 28
        current: root.tab
        onSelected: function (i) {
            root.tab = i;
            root.forceActiveFocus();
        }
    }

    // ---- Sheet: add / edit an activity -------------------------------------------
    Sheet {
        id: activitySheet
        property string editId: ""
        property string color: Model.PALETTE[0]
        readonly property var act: editId ? Model.activityById(root.store.db, editId) : null

        function edit(id) {
            editId = id;
            var a = id ? Model.activityById(root.store.db, id) : null;
            nameBox.text = a ? a.name : "";
            color = a ? a.color : Model.PALETTE[root.store.db.activities.length % Model.PALETTE.length];
            deleteRow.stage = 0;
            open = true;
            nameBox.focusInput();
        }
        function commit() {
            if (nameBox.text.trim() === "")
                return;
            if (editId)
                root.store.updateActivity(editId, { "name": nameBox.text, "color": color });
            else
                root.store.addActivity(nameBox.text, color);
            root.closeSheets();
        }

        title: editId ? "Edit Activity" : "New Activity"
        actionText: editId ? "Save" : "Add"
        actionEnabled: nameBox.text.trim() !== ""
        onCloseRequested: root.closeSheets()
        onActionClicked: commit()

        // Preview of the tile.
        ActivityTile {
            width: parent.width
            name: nameBox.text || "Activity name"
            tint: activitySheet.color
        }
        TextBox {
            id: nameBox
            placeholder: "Name"
            onSubmitted: activitySheet.commit()
        }
        Label {
            text: "Colour"
            color: Theme.text2
            font.pixelSize: 13
        }
        Swatches {
            value: activitySheet.color
            onChosen: function (c) {
                activitySheet.color = c;
            }
        }
        Group {
            visible: activitySheet.editId !== ""
            ListRow {
                glyph: Theme.iUp
                label: "Move Up"
                chevron: false
                onClicked: root.store.moveActivity(activitySheet.editId, -1)
            }
            ListRow {
                glyph: Theme.iDown
                label: "Move Down"
                chevron: false
                onClicked: root.store.moveActivity(activitySheet.editId, 1)
            }
            ListRow {
                glyph: Theme.iArchive
                label: activitySheet.act && activitySheet.act.archived ? "Unarchive" : "Archive"
                chevron: false
                onClicked: {
                    root.store.updateActivity(activitySheet.editId, { "archived": !(activitySheet.act && activitySheet.act.archived) });
                    root.closeSheets();
                }
            }
            ListRow {
                id: deleteRow
                property int stage: 0
                glyph: Theme.iTrash
                glyphColor: Theme.danger
                label: stage === 0 ? "Delete Activity" : "Delete it and all its events?"
                labelColor: Theme.danger
                chevron: false
                last: true
                onClicked: {
                    if (stage === 0) {
                        stage = 1;
                    } else {
                        root.store.deleteActivity(activitySheet.editId);
                        root.closeSheets();
                    }
                }
            }
        }
        Label {
            visible: activitySheet.editId !== ""
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Archiving hides it from Tracking but keeps its history."
            color: Theme.text3
            font.pixelSize: 12
        }
    }

    // ---- Sheet: add / edit an event ------------------------------------------------
    Sheet {
        id: eventSheet
        property string editId: ""
        property string activity: ""
        property double start: 0
        property double end: 0
        property bool running: false
        property int delStage: 0

        function edit(ev) {
            var now = Date.now();
            if (ev) {
                editId = ev.running ? "" : ev.id;
                activity = ev.activity;
                start = ev.start;
                end = ev.running ? now : ev.end;
                running = ev.running === true;
            } else {
                editId = "";
                var acts = root.store.activities;
                activity = acts.length ? acts[0].id : "";
                end = Math.floor(now / 300000) * 300000;
                start = end - 3600000;
                running = false;
            }
            delStage = 0;
            open = true;
        }
        function shift(which, ms) {
            if (which === "start")
                start = Math.min(start + ms, (running ? Date.now() : end) - 60000);
            else
                end = Math.max(start + 60000, end + ms);
        }
        function commit() {
            if (running)
                root.store.setRunningStart(activity, start);
            else
                root.store.saveEvent({ "id": editId, "activity": activity, "start": start, "end": end });
            root.closeSheets();
        }

        title: running ? "Running Timer" : (editId ? "Edit Event" : "New Event")
        actionText: "Save"
        actionEnabled: activity !== "" && (running || end > start)
        onCloseRequested: root.closeSheets()
        onActionClicked: commit()

        Label {
            text: "Activity"
            color: Theme.text2
            font.pixelSize: 13
        }
        Flow {
            width: parent.width
            spacing: 8
            enabled: !eventSheet.running
            Repeater {
                model: root.store.activities
                Rectangle {
                    id: pick
                    required property var modelData
                    readonly property bool on: eventSheet.activity === modelData.id
                    width: pickLabel.implicitWidth + 26
                    height: 32
                    radius: 16
                    color: on ? modelData.color : Theme.cardHi
                    opacity: eventSheet.running && !on ? 0.4 : 1
                    Label {
                        id: pickLabel
                        anchors.centerIn: parent
                        text: pick.modelData.name
                        font.pixelSize: 13
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: eventSheet.activity = pick.modelData.id
                    }
                }
            }
        }

        Repeater {
            model: eventSheet.running ? ["start"] : ["start", "end"]

            Column {
                id: when
                required property string modelData
                readonly property double value: modelData === "start" ? eventSheet.start : eventSheet.end
                width: parent.width
                spacing: 8

                Label {
                    text: (when.modelData === "start" ? "Start · " : "End · ") + Model.dayTitle(when.value) + " · " + Model.clock(when.value)
                    color: Theme.text2
                    font.pixelSize: 13
                }
                Row {
                    spacing: 12
                    Stepper {
                        text: "day"
                        onDecrement: eventSheet.shift(when.modelData, -86400000)
                        onIncrement: eventSheet.shift(when.modelData, 86400000)
                    }
                    Stepper {
                        text: Model.clock(when.value)
                        onDecrement: eventSheet.shift(when.modelData, -300000)
                        onIncrement: eventSheet.shift(when.modelData, 300000)
                    }
                }
            }
        }

        Label {
            text: "Duration  " + Model.fmtEvent((eventSheet.running ? Date.now() : eventSheet.end) - eventSheet.start, root.store.settings.timeFormat)
            font.pixelSize: Theme.title
            color: Theme.accent
        }

        Group {
            visible: eventSheet.running || eventSheet.editId !== ""
            ListRow {
                visible: eventSheet.running
                glyph: Theme.iStop
                label: "Stop Timer Now"
                chevron: false
                last: true
                onClicked: {
                    root.store.toggle(eventSheet.activity);
                    root.closeSheets();
                }
            }
            ListRow {
                visible: eventSheet.editId !== ""
                glyph: Theme.iTrash
                glyphColor: Theme.danger
                label: eventSheet.delStage === 0 ? "Delete Event" : "Click again to delete"
                labelColor: Theme.danger
                chevron: false
                last: true
                onClicked: {
                    if (eventSheet.delStage === 0) {
                        eventSheet.delStage = 1;
                    } else {
                        root.store.deleteEvent(eventSheet.editId);
                        root.closeSheets();
                    }
                }
            }
        }
    }

    // ---- Sheet: add / edit a goal ----------------------------------------------------
    Sheet {
        id: goalSheet
        property string editId: ""
        property string activity: ""
        property string period: "day"
        property string kind: "atLeast"
        property int minutes: 60
        property int delStage: 0

        function edit(g) {
            editId = g ? g.id : "";
            var acts = root.store.activities;
            activity = g ? g.activity : (acts.length ? acts[0].id : "");
            period = g ? g.period : "day";
            kind = g ? g.kind : "atLeast";
            minutes = g ? g.minutes : 60;
            delStage = 0;
            open = true;
        }

        title: editId ? "Edit Goal" : "New Goal"
        actionText: "Save"
        actionEnabled: activity !== ""
        onCloseRequested: root.closeSheets()
        onActionClicked: {
            root.store.saveGoal({ "id": editId, "activity": activity, "period": period, "kind": kind, "minutes": minutes });
            root.closeSheets();
        }

        Label {
            text: "Activity"
            color: Theme.text2
            font.pixelSize: 13
        }
        Flow {
            width: parent.width
            spacing: 8
            Repeater {
                model: root.store.activities
                Rectangle {
                    id: gpick
                    required property var modelData
                    readonly property bool on: goalSheet.activity === modelData.id
                    width: gpickLabel.implicitWidth + 26
                    height: 32
                    radius: 16
                    color: on ? modelData.color : Theme.cardHi
                    Label {
                        id: gpickLabel
                        anchors.centerIn: parent
                        text: gpick.modelData.name
                        font.pixelSize: 13
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: goalSheet.activity = gpick.modelData.id
                    }
                }
            }
        }
        Segmented {
            width: parent.width
            options: [
                { label: "At least", value: "atLeast" },
                { label: "At most (limit)", value: "atMost" }
            ]
            value: goalSheet.kind
            onChosen: function (v) {
                goalSheet.kind = v;
            }
        }
        Segmented {
            width: parent.width
            options: [
                { label: "Every day", value: "day" },
                { label: "Every week", value: "week" }
            ]
            value: goalSheet.period
            onChosen: function (v) {
                goalSheet.period = v;
            }
        }
        Item {
            width: parent.width
            height: 40
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: "Target"
            }
            Stepper {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Model.fmt(goalSheet.minutes * 60000, "hm")
                onDecrement: goalSheet.minutes = Math.max(5, goalSheet.minutes - (goalSheet.minutes > 120 ? 30 : goalSheet.minutes > 60 ? 15 : 5))
                onIncrement: goalSheet.minutes = Math.min(goalSheet.period === "week" ? 7 * 1440 : 1440, goalSheet.minutes + (goalSheet.minutes >= 120 ? 30 : goalSheet.minutes >= 60 ? 15 : 5))
            }
        }
        Group {
            visible: goalSheet.editId !== ""
            ListRow {
                glyph: Theme.iTrash
                glyphColor: Theme.danger
                label: goalSheet.delStage === 0 ? "Delete Goal" : "Click again to delete"
                labelColor: Theme.danger
                chevron: false
                last: true
                onClicked: {
                    if (goalSheet.delStage === 0) {
                        goalSheet.delStage = 1;
                    } else {
                        root.store.deleteGoal(goalSheet.editId);
                        root.closeSheets();
                    }
                }
            }
        }
    }

    // ---- Sheet: pick one value of a setting ---------------------------------------------
    Sheet {
        id: choiceSheet
        property string key: ""
        property var options: []
        onCloseRequested: root.closeSheets()

        Group {
            Repeater {
                model: choiceSheet.options
                ListRow {
                    required property var modelData
                    required property int index
                    label: modelData.label
                    chevron: false
                    value: root.store.settings[choiceSheet.key] === modelData.value ? "✓" : ""
                    last: index === choiceSheet.options.length - 1
                    onClicked: {
                        root.store.set(choiceSheet.key, modelData.value);
                        root.closeSheets();
                    }
                }
            }
        }
    }

    // ---- Sheet: visible timelines -----------------------------------------------------------
    Sheet {
        id: visSheet
        title: "Visible Timelines"
        actionText: root.store.settings.hidden.length > 0 ? "All" : "None"
        onCloseRequested: root.closeSheets()
        onActionClicked: root.store.set("hidden", root.store.settings.hidden.length > 0 ? [] : root.store.activities.map(function (a) {
            return a.id;
        }))

        Group {
            Repeater {
                model: root.store.activities
                ListRow {
                    required property var modelData
                    required property int index
                    dot: modelData.color
                    label: modelData.name
                    chevron: false
                    value: root.store.settings.hidden.indexOf(modelData.id) < 0 ? "✓" : ""
                    last: index === root.store.activities.length - 1
                    onClicked: root.store.toggleHidden(modelData.id)
                }
            }
        }
    }

    // ---- Sheet: about ---------------------------------------------------------------------
    Sheet {
        id: aboutSheet
        title: "About"
        onCloseRequested: root.closeSheets()

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            glyph: Theme.iClock
            size: 56
            color: Theme.accent
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Time Tracker for Omarchy  v" + Model.VERSION
            font.pixelSize: Theme.title
            font.weight: Font.DemiBold
        }
        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            color: Theme.text2
            text: "Track where your time goes with one click. Free forever, fully local, MIT licensed.\n\nKeys: 1–5 tabs · N new · arrows + Enter start/stop · S stop all · on Timeline ←/→ page and D/W/M/Y period · Esc close."
        }
    }
}
