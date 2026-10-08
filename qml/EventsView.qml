import QtQuick
import qs.qml
import "../js/Model.js" as Model
import "components"

// Tab 2: every stretch of time, newest first, grouped by day. Click one to
// edit it; + adds one by hand.
Item {
    id: root
    required property var store
    property int bottomInset: 90
    // How many days are listed; "Show more" adds more.
    property int dayLimit: 30

    signal addRequested
    signal editRequested(var ev)

    readonly property var log: Model.eventLog(store.db, store.now, dayLimit + 1)
    readonly property var shown: log.slice(0, dayLimit)

    Header {
        id: header
        title: "Events Log"
        rightGlyph: Theme.iPlus
        onRightClicked: root.addRequested()
    }

    Flickable {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 6
        contentHeight: list.implicitHeight + root.bottomInset
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: parent.width

            Label {
                visible: root.shown.length === 0
                width: parent.width
                topPadding: 60
                horizontalAlignment: Text.AlignHCenter
                text: "No events yet.\nStart a timer on the Tracking tab."
                color: Theme.text2
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: root.shown

                Column {
                    id: day
                    required property var modelData
                    width: list.width

                    // Day header, like "Saturday, Sep 19 · 1 event".
                    Rectangle {
                        width: parent.width
                        height: 30
                        color: Theme.cardHi
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.pad
                            anchors.verticalCenter: parent.verticalCenter
                            text: day.modelData.title
                            font.pixelSize: 14
                        }
                        Label {
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.pad
                            anchors.verticalCenter: parent.verticalCenter
                            text: day.modelData.count + (day.modelData.count === 1 ? " event" : " events")
                            color: Theme.text2
                            font.pixelSize: 12
                        }
                    }

                    Repeater {
                        model: day.modelData.events

                        Rectangle {
                            id: row
                            required property var modelData
                            width: list.width
                            height: 58
                            color: rowMouse.containsMouse ? Theme.card : Theme.bg

                            Rectangle {
                                x: 0
                                width: 4
                                height: parent.height - 12
                                anchors.verticalCenter: parent.verticalCenter
                                color: row.modelData.color
                            }
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.pad + 4
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Label {
                                    text: row.modelData.name
                                    font.pixelSize: 16
                                }
                                Label {
                                    text: Model.clock(row.modelData.start) + "  →  " + (row.modelData.running ? "now" : Model.clock(row.modelData.end))
                                    color: Theme.text2
                                    font.pixelSize: 13
                                }
                            }
                            Label {
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.pad
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 9
                                text: row.modelData.running ? Model.fmtElapsed(row.modelData.end - row.modelData.start) : Model.fmtEvent(row.modelData.end - row.modelData.start, root.store.settings.timeFormat)
                                color: row.modelData.running ? Theme.good : Theme.accent
                                font.pixelSize: 14
                                font.features: { "tnum": 1 }
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                x: Theme.pad
                                width: parent.width - Theme.pad
                                height: 1
                                color: Theme.card
                            }
                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.editRequested(row.modelData)
                            }
                        }
                    }
                }
            }

            Item {
                visible: root.log.length > root.dayLimit
                width: parent.width
                height: 50
                Label {
                    anchors.centerIn: parent
                    text: "Show older days"
                    color: Theme.accent
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -10
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dayLimit += 30
                    }
                }
            }
        }
    }
}
