import QtQuick
import QtQuick.Shapes
import qs.qml

// Solid pie like the reference, with labels inside the slices. `slices`
// come from Model.pieSlices. Hovering a slice pops it out.
Item {
    id: root
    property var slices: []
    property int hovered: -1
    // Text per slice, same order as slices.
    property var labels: []
    signal hoverRequested(int index)

    readonly property real r: Math.min(width, height) / 2 - 8
    readonly property real cx: width / 2
    readonly property real cy: height / 2

    function sliceAt(x, y) {
        var dx = x - cx, dy = y - cy;
        if (Math.sqrt(dx * dx + dy * dy) > r + 8)
            return -1;
        var turn = (Math.atan2(dy, dx) * 180 / Math.PI + 90) / 360;
        if (turn < 0)
            turn += 1;
        for (var i = 0; i < slices.length; i++)
            if (turn >= slices[i].startFrac && turn < slices[i].startFrac + slices[i].sweepFrac)
                return i;
        return -1;
    }

    // Empty state: a dim disc.
    Rectangle {
        visible: root.slices.length === 0
        anchors.centerIn: parent
        width: root.r * 2
        height: width
        radius: width / 2
        color: Theme.card
        Label {
            anchors.centerIn: parent
            text: "No time tracked"
            color: Theme.text2
        }
    }

    Repeater {
        model: root.slices

        Shape {
            id: sh
            required property var modelData
            required property int index
            readonly property real mid: (modelData.startFrac + modelData.sweepFrac / 2) * 2 * Math.PI - Math.PI / 2
            readonly property real pop: root.hovered === index ? 10 : 0
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            transform: Translate {
                x: Math.cos(sh.mid) * sh.pop
                y: Math.sin(sh.mid) * sh.pop
                Behavior on x {
                    NumberAnimation {
                        duration: 140
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: 140
                    }
                }
            }

            ShapePath {
                fillColor: sh.modelData.color
                strokeColor: root.slices.length > 1 ? "black" : "transparent"
                strokeWidth: root.slices.length > 1 ? 1.5 : 0
                startX: root.cx
                startY: root.cy
                PathAngleArc {
                    centerX: root.cx
                    centerY: root.cy
                    radiusX: root.r
                    radiusY: root.r
                    startAngle: -90 + sh.modelData.startFrac * 360
                    sweepAngle: Math.min(359.99, sh.modelData.sweepFrac * 360)
                    moveToStart: false
                }
                PathLine {
                    x: root.cx
                    y: root.cy
                }
            }
        }
    }
    Repeater {
        model: root.slices

        Label {
            required property var modelData
            required property int index
            readonly property real mid: (modelData.startFrac + modelData.sweepFrac / 2) * 2 * Math.PI - Math.PI / 2
            readonly property real dist: root.slices.length === 1 ? 0 : root.r * 0.62
            visible: modelData.sweepFrac >= 0.04
            x: root.cx + Math.cos(mid) * dist - width / 2
            y: root.cy + Math.sin(mid) * dist - height / 2
            text: root.labels[index] !== undefined ? root.labels[index] : ""
            font.pixelSize: 12
            font.weight: Font.DemiBold
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.35)
        }
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: function (m) {
            root.hoverRequested(root.sliceAt(m.x, m.y));
        }
        onExited: root.hoverRequested(-1)
    }
}
