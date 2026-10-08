import QtQuick
import qs.qml

// One row of a Group: icon, label, a value on the right and a chevron, or a
// switch. `last` hides the separator under the final row.
Item {
    id: root
    property string glyph: ""
    property color glyphColor: Theme.accent
    property string label: ""
    property color labelColor: Theme.text
    property string value: ""
    property color valueColor: value === "✓" ? Theme.accent : Theme.text2
    property bool chevron: true
    property bool toggle: false
    property bool checked: false
    property bool last: false
    property color dot: "transparent"

    signal clicked
    signal toggled(bool value)

    width: parent ? parent.width : 400
    height: 46

    Rectangle {
        anchors.fill: parent
        color: mouse.pressed ? Theme.separator : (mouse.containsMouse && !root.toggle ? Theme.cardHi : "transparent")
    }
    Icon {
        id: icon
        visible: root.glyph !== ""
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        glyph: root.glyph
        size: 17
        color: root.glyphColor
    }
    Rectangle {
        id: dotItem
        visible: root.dot.a > 0
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        color: root.dot
    }
    Label {
        anchors.left: parent.left
        anchors.leftMargin: root.glyph !== "" || root.dot.a > 0 ? 48 : 16
        anchors.right: right.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.labelColor
    }
    Row {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Label {
            visible: root.value !== "" && !root.toggle
            anchors.verticalCenter: parent.verticalCenter
            text: root.value
            color: root.valueColor
            font.weight: root.value === "✓" ? Font.Bold : Font.Normal
        }
        Icon {
            visible: root.chevron && !root.toggle
            anchors.verticalCenter: parent.verticalCenter
            glyph: Theme.iRight
            size: 11
            color: Theme.text3
        }
        Toggle {
            visible: root.toggle
            anchors.verticalCenter: parent.verticalCenter
            checked: root.checked
            onToggled: function (v) {
                root.toggled(v);
            }
        }
    }
    Rectangle {
        visible: !root.last
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        x: 48
        width: parent.width - 48
        height: 1
        color: Theme.separator
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: !root.toggle
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
