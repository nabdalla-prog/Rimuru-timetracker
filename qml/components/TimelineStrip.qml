import QtQuick
import qs.qml

// The horizontal timeline under the pie: coloured blocks for each stretch
// of time in the period, over an axis with ticks. A blue marker shows now.
Item {
    id: root
    property var blocks: []
    property var ticks: []
    property real nowFrac: -1

    height: 58

    Rectangle {
        id: track
        y: 4
        width: parent.width
        height: 24
        radius: 6
        color: Theme.card
        clip: true

        Repeater {
            model: root.blocks

            Rectangle {
                required property var modelData
                x: modelData.startFrac * track.width
                width: Math.max(2, modelData.widthFrac * track.width)
                height: track.height
                color: modelData.color
            }
        }
    }
    // Now marker: the reference's small blue triangle.
    Text {
        visible: root.nowFrac >= 0 && root.nowFrac <= 1
        x: root.nowFrac * root.width - width / 2
        y: track.y + track.height - 2
        text: "▲"
        color: Theme.accent
        font.pixelSize: 10
    }
    Rectangle {
        y: track.y + track.height + 10
        width: parent.width
        height: 1
        color: Theme.separator
    }
    Repeater {
        model: root.ticks

        Item {
            required property var modelData
            x: modelData.frac * root.width
            y: track.y + track.height + 6

            Rectangle {
                width: 1
                height: 9
                color: Theme.text3
            }
            Label {
                x: 4
                y: 9
                text: modelData.label
                font.pixelSize: 11
                color: Theme.text2
            }
        }
    }
}
