import QtQuick
import qs.qml

// A tracking tile: dark card with the activity's colour as a strip on the
// left. While running it fills with a tint of the colour and shows the time.
Rectangle {
    id: root
    property string name: ""
    property color tint: Theme.accent
    property bool running: false
    property string elapsed: ""
    // "grid" tiles or full-width "list" rows.
    property bool listStyle: false
    property bool keyFocus: false

    signal clicked
    signal editRequested

    height: listStyle ? 44 : 58
    radius: listStyle ? 0 : 10
    color: running ? Qt.rgba(tint.r, tint.g, tint.b, mouse.containsMouse ? 0.42 : 0.32) : (mouse.pressed ? Theme.separator : (mouse.containsMouse ? Theme.cardHi : Theme.card))
    border.width: keyFocus ? 2 : 0
    border.color: Theme.accent
    clip: true
    Behavior on color {
        ColorAnimation {
            duration: 160
        }
    }

    Rectangle {
        id: strip
        width: root.listStyle ? 5 : 9
        height: parent.height
        color: root.tint
        radius: root.listStyle ? 0 : 10
        // Square off the strip's inner edge.
        Rectangle {
            visible: !root.listStyle
            anchors.right: parent.right
            width: 5
            height: parent.height
            color: root.tint
        }
    }
    Label {
        anchors.left: strip.right
        anchors.leftMargin: 14
        anchors.right: side.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.running && !root.listStyle ? -8 : 0
        text: root.name
        font.pixelSize: root.name.length > 16 && !root.listStyle ? 13 : Theme.tile
        color: Theme.text
    }
    Label {
        visible: root.running && !root.listStyle
        anchors.left: strip.right
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 11
        text: root.elapsed
        font.pixelSize: Theme.small
        font.features: { "tnum": 1 }
        color: Qt.rgba(1, 1, 1, 0.8)
    }
    Item {
        id: side
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: root.listStyle ? sideRow.implicitWidth : (root.running ? 16 : 0)
        height: 24

        Row {
            id: sideRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Label {
                visible: root.listStyle && root.running
                anchors.verticalCenter: parent.verticalCenter
                text: root.elapsed
                font.features: { "tnum": 1 }
                color: Theme.text
            }
            // List rows: a blue clock ring like the reference; grid: a stop square.
            Rectangle {
                visible: root.listStyle
                width: 24
                height: 24
                radius: 12
                color: root.running ? Theme.accent : "transparent"
                border.width: 1.5
                border.color: Theme.accent
                Icon {
                    anchors.centerIn: parent
                    glyph: root.running ? Theme.iStop : Theme.iClock
                    size: root.running ? 10 : 14
                    color: root.running ? Theme.text : Theme.accent
                }
            }
            Icon {
                visible: !root.listStyle && root.running
                glyph: Theme.iStop
                size: 12
                color: Theme.text
            }
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function (m) {
            if (m.button === Qt.RightButton)
                root.editRequested();
            else
                root.clicked();
        }
        onPressAndHold: root.editRequested()
    }
}
