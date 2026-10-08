import QtQuick
import qs.qml

// iOS segmented control. `options`: [{ label, value }].
Rectangle {
    id: root
    property var options: []
    property var value: null
    signal chosen(var value)

    height: 32
    radius: 9
    color: Theme.card

    Row {
        anchors.fill: parent
        anchors.margins: 2

        Repeater {
            model: root.options

            Rectangle {
                id: seg
                required property var modelData
                readonly property bool selected: modelData.value === root.value
                width: (root.width - 4) / root.options.length
                height: parent.height
                radius: 7
                color: selected ? "#636366" : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
                Label {
                    anchors.centerIn: parent
                    text: seg.modelData.label
                    font.pixelSize: 13
                    font.weight: seg.selected ? Font.DemiBold : Font.Normal
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.chosen(seg.modelData.value)
                }
            }
        }
    }
}
