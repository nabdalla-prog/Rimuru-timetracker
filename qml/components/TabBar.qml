import QtQuick
import qs.qml

// The floating pill at the bottom with the five tabs.
Rectangle {
    id: root
    property int current: 0
    readonly property var tabs: [
        { label: "Tracking", glyph: Theme.iClock },
        { label: "Events", glyph: Theme.iEvents },
        { label: "Timeline", glyph: Theme.iTimeline },
        { label: "Goals", glyph: Theme.iGoals },
        { label: "Settings", glyph: Theme.iSettings }
    ]
    signal selected(int index)

    height: 62
    radius: height / 2
    color: Qt.rgba(0.11, 0.11, 0.12, 0.96)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.08)

    Row {
        anchors.fill: parent
        anchors.margins: 5

        Repeater {
            model: root.tabs

            Item {
                id: tab
                required property var modelData
                required property int index
                readonly property bool active: root.current === index
                width: (root.width - 10) / root.tabs.length
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, tab.active ? 0.12 : (tabMouse.containsMouse ? 0.05 : 0))
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        glyph: tab.modelData.glyph
                        size: 20
                        color: tab.active ? Theme.accent : Theme.text
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tab.modelData.label
                        font.pixelSize: 10
                        color: tab.active ? Theme.accent : Theme.text
                    }
                }
                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(tab.index)
                }
            }
        }
    }
}
