import QtQuick
import qs.qml

// A one-line text field.
Rectangle {
    id: root
    property alias text: input.text
    property string placeholder: ""
    readonly property bool editing: input.activeFocus
    signal submitted(string text)

    function focusInput() {
        input.forceActiveFocus();
        input.selectAll();
    }

    width: parent ? parent.width : 300
    height: 42
    radius: 10
    color: Theme.cardHi
    border.width: input.activeFocus ? 1.5 : 0
    border.color: Theme.accent

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        selectByMouse: true
        maximumLength: 40
        color: Theme.text
        selectionColor: Theme.accent
        font.family: Theme.font
        font.pixelSize: Theme.body
        onAccepted: root.submitted(text)
    }
    Label {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text === ""
        text: root.placeholder
        color: Theme.text3
    }
}
