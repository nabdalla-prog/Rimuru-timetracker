import QtQuick
import qs.qml

// The round grey header buttons (grid menu, +, info).
Rectangle {
    id: root
    property string glyph: Theme.iPlus
    property int glyphSize: 17
    signal clicked

    width: 40
    height: 40
    radius: 20
    color: mouse.pressed ? Theme.separator : (mouse.containsMouse ? Theme.cardHi : Theme.card)

    Icon {
        anchors.centerIn: parent
        glyph: root.glyph
        size: root.glyphSize
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
