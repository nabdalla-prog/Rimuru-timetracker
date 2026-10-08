import QtQuick
import qs.qml

// Top bar of a tab: optional left button, centred title, optional right button.
Item {
    id: root
    property string title: ""
    property string leftGlyph: ""
    property string rightGlyph: ""
    signal leftClicked
    signal rightClicked

    width: parent ? parent.width : 400
    height: 56

    RoundButton {
        visible: root.leftGlyph !== ""
        anchors.left: parent.left
        anchors.leftMargin: Theme.pad
        anchors.verticalCenter: parent.verticalCenter
        glyph: root.leftGlyph
        onClicked: root.leftClicked()
    }
    Label {
        anchors.centerIn: parent
        text: root.title
        font.pixelSize: Theme.title
        font.weight: Font.DemiBold
    }
    RoundButton {
        visible: root.rightGlyph !== ""
        anchors.right: parent.right
        anchors.rightMargin: Theme.pad
        anchors.verticalCenter: parent.verticalCenter
        glyph: root.rightGlyph
        onClicked: root.rightClicked()
    }
}
