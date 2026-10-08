import QtQuick
import qs.qml
import "../js/Model.js" as Model
import "components"

// Tab 1: the activities as tiles (or a list). Click one to start it, click a
// running one to stop it. Right click (or hold) edits it.
Item {
    id: root
    required property var store
    property int bottomInset: 90
    // Keyboard cursor over the tiles (-1 = none).
    property int cursor: -1

    signal addRequested
    signal editRequested(string id)
    signal reportRequested

    readonly property bool grid: store.settings.displayStyle !== "list"
    readonly property var acts: store.activities
    readonly property var summary: Model.todaySummary(store.db, store.now)

    function runningElapsed(id) {
        var r = Model.isRunning(store.db, id);
        return r ? Model.fmtElapsed(store.now - r.start) : "";
    }

    function moveCursor(dx, dy) {
        if (acts.length === 0)
            return;
        var cols = grid ? 2 : 1;
        if (cursor < 0) {
            cursor = 0;
            return;
        }
        cursor = Math.max(0, Math.min(acts.length - 1, cursor + dx + dy * cols));
    }
    function activateCursor() {
        if (cursor >= 0 && cursor < acts.length)
            store.toggle(acts[cursor].id);
    }

    Header {
        id: header
        title: "Tracking"
        leftGlyph: root.grid ? Theme.iGrid : Theme.iList
        rightGlyph: Theme.iPlus
        onLeftClicked: styleMenu.visible = !styleMenu.visible
        onRightClicked: root.addRequested()
    }

    Flickable {
        id: scroll
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 6
        contentHeight: content.implicitHeight + root.bottomInset
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            x: root.grid ? Theme.pad : 0
            width: parent.width - (root.grid ? Theme.pad * 2 : 0)
            spacing: 18

            // Grid style.
            Grid {
                visible: root.grid
                width: parent.width
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: root.grid ? root.acts : []

                    ActivityTile {
                        required property var modelData
                        required property int index
                        width: (content.width - 10) / 2
                        name: modelData.name
                        tint: modelData.color
                        running: Model.isRunning(root.store.db, modelData.id) !== null
                        elapsed: running ? root.runningElapsed(modelData.id) : ""
                        keyFocus: root.cursor === index
                        onClicked: root.store.toggle(modelData.id)
                        onEditRequested: root.editRequested(modelData.id)
                    }
                }
            }

            // List style.
            Column {
                visible: !root.grid
                width: parent.width

                Repeater {
                    model: root.grid ? [] : root.acts

                    Column {
                        required property var modelData
                        required property int index
                        width: content.width

                        ActivityTile {
                            width: parent.width
                            listStyle: true
                            name: modelData.name
                            tint: modelData.color
                            running: Model.isRunning(root.store.db, modelData.id) !== null
                            elapsed: running ? root.runningElapsed(modelData.id) : ""
                            keyFocus: root.cursor === index
                            onClicked: root.store.toggle(modelData.id)
                            onEditRequested: root.editRequested(modelData.id)
                        }
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.separator
                        }
                    }
                }
            }

            Label {
                visible: root.acts.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "No activities yet. Press + to add one."
                color: Theme.text2
            }

            // "Basic Reporting" card: today at a glance, opens the timeline.
            Rectangle {
                x: root.grid ? 0 : Theme.pad
                width: content.width - (root.grid ? 0 : Theme.pad * 2)
                height: reportCol.implicitHeight + 24
                radius: Theme.radius
                color: reportMouse.containsMouse ? Theme.cardHi : Theme.card

                Column {
                    id: reportCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 10

                    Item {
                        width: parent.width
                        height: 22
                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Basic Reporting"
                            color: Theme.text2
                            font.pixelSize: Theme.title
                        }
                        Icon {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            glyph: Theme.iRight
                            size: 13
                            color: Theme.text2
                        }
                    }
                    // Today's split as one stacked bar.
                    Rectangle {
                        visible: root.summary.total > 0
                        width: parent.width
                        height: 8
                        radius: 4
                        color: Theme.cardHi
                        clip: true
                        Row {
                            anchors.fill: parent
                            Repeater {
                                model: root.summary.rows
                                Rectangle {
                                    required property var modelData
                                    width: modelData.share * reportCol.width
                                    height: 8
                                    color: modelData.color
                                }
                            }
                        }
                    }
                    Label {
                        width: parent.width
                        leftPadding: 2
                        text: root.summary.total > 0 ? "Today " + root.store.fmt(root.summary.total) + " · most on " + root.summary.top.name : "Nothing tracked today yet"
                        color: Theme.text3
                        font.pixelSize: 13
                    }
                }
                MouseArea {
                    id: reportMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.reportRequested()
                }
            }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Click to start or stop · right click to edit"
                color: Theme.text3
                font.pixelSize: 11
            }
        }
    }

    // "Display Style" menu from the reference.
    MouseArea {
        anchors.fill: parent
        visible: styleMenu.visible
        onClicked: styleMenu.visible = false
    }
    Rectangle {
        id: styleMenu
        visible: false
        x: Theme.pad
        y: header.height - 4
        width: 230
        height: menuCol.implicitHeight + 8
        radius: 14
        color: "#252527"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.06)
        z: 10

        Column {
            id: menuCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 4

            Label {
                leftPadding: 14
                height: 26
                text: "Display Style"
                color: Theme.text2
                font.pixelSize: 12
            }
            Repeater {
                model: [
                    { label: "List", glyph: Theme.iList, value: "list" },
                    { label: "Grid", glyph: Theme.iGrid, value: "grid" }
                ]
                Item {
                    required property var modelData
                    width: menuCol.width
                    height: 38
                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        radius: 8
                        color: optMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    }
                    Icon {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: Theme.iCheck
                        size: 12
                        visible: root.store.settings.displayStyle === modelData.value
                    }
                    Icon {
                        x: 34
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: modelData.glyph
                        size: 14
                    }
                    Label {
                        x: 62
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                    }
                    MouseArea {
                        id: optMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.store.set("displayStyle", modelData.value);
                            styleMenu.visible = false;
                        }
                    }
                }
            }
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.separator
            }
            Item {
                width: menuCol.width
                height: 38
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 8
                    color: stopMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                }
                Icon {
                    x: 34
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: Theme.iStop
                    size: 12
                    color: root.store.anyRunning ? Theme.danger : Theme.text3
                }
                Label {
                    x: 62
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Stop all timers"
                    color: root.store.anyRunning ? Theme.danger : Theme.text3
                }
                MouseArea {
                    id: stopMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.store.anyRunning
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.store.stopAll();
                        styleMenu.visible = false;
                    }
                }
            }
        }
    }
}
