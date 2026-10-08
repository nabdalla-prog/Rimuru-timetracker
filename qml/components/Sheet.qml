import QtQuick
import qs.qml

// A modal card over a dimmed background, sliding up from the bottom.
// Clicking the dimmed area or pressing Esc (handled by the owner) closes it.
Item {
    id: root
    property bool open: false
    property string title: ""
    property string actionText: ""
    property bool actionEnabled: true
    default property alias content: body.data
    signal closeRequested
    signal actionClicked

    anchors.fill: parent
    visible: open || card.y < root.height
    z: 100

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.open ? 0.6 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }
    Rectangle {
        id: card
        width: parent.width
        height: Math.min(parent.height - 40, inner.implicitHeight + 40)
        y: root.open ? parent.height - height : parent.height
        radius: 16
        color: "#161618"
        Behavior on y {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutCubic
            }
        }
        // Swallow clicks so they don't reach the dimmer.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: inner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 14

            Item {
                width: parent.width
                height: 34

                Label {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Cancel"
                    color: Theme.accent
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
                Label {
                    anchors.centerIn: parent
                    text: root.title
                    font.pixelSize: Theme.title
                    font.weight: Font.DemiBold
                }
                Label {
                    visible: root.actionText !== ""
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.actionText
                    color: root.actionEnabled ? Theme.accent : Theme.text3
                    font.weight: Font.DemiBold
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        enabled: root.actionEnabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.actionClicked()
                    }
                }
            }
            Flickable {
                width: parent.width
                height: Math.min(body.implicitHeight, root.height - 140)
                contentHeight: body.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                Column {
                    id: body
                    width: parent.width
                    spacing: 14
                }
            }
        }
    }
}
