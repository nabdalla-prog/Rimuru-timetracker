import QtQuick
import qs.qml

// An iOS-style grouped list: an optional caption above a rounded card whose
// rows are separated by hairlines (rows draw their own separator).
Column {
    id: root
    property string title: ""
    property string footer: ""
    default property alias rows: card.data

    width: parent ? parent.width : 400
    spacing: 6

    Label {
        visible: root.title !== ""
        leftPadding: 14
        text: root.title
        color: Theme.text2
        font.pixelSize: 13
    }
    Rectangle {
        width: parent.width
        height: card.implicitHeight
        radius: Theme.radius
        color: Theme.card
        clip: true

        Column {
            id: card
            width: parent.width
        }
    }
    Label {
        visible: root.footer !== ""
        width: parent.width
        leftPadding: 14
        rightPadding: 14
        text: root.footer
        wrapMode: Text.WordWrap
        color: Theme.text2
        font.pixelSize: Theme.small
    }
}
