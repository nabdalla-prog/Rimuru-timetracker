import QtQuick
import qs.qml
import "../js/Model.js" as Model
import "components"

// Tab 4: daily and weekly goals with progress. A goal is either "at least"
// (do more of it) or "at most" (a limit). Click one to edit it.
Item {
    id: root
    required property var store
    property int bottomInset: 90

    signal addRequested
    signal editRequested(var goal)

    readonly property var status: Model.goalStatus(store.db, store.now)
    readonly property var daily: status.filter(function (s) {
        return s.goal.period === "day";
    })
    readonly property var weekly: status.filter(function (s) {
        return s.goal.period === "week";
    })
    readonly property var weekRange: Model.periodRange("week", 0, store.now, store.settings.weekStart)

    Header {
        id: header
        rightGlyph: Theme.iPlus
        onRightClicked: root.addRequested()
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
            spacing: 14

            Label {
                text: "Goals"
                font.pixelSize: Theme.large
                font.weight: Font.Bold
            }

            Column {
                visible: root.status.length === 0
                width: parent.width
                spacing: 16
                topPadding: 40

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    glyph: Theme.iGoals
                    size: 46
                    color: Theme.text3
                }
                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "Set a goal like \"Reading 30m a day\" or a limit like \"Social media at most 1h a day\"."
                    color: Theme.text2
                }
                PillButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Add a goal"
                    onClicked: root.addRequested()
                }
            }

            Repeater {
                model: [
                    { title: "Today", sub: Model.dayTitle(root.store.now), rows: root.daily },
                    { title: "This Week", sub: root.weekRange.label, rows: root.weekly }
                ]

                Column {
                    id: section
                    required property var modelData
                    visible: modelData.rows.length > 0
                    width: col.width
                    spacing: 8

                    Item {
                        width: parent.width
                        height: 30
                        Label {
                            anchors.bottom: parent.bottom
                            text: section.modelData.title
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                        }
                        Label {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                            text: section.modelData.sub
                            color: Theme.text2
                            font.pixelSize: 13
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.separator
                    }

                    Repeater {
                        model: section.modelData.rows

                        Rectangle {
                            id: goalRow
                            required property var modelData
                            readonly property bool limit: modelData.goal.kind === "atMost"
                            readonly property color barColor: limit ? (modelData.over ? Theme.danger : modelData.color) : (modelData.reached ? Theme.good : modelData.color)
                            width: col.width
                            height: 78
                            radius: Theme.radius
                            color: goalMouse.containsMouse ? Theme.cardHi : Theme.card

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                Item {
                                    width: parent.width
                                    height: 20
                                    Rectangle {
                                        id: dot
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 14
                                        height: 14
                                        radius: 7
                                        color: goalRow.modelData.color
                                    }
                                    Label {
                                        anchors.left: dot.right
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: goalRow.modelData.name + (goalRow.limit ? "  ·  limit" : "")
                                        font.pixelSize: 16
                                    }
                                    Label {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: goalRow.limit ? (goalRow.modelData.over ? "Over by " + root.store.fmt(goalRow.modelData.doneMs - goalRow.modelData.targetMs) : root.store.fmt(goalRow.modelData.targetMs - goalRow.modelData.doneMs) + " left") : (goalRow.modelData.reached ? "Done ✓" : Math.round(goalRow.modelData.ratio * 100) + "%")
                                        color: goalRow.modelData.over ? Theme.danger : (goalRow.modelData.reached && !goalRow.limit ? Theme.good : Theme.text2)
                                        font.pixelSize: 13
                                    }
                                }
                                Rectangle {
                                    width: parent.width
                                    height: 6
                                    radius: 3
                                    color: Theme.separator
                                    Rectangle {
                                        width: Math.max(goalRow.modelData.ratio > 0 ? 6 : 0, parent.width * goalRow.modelData.ratio)
                                        height: 6
                                        radius: 3
                                        color: goalRow.barColor
                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 300
                                            }
                                        }
                                    }
                                }
                                Label {
                                    text: root.store.fmt(goalRow.modelData.doneMs) + " / " + root.store.fmt(goalRow.modelData.targetMs)
                                    color: Theme.text2
                                    font.pixelSize: 12
                                }
                            }
                            MouseArea {
                                id: goalMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.editRequested(goalRow.modelData.goal)
                            }
                        }
                    }
                }
            }
        }
    }
}
