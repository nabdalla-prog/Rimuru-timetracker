import QtQuick
import qs.qml

// A filled rounded button ("Save", "Renew"-style blue pill).
Rectangle {
    id: root
    property string text: ""
    property color fill: Theme.accent
    property color textColor: Theme.text
    property bool enabledButton: true
    signal clicked

    width: label.implicitWidth + 36
    height: 42
    radius: height / 2
    opacity: enabledButton ? (mouse.pressed ? 0.7 : 1) : 0.4
    color: fill

    Label {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.textColor
        font.weight: Font.DemiBold
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabledButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
