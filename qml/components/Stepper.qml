import QtQuick
import qs.qml

// "−  value  +" control.
Row {
    id: root
    property string text: ""
    signal decrement
    signal increment

    spacing: 0

    Repeater {
        model: 3

        Rectangle {
            required property int index
            width: index === 1 ? Math.max(84, valueLabel.implicitWidth + 16) : 40
            height: 34
            radius: index === 1 ? 0 : 8
            color: index === 1 ? "transparent" : (m.pressed ? Theme.separator : Theme.cardHi)
            Label {
                id: valueLabel
                anchors.centerIn: parent
                text: index === 0 ? "−" : index === 2 ? "+" : root.text
                font.pixelSize: index === 1 ? Theme.body : 20
                font.features: { "tnum": 1 }
            }
            MouseArea {
                id: m
                anchors.fill: parent
                enabled: index !== 1
                cursorShape: Qt.PointingHandCursor
                onClicked: index === 0 ? root.decrement() : root.increment()
                // Hold to repeat.
                onPressAndHold: repeat.start()
                onReleased: repeat.stop()
            }
            Timer {
                id: repeat
                interval: 90
                repeat: true
                onTriggered: index === 0 ? root.decrement() : root.increment()
            }
        }
    }
}
