import QtQuick
import qs.qml
import "../../js/Model.js" as Model

// Colour picker: the palette as a grid of dots.
Flow {
    id: root
    property string value: ""
    signal chosen(string color)

    width: parent ? parent.width : 300
    spacing: 10

    Repeater {
        model: Model.PALETTE

        Rectangle {
            id: sw
            required property string modelData
            width: 32
            height: 32
            radius: 16
            color: modelData
            border.width: root.value.toLowerCase() === modelData.toLowerCase() ? 3 : 0
            border.color: "white"
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.chosen(sw.modelData)
            }
        }
    }
}
