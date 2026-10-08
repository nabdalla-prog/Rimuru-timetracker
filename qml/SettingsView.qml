import QtQuick
import qs.qml
import "../js/Model.js" as Model
import "components"

// Tab 5: grouped settings in the reference's style. Everything is free.
Item {
    id: root
    required property var store
    property int bottomInset: 90

    // Ask the owner to show a picker: options are [{ label, value }].
    signal choiceRequested(string title, string key, var options)
    signal editActivityRequested(string id)
    signal addActivityRequested
    signal aboutRequested

    readonly property var s: store.settings

    readonly property var formatOptions: [
        { label: "4h 12m", value: "hm" },
        { label: "4:12", value: "clock" },
        { label: "4.2h", value: "decimal" }
    ]
    readonly property var roundingOptions: [
        { label: "none", value: 0 },
        { label: "1 min", value: 1 },
        { label: "5 min", value: 5 },
        { label: "15 min", value: 15 },
        { label: "30 min", value: 30 }
    ]
    readonly property var reminderOptions: [
        { label: "disabled", value: 0 },
        { label: "after 1 hour", value: 1 },
        { label: "after 2 hours", value: 2 },
        { label: "after 4 hours", value: 4 },
        { label: "after 8 hours", value: 8 }
    ]
    readonly property var weekOptions: [
        { label: "Monday", value: 1 },
        { label: "Sunday", value: 0 }
    ]
    readonly property var pieOptions: [
        { label: "Percent", value: "percent" },
        { label: "Time", value: "time" }
    ]

    function labelFor(options, value) {
        for (var i = 0; i < options.length; i++)
            if (options[i].value === value)
                return options[i].label;
        return "";
    }

    Header {
        id: header
        rightGlyph: Theme.iInfo
        onRightClicked: root.aboutRequested()
    }

    Flickable {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentHeight: col.implicitHeight + root.bottomInset
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            x: Theme.pad
            width: parent.width - Theme.pad * 2
            spacing: 22

            Label {
                text: "Settings"
                font.pixelSize: Theme.large
                font.weight: Font.Bold
            }

            Group {
                title: "Time Tracking"
                ListRow {
                    glyph: Theme.iBell
                    label: "Reminders"
                    value: root.s.reminderHours > 0 ? "enabled" : "disabled"
                    onClicked: root.choiceRequested("Remind me when a timer runs", "reminderHours", root.reminderOptions)
                }
                ListRow {
                    glyph: Theme.iClone
                    label: "Allow Simultaneous Timers"
                    toggle: true
                    checked: root.s.simultaneous
                    onToggled: function (v) {
                        root.store.set("simultaneous", v);
                    }
                }
                ListRow {
                    glyph: Theme.iFlag
                    label: "Goals Notifications"
                    toggle: true
                    checked: root.s.goalNotifications
                    last: true
                    onToggled: function (v) {
                        root.store.set("goalNotifications", v);
                    }
                }
            }

            Group {
                title: "Activities"
                footer: "Click an activity to rename it, change its colour, reorder or archive it."
                Repeater {
                    model: root.store.db.activities
                    ListRow {
                        required property var modelData
                        dot: modelData.color
                        label: modelData.name
                        labelColor: modelData.archived ? Theme.text2 : Theme.text
                        value: modelData.archived ? "archived" : ""
                        onClicked: root.editActivityRequested(modelData.id)
                    }
                }
                ListRow {
                    glyph: Theme.iPlus
                    label: "New Activity"
                    labelColor: Theme.accent
                    chevron: false
                    last: true
                    onClicked: root.addActivityRequested()
                }
            }

            Group {
                title: "Statistics & Export"
                ListRow {
                    glyph: Theme.iHash
                    label: "Time Format"
                    value: root.labelFor(root.formatOptions, root.s.timeFormat)
                    onClicked: root.choiceRequested("Time Format", "timeFormat", root.formatOptions)
                }
                ListRow {
                    glyph: Theme.iRound
                    label: "Rounding"
                    value: root.labelFor(root.roundingOptions, root.s.rounding)
                    onClicked: root.choiceRequested("Round stopped timers to", "rounding", root.roundingOptions)
                }
                ListRow {
                    glyph: Theme.iPie
                    label: "Pie Chart Labels"
                    value: root.labelFor(root.pieOptions, root.s.pieLabels)
                    onClicked: root.choiceRequested("Pie Chart Labels", "pieLabels", root.pieOptions)
                }
                ListRow {
                    glyph: Theme.iExport
                    label: "Export to File"
                    value: "CSV"
                    last: true
                    onClicked: root.store.exportCsv()
                }
            }

            Group {
                title: "General"
                footer: "Your data stays on this computer, in " + root.store.dataPath.replace(/^\/home\/[^\/]+/, "~") + "."
                ListRow {
                    glyph: Theme.iCalendar
                    label: "Start of Week"
                    value: root.labelFor(root.weekOptions, root.s.weekStart)
                    onClicked: root.choiceRequested("Start of Week", "weekStart", root.weekOptions)
                }
                ListRow {
                    glyph: Theme.iGrid
                    label: "Add to App Launcher"
                    value: root.store.launcherInstalled ? "added" : ""
                    chevron: !root.store.launcherInstalled
                    onClicked: if (!root.store.launcherInstalled) root.store.installLauncher()
                }
                ListRow {
                    glyph: Theme.iArchive
                    label: "Archived Activities"
                    value: root.store.archived.length === 0 ? "none" : "" + root.store.archived.length
                    chevron: false
                }
                ListRow {
                    glyph: Theme.iEvents
                    label: "Events Recorded"
                    value: "" + root.store.db.events.length
                    chevron: false
                    last: true
                }
            }

            Group {
                title: "Data"
                footer: "Click three times to confirm. Deletes every event, goal and custom activity."
                ListRow {
                    id: wipeRow
                    property int stage: 0
                    glyph: Theme.iTrash
                    glyphColor: Theme.danger
                    label: ["Delete All Data", "Are you sure?", "Really delete everything?"][stage]
                    labelColor: Theme.danger
                    chevron: false
                    last: true
                    onClicked: {
                        if (stage >= 2) {
                            stage = 0;
                            root.store.wipe();
                        } else {
                            stage++;
                            wipeReset.restart();
                        }
                    }
                    Timer {
                        id: wipeReset
                        interval: 4000
                        onTriggered: wipeRow.stage = 0
                    }
                }
            }

            Group {
                title: "About"
                footer: "Free and open source. No account, no subscription, nothing leaves your machine."
                ListRow {
                    glyph: Theme.iHeart
                    glyphColor: "#ff375f"
                    label: "Time Tracker for Omarchy"
                    value: "v" + Model.VERSION
                    last: true
                    onClicked: root.aboutRequested()
                }
            }
        }
    }
}
