import QtQuick
import qs.qml
import "../js/Model.js" as Model
import "components"

// Tab 3: where the time went in a day, week, month or year. The names along
// the top pick which activities are visible; the pie and the list below
// follow, and the strip shows when each stretch happened.
Item {
    id: root
    required property var store
    property int bottomInset: 90

    property string kind: "week"   // "day" | "week" | "month" | "year"
    property int offset: 0
    property string chart: "pie"   // "pie" | "bars"
    property int hovered: -1

    signal visibilityRequested

    readonly property var hidden: store.settings.hidden
    readonly property var range: Model.periodRange(kind, offset, store.now, store.settings.weekStart)
    readonly property var rows: Model.totals(store.db, store.now, range.from, range.to, hidden)
    readonly property var slices: Model.pieSlices(rows)
    readonly property double total: Model.sumMs(rows)
    readonly property var blocks: Model.strip(store.db, store.now, range.from, range.to, hidden)
    readonly property var ticks: Model.axisTicks(kind, range.from, range.to)
    readonly property real nowFrac: offset === 0 ? (store.now - range.from) / (range.to - range.from) : -1
    readonly property var sliceLabels: slices.map(function (s) {
        return store.settings.pieLabels === "time" ? store.fmt(s.ms) : Math.round(s.share * 100) + "%";
    })

    function page(delta) {
        offset = Math.max(0, offset + delta);
        hovered = -1;
    }
    function setKind(k) {
        kind = k;
        offset = 0;
        hovered = -1;
    }

    // ---- Visible activities: the reference's underlined names -------------------
    Flickable {
        id: chips
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: eye.left
        anchors.leftMargin: Theme.pad
        anchors.rightMargin: 6
        height: 32
        contentWidth: chipRow.implicitWidth
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Row {
            id: chipRow
            spacing: 12
            height: parent.height

            Repeater {
                model: root.store.activities

                Item {
                    id: chip
                    required property var modelData
                    readonly property bool on: root.hidden.indexOf(modelData.id) < 0
                    width: chipLabel.implicitWidth
                    height: 32
                    opacity: on ? 1 : 0.35

                    Label {
                        id: chipLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: chip.modelData.name
                        font.pixelSize: 14
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 3
                        width: parent.width
                        height: 2
                        color: chip.modelData.color
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.store.toggleHidden(chip.modelData.id)
                    }
                }
            }
        }
    }
    RoundButton {
        id: eye
        anchors.right: parent.right
        anchors.rightMargin: Theme.pad
        anchors.verticalCenter: chips.verticalCenter
        width: 34
        height: 34
        radius: 17
        glyph: Theme.iEye
        glyphSize: 14
        onClicked: root.visibilityRequested()
    }

    Flickable {
        anchors.top: chips.bottom
        anchors.topMargin: 8
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
            spacing: 14

            // Period: arrows around the segmented control.
            Item {
                width: parent.width
                height: 34

                Icon {
                    id: prev
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    glyph: Theme.iLeft
                    size: 15
                    color: Theme.text2
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.page(1)
                    }
                }
                Segmented {
                    anchors.left: prev.right
                    anchors.right: next.left
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    options: [
                        { label: "Day", value: "day" },
                        { label: "Week", value: "week" },
                        { label: "Month", value: "month" },
                        { label: "Year", value: "year" }
                    ]
                    value: root.kind
                    onChosen: function (v) {
                        root.setKind(v);
                    }
                }
                Icon {
                    id: next
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    glyph: Theme.iRight
                    size: 15
                    color: root.offset > 0 ? Theme.text2 : Theme.text3
                    opacity: root.offset > 0 ? 1 : 0.4
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: root.offset > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.page(-1)
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 2
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.range.label
                    font.pixelSize: Theme.title
                    font.weight: Font.DemiBold
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.hovered >= 0 && root.hovered < root.rows.length ? root.rows[root.hovered].name + " · " + root.store.fmt(root.rows[root.hovered].ms) : "Total " + root.store.fmt(root.total)
                    color: Theme.text2
                    font.pixelSize: 13
                }
            }

            // ---- Chart ----------------------------------------------------------
            PieChart {
                visible: root.chart === "pie"
                width: parent.width
                height: Math.min(300, parent.width * 0.82)
                slices: root.slices
                labels: root.sliceLabels
                hovered: root.hovered
                onHoverRequested: function (i) {
                    root.hovered = i;
                }
            }

            Column {
                visible: root.chart === "bars"
                width: parent.width
                spacing: 10

                Label {
                    visible: root.rows.length === 0
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 30
                    bottomPadding: 30
                    text: "No time tracked"
                    color: Theme.text2
                }
                Repeater {
                    model: root.rows

                    Column {
                        id: bar
                        required property var modelData
                        required property int index
                        width: col.width
                        spacing: 4
                        Item {
                            width: parent.width
                            height: 18
                            Label {
                                text: bar.modelData.name
                                font.pixelSize: 14
                            }
                            Label {
                                anchors.right: parent.right
                                text: root.store.fmt(bar.modelData.ms) + "  " + Math.round(bar.modelData.share * 100) + "%"
                                color: Theme.text2
                                font.pixelSize: 13
                            }
                        }
                        Rectangle {
                            width: parent.width
                            height: 10
                            radius: 5
                            color: Theme.card
                            Rectangle {
                                width: Math.max(10, parent.width * bar.modelData.ms / root.rows[0].ms)
                                height: 10
                                radius: 5
                                color: bar.modelData.color
                            }
                        }
                    }
                }
            }

            // ---- Legend: dot, time and how many stretches -------------------------
            Flow {
                visible: root.chart === "pie" && root.rows.length > 0
                width: parent.width
                spacing: 14

                Repeater {
                    model: root.rows

                    Item {
                        id: leg
                        required property var modelData
                        required property int index
                        width: legRow.implicitWidth
                        height: legRow.implicitHeight
                        opacity: root.hovered < 0 || root.hovered === index ? 1 : 0.4

                      Row {
                        id: legRow
                        spacing: 6

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 12
                            height: 12
                            radius: 6
                            color: leg.modelData.color
                        }
                        Label {
                            text: leg.modelData.name + "  " + root.store.fmt(leg.modelData.ms) + " (" + leg.modelData.count + ")"
                            font.pixelSize: 13
                            color: Theme.text
                        }
                      }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.hovered = leg.index
                            onExited: if (root.hovered === leg.index) root.hovered = -1
                        }
                    }
                }
            }

            // ---- When it happened ---------------------------------------------------
            TimelineStrip {
                width: parent.width
                blocks: root.blocks
                ticks: root.ticks
                nowFrac: root.nowFrac
            }

            // ---- Chart switch and export (the reference's bottom row) ---------------
            Item {
                width: parent.width
                height: 44

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Repeater {
                        model: [
                            { glyph: Theme.iPie, value: "pie" },
                            { glyph: Theme.iBars, value: "bars" }
                        ]
                        Rectangle {
                            required property var modelData
                            width: 40
                            height: 34
                            radius: 9
                            color: root.chart === modelData.value ? Theme.cardHi : "transparent"
                            Icon {
                                anchors.centerIn: parent
                                glyph: modelData.glyph
                                size: 17
                                color: root.chart === modelData.value ? Theme.text : Theme.text2
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.chart = modelData.value
                            }
                        }
                    }
                }
                Row {
                    id: exportRow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: Theme.iExport
                        size: 15
                        color: Theme.accent
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Export →"
                        color: exportMouse.containsMouse ? Theme.accent : Theme.text2
                        font.pixelSize: 17
                    }
                }
                MouseArea {
                    id: exportMouse
                    anchors.fill: exportRow
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.store.exportCsv()
                }
            }
        }
    }
}
