import QtQuick
import qs.qml

// iOS switch.
Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool value)

    width: 51
    height: 31
    radius: height / 2
    color: checked ? Theme.good : "#39393d"
    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }
    Rectangle {
        width: 27
        height: 27
        radius: 13.5
        y: 2
        x: root.checked ? parent.width - width - 2 : 2
        color: "white"
        Behavior on x {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
